#!/usr/bin/env bash
# upscale.sh — IG-compliant canvas + hard size cap via ffmpeg two-pass
#
# Usage:
#   ./upscale.sh [auto|portrait|square|landscape] input1 [input2 ...]
#
# Defaults:
#   MODE=auto
#   TARGET_MB=49           # a little under 50MB to be safe
#   AUDIO_KBPS=128         # audio bitrate budget
#   VB_MIN_KBPS=300        # floor to avoid encoder starvation
#   VB_MAX_KBPS=20000      # safety ceiling

set -euo pipefail

MODE="${1:-auto}"
case "$MODE" in auto|portrait|square|landscape) [[ $# -gt 0 ]] && shift || true ;; *) MODE="auto" ;; esac
[[ $# -lt 1 ]] && { echo "Usage: $0 [auto|portrait|square|landscape] input1 [input2 ...]"; exit 1; }

command -v ffmpeg >/dev/null 2>&1 || { echo "Error: ffmpeg not found."; exit 1; }
command -v ffprobe >/dev/null 2>&1 || { echo "Error: ffprobe not found."; exit 1; }

# ---- Tunables ----
TARGET_MB=${TARGET_MB:-49}
AUDIO_KBPS=${AUDIO_KBPS:-128}
VB_MIN_KBPS=${VB_MIN_KBPS:-300}
VB_MAX_KBPS=${VB_MAX_KBPS:-20000}

# ---- Helpers ----
get_dims() {
  local in="$1"; ffprobe -v error -select_streams v:0 \
    -show_entries stream=width,height -of csv=p=0:s=' ' "$in"
}

get_dur_sec() {
  local in="$1"; ffprobe -v error -show_entries format=duration -of csv=p=0 "$in" | awk '{printf("%.3f\n",$1)}'
}

choose_mode_by_aspect() {
  local w="$1" h="$2"
  [[ "$h" -eq 0 ]] && { echo "portrait"; return; }
  local a; a=$(awk -v w="$w" -v h="$h" 'BEGIN{printf "%.4f", w/h}')
  awk -v a="$a" 'BEGIN{ if (a<=0.90) print "portrait"; else if (a<1.20) print "square"; else print "landscape"; }'
}

apply_canvas() {
  case "$1" in
    portrait)  CANVAS_W=1080; CANVAS_H=1350; TAG="ig-POR" ;;
    square)    CANVAS_W=1080; CANVAS_H=1080; TAG="ig-SQ"  ;;
    landscape) CANVAS_W=1080; CANVAS_H=566;  TAG="ig-LS"  ;;
    *)         CANVAS_W=1080; CANVAS_H=1350; TAG="ig-POR" ;;
  esac
}

calc_vb_kbps() {
  # total_bits = TARGET_MB * 1e6 * 8
  # total_kbps = total_bits / dur_sec / 1000
  # video_kbps = total_kbps - audio_kbps
  local dur="$1"
  awk -v mb="$TARGET_MB" -v a="$AUDIO_KBPS" -v d="$dur" -v vmin="$VB_MIN_KBPS" -v vmax="$VB_MAX_KBPS" '
    BEGIN{
      if (d<=0) { print vmin; exit }
      total_kbps=(mb*1000000*8)/(d*1000)
      v=total_kbps - a
      if (v < vmin) v=vmin
      if (v > vmax) v=vmax
      printf "%.0f\n", v
    }'
}

for IN in "$@"; do
  [[ ! -f "$IN" ]] && { echo "Skipping missing file: $IN" >&2; continue; }

  # Detect mode by aspect if auto
  read -r W H <<<"$(get_dims "$IN")"
  SRC_MODE="$MODE"
  if [[ "$MODE" == "auto" && -n "${W:-}" && -n "${H:-}" ]]; then
    SRC_MODE="$(choose_mode_by_aspect "$W" "$H")"
  fi
  apply_canvas "$SRC_MODE"

  # Duration and bitrate budget
  DUR="$(get_dur_sec "$IN")"
  VB_KBPS="$(calc_vb_kbps "$DUR")"
  # Use a modest rate control setup; bufsize ~2x, maxrate ~1.25x
  MAXRATE_KBPS=$(awk -v v="$VB_KBPS" 'BEGIN{printf "%.0f", v*1.25}')
  BUFSIZE_KBPS=$(awk -v v="$VB_KBPS" 'BEGIN{printf "%.0f", v*2.00}')

  BASENAME="${IN##*/}"; STEM="${BASENAME%.*}"; DIR="$(dirname "$IN")"
  OUT="${DIR}/${STEM}_${TAG}.mp4"
  LOGPREFIX="${DIR}/.passlog_${STEM}_${TAG}"

  echo ">>> Source ${W}x${H}, mode=${SRC_MODE}, canvas=${CANVAS_W}x${CANVAS_H}, dur=${DUR}s"
  echo ">>> Target size ≤ ${TARGET_MB} MB → video ~${VB_KBPS} kbps, audio ${AUDIO_KBPS} kbps"

  # Common scaling+pad filter (no stretch; center pad)
  VF="scale=${CANVAS_W}:${CANVAS_H}:force_original_aspect_ratio=decrease,pad=${CANVAS_W}:${CANVAS_H}:(ow-iw)/2:(oh-ih)/2"

  # Pass 1 (no audio)
  ffmpeg -y -hide_banner -loglevel error \
    -i "$IN" -vf "$VF" -an \
    -c:v libx264 -preset slow -profile:v high \
    -b:v ${VB_KBPS}k -maxrate ${MAXRATE_KBPS}k -bufsize ${BUFSIZE_KBPS}k \
    -pass 1 -passlogfile "$LOGPREFIX" -movflags +faststart \
    -f mp4 /dev/null

  # Pass 2
  ffmpeg -y -hide_banner -loglevel error \
    -i "$IN" -vf "$VF" \
    -c:v libx264 -preset slow -profile:v high \
    -b:v ${VB_KBPS}k -maxrate ${MAXRATE_KBPS}k -bufsize ${BUFSIZE_KBPS}k \
    -pass 2 -passlogfile "$LOGPREFIX" -movflags +faststart \
    -c:a aac -b:a ${AUDIO_KBPS}k -ac 2 -ar 48000 \
    "$OUT"

  # Clean up pass logs (Windows Git Bash friendly)
  rm -f "${LOGPREFIX}-0.log" "${LOGPREFIX}-0.log.mbtree" "${LOGPREFIX}.log" "${LOGPREFIX}.log.mbtree" 2>/dev/null || true

  # Safety check
  ACTUAL_BYTES=$(wc -c < "$OUT" | tr -d '[:space:]')
  echo "✓ Wrote: $OUT ($(awk -v b="$ACTUAL_BYTES" 'BEGIN{printf "%.2f", b/1000000}') MB)"
done

echo "Done."
