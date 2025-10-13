#!/usr/bin/env bash
# upscale.sh — Auto IG-compliant upscaler
# Outputs:  <original>.high-resolution.mp4
# Detects aspect → portrait / square / landscape automatically.

set -euo pipefail

command -v HandBrakeCLI >/dev/null 2>&1 || { echo "Need HandBrakeCLI."; exit 1; }
have_ffmpeg=false;  command -v ffmpeg >/dev/null 2>&1 && have_ffmpeg=true
have_ffprobe=false; command -v ffprobe >/dev/null 2>&1 && have_ffprobe=true
have_mediainfo=false; command -v mediainfo >/dev/null 2>&1 && have_mediainfo=true

get_dims() {
  local in="$1" w h
  if $have_ffprobe; then
    read -r w h <<<"$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height \
      -of csv=s=' ' "$in" 2>/dev/null || echo "")"
  elif $have_mediainfo; then
    w="$(mediainfo --Inform='Video;%Width%' "$in" 2>/dev/null || true)"
    h="$(mediainfo --Inform='Video;%Height%' "$in" 2>/dev/null || true)"
  else
    local scan; scan="$(HandBrakeCLI -i "$in" --title 1 --scan 2>&1 || true)"
    w="$(echo "$scan" | awk '/size:[ ]*[0-9]+x[0-9]+/ {sub(/.*size:[ ]*/,""); split($0,a,"x"); print a[1]; exit}')"
    h="$(echo "$scan" | awk '/size:[ ]*[0-9]+x[0-9]+/ {sub(/.*size:[ ]*/,""); split($0,a,"x"); print a[2]; exit}')"
  fi
  [[ -n "$w" && -n "$h" ]] && echo "$w $h"
}

choose_mode() {
  local w="$1" h="$2"
  [[ "$h" -eq 0 ]] && { echo "portrait"; return; }
  local a; a=$(awk -v w="$w" -v h="$h" 'BEGIN{printf "%.4f", w/h}')
  awk -v a="$a" 'BEGIN{if(a<=0.9)print"portrait";else if(a<1.2)print"square";else print"landscape"}'
}

set_canvas() {
  case "$1" in
    portrait)  MW=1080; MH=1350 ;;
    square)    MW=1080; MH=1080 ;;
    landscape) MW=1080; MH=566  ;;
  esac
}

HB_BASE_ARGS=(
  --encoder x264 --quality 18 --x264-preset slow
  --optimize --format av_mp4
  --auto-anamorphic --keep-display-aspect --modulus 2 --crop 0:0:0:0
  --aencoder av_aac --ab 160 --mixdown stereo --arate 48
)

for IN in "$@"; do
  [[ ! -f "$IN" ]] && { echo "Skip missing $IN"; continue; }

  dims="$(get_dims "$IN" || true)"
  if [[ -n "$dims" ]]; then
    read -r W H <<<"$dims"
    MODE="$(choose_mode "$W" "$H")"
  else
    MODE="portrait"
  fi
  set_canvas "$MODE"

  STEM="${IN%.*}"
  TMP_OUT="${STEM}.tmp.mp4"
  OUT="${STEM}.high-resolution.mp4"

  echo ">>> [$MODE] scaling <= ${MW}x${MH} for '$IN'"
  if ! HandBrakeCLI -i "$IN" -o "$TMP_OUT" "${HB_BASE_ARGS[@]}" --maxWidth "$MW" --maxHeight "$MH"; then
    echo "HandBrake failed for $IN"; rm -f "$TMP_OUT"; continue
  fi

  if $have_ffmpeg; then
    echo ">>> padding to exact ${MW}x${MH}"
    ffmpeg -y -i "$TMP_OUT" \
      -vf "scale=${MW}:${MH}:force_original_aspect_ratio=decrease,pad=${MW}:${MH}:(ow-iw)/2:(oh-ih)/2" \
      -c:v libx264 -crf 18 -preset slow -c:a copy "$OUT" >/dev/null 2>&1
    rm -f "$TMP_OUT"
  else
    mv -f "$TMP_OUT" "$OUT"
  fi

  echo "✓ Wrote: $OUT"
done

echo "Done."
