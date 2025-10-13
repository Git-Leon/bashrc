#!/usr/bin/env bash
# upscale.sh — Auto-select IG canvas by source aspect; preserve quality; optional pad to exact size

set -euo pipefail

if ! command -v HandBrakeCLI >/dev/null 2>&1; then
  echo "Error: HandBrakeCLI not found." >&2
  exit 1
fi

have_ffmpeg=false; command -v ffmpeg >/dev/null 2>&1 && have_ffmpeg=true
have_ffprobe=false; command -v ffprobe >/dev/null 2>&1 && have_ffprobe=true
have_mediainfo=false; command -v mediainfo >/dev/null 2>&1 && have_mediainfo=true

get_dims() {
  local in="$1" w h
  if $have_ffprobe; then
    read -r w h <<<"$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=' ' "$in" 2>/dev/null || echo "")"
  elif $have_mediainfo; then
    w="$(mediainfo --Inform='Video;%Width%' "$in" 2>/dev/null || true)"
    h="$(mediainfo --Inform='Video;%Height%' "$in" 2>/dev/null || true)"
  else
    local scan; scan="$(HandBrakeCLI -i "$in" --title 1 --scan 2>&1 || true)"
    w="$(echo "$scan" | awk '/size:[ ]*[0-9]+x[0-9]+/ {sub(/.*size:[ ]*/,""); split($0,a,"x"); print a[1]; exit}')"
    h="$(echo "$scan" | awk '/size:[ ]*[0-9]+x[0-9]+/ {sub(/.*size:[ ]*/,""); split($0,a,"x"); print a[2]; exit}')"
  fi
  [[ -n "${w:-}" && -n "${h:-}" ]] && echo "$w $h" || echo ""
}

choose_mode_by_aspect() {
  local w="$1" h="$2"
  [[ "$h" -eq 0 ]] && { echo "portrait"; return; }
  local a; a=$(awk -v w="$w" -v h="$h" 'BEGIN{printf "%.4f", w/h}')
  awk -v a="$a" 'BEGIN{ if (a<=0.9) print "portrait"; else if (a<1.2) print "square"; else print "landscape"; }'
}

apply_canvas() {
  case "$1" in
    portrait)  MW=1080; MH=1350; TAG="ig-POR" ;;
    square)    MW=1080; MH=1080; TAG="ig-SQ"  ;;
    landscape) MW=1080; MH=566;  TAG="ig-LS"  ;;
    *)         MW=1080; MH=1350; TAG="ig-POR" ;;
  esac
}

MODE="${1:-auto}"
case "$MODE" in auto|portrait|square|landscape) [[ $# -gt 0 ]] && shift || true ;; *) MODE="auto" ;; esac
[[ $# -lt 1 ]] && { echo "Usage: $0 [auto|portrait|square|landscape] input1 [input2 ...]"; exit 1; }

HB_BASE_ARGS=(
  --encoder x264
  --quality 18
  --x264-preset slow
  --optimize
  --format av_mp4
  --auto-anamorphic
  --keep-display-aspect
  --modulus 2
  --crop 0:0:0:0
  # Audio: universal AAC (avoid copy:all incompatibilities)
  --aencoder av_aac
  --ab 160
  --mixdown stereo
  --arate 48
)

for IN in "$@"; do
  [[ ! -f "$IN" ]] && { echo "Skipping missing file: $IN" >&2; continue; }

  FILE_MODE="$MODE"
  dims="$(get_dims "$IN")" || dims=""
  if [[ "$MODE" == "auto" && -n "$dims" ]]; then
    read -r SRC_W SRC_H <<<"$dims"
    FILE_MODE="$(choose_mode_by_aspect "$SRC_W" "$SRC_H")"
  fi
  apply_canvas "$FILE_MODE"

  BASENAME="${IN##*/}"; STEM="${BASENAME%.*}"; DIR="$(dirname "$IN")"
  TMP_OUT="${DIR}/${STEM}_${TAG}.tmp.mp4"
  OUT="${DIR}/${STEM}_${TAG}.mp4"

  HB_ARGS=( "${HB_BASE_ARGS[@]}" --maxWidth "$MW" --maxHeight "$MH" )

  if [[ -n "${SRC_W:-}" && -n "${SRC_H:-}" ]]; then
    aspect=$(awk -v w="$SRC_W" -v h="$SRC_H" 'BEGIN{printf "%.4f", w/h}')
    echo ">>> Source ${SRC_W}x${SRC_H} (AR=$aspect) → ${FILE_MODE} box ${MW}x${MH}"
  else
    echo ">>> ${FILE_MODE} box ${MW}x${MH} (source dims unavailable)"
  fi

  echo ">>> HB: $IN -> $TMP_OUT (fit <= ${MW}x${MH}, preserve aspect)"
  if ! HandBrakeCLI -i "$IN" -o "$TMP_OUT" "${HB_ARGS[@]}"; then
    echo "!!! HandBrake failed for: $IN" >&2
    rm -f "$TMP_OUT"
    continue
  fi

  # Guard: only proceed if HandBrake created a file with size
  if [[ ! -s "$TMP_OUT" ]]; then
    echo "!!! HandBrake produced no output for: $IN" >&2
    rm -f "$TMP_OUT"
    continue
  fi

  if $have_ffmpeg; then
    echo ">>> FFMPEG: pad to exact ${MW}x${MH} -> $OUT"
    ffmpeg -y -i "$TMP_OUT" \
      -vf "scale=${MW}:${MH}:force_original_aspect_ratio=decrease,pad=${MW}:${MH}:(ow-iw)/2:(oh-ih)/2" \
      -c:v libx264 -crf 18 -preset slow -c:a copy "$OUT" >/dev/null 2>&1
    rm -f "$TMP_OUT"
  else
    echo ">>> ffmpeg not found; keeping HandBrake output as-is (<= ${MW}x${MH})."
    mv -f "$TMP_OUT" "$OUT"
  fi

  echo "✓ Wrote: $OUT"
done

echo "Done."
