#!/usr/bin/env bash
set -euo pipefail

# ===== Config =====
TARGET_SIZE_MB=50                # hard cap (<= this after encode)
AUDIO_KBPS=192                   # audio bitrate target (CBR)
VIDEO_ENCODER="x264"             # x264 for compatibility, x265 for smaller files
X264_PRESET="medium"             # slower = better quality at same bitrate
RETRIES=3                        # extra attempts if size slightly exceeds cap
SAFETY_MARGIN_PCT=5              # tighten initial bitrate by this percent
FILES=("$@")
# ==================

# --- helpers ---
require_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1"; exit 1; }; }
ceil() { awk -v n="$1" 'BEGIN{ printf("%d", (n==int(n)?n:int(n)+1)) }'; }

get_duration_sec() {
  local f="$1"
  if command -v ffprobe >/dev/null 2>&1; then
    # seconds (float); ceil to be safe
    local d
    d=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$f" || echo 0)
    [[ -z "$d" || "$d" = "N/A" ]] && d=0
    ceil "$d"
  elif command -v mediainfo >/dev/null 2>&1; then
    # milliseconds -> seconds; ceil
    local ms
    ms=$(mediainfo --Inform="General;%Duration%" "$f" 2>/dev/null || echo 0)
    awk -v ms="${ms:-0}" 'BEGIN{ s=ms/1000; printf("%d",(s==int(s)?s:int(s)+1)) }'
  else
    echo "0"
  fi
}

# Detect pass flag for your HandBrakeCLI version
PASS_FLAG=""
if HandBrakeCLI --help 2>&1 | grep -q -- "--multi-pass"; then
  PASS_FLAG="--multi-pass"
elif HandBrakeCLI --help 2>&1 | grep -q -- "--two-pass"; then
  PASS_FLAG="--two-pass"
fi

require_cmd HandBrakeCLI

BYTES_TARGET=$(( TARGET_SIZE_MB * 1000 * 1000 ))   # decimal MB to bytes

echo "Target size cap: ${TARGET_SIZE_MB} MB"
[[ -n "$PASS_FLAG" ]] && echo "Using $PASS_FLAG" || echo "Single-pass mode detected."

for f in "${FILES[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "File not found: $f"
    continue
  fi

  duration_sec=$(get_duration_sec "$f")
  if [[ "$duration_sec" -le 0 ]]; then
    echo "Could not determine duration for: $f"
    echo "Install ffprobe (from ffmpeg) or mediainfo and try again."
    exit 1
  fi

  # Compute total bitrate (kbps) to fit under cap, then apply safety margin.
  # total_kbps = (bytes * 8) / seconds / 1000
  total_kbps=$(( (BYTES_TARGET * 8) / duration_sec / 1000 ))
  margin=$(( total_kbps * SAFETY_MARGIN_PCT / 100 ))
  total_kbps=$(( total_kbps - margin ))

  # Ensure audio fits; give remainder to video.
  if (( total_kbps <= AUDIO_KBPS + 16 )); then
    # If audio alone would blow the budget for very short clips, clamp aggressively.
    video_kbps=100
    audio_kbps=$(( total_kbps - video_kbps ))
    (( audio_kbps < 64 )) && audio_kbps=64
  else
    audio_kbps=$AUDIO_KBPS
    video_kbps=$(( total_kbps - audio_kbps ))
  fi

  # Sensible floors/ceilings
  (( video_kbps < 100 )) && video_kbps=100
  (( audio_kbps < 64 )) && audio_kbps=64

  base_out="${f%.*}_50mb.mp4"
  out="$base_out"

  echo "------------------------------------------------------------"
  echo "Source:        $f"
  echo "Duration:      ${duration_sec}s"
  echo "Initial budget: total ~${total_kbps} kbps  (video ${video_kbps} + audio ${audio_kbps})"
  echo "Encoder:       ${VIDEO_ENCODER} preset=${X264_PRESET}"

  attempt=1
  current_video_kbps=$video_kbps
  current_audio_kbps=$audio_kbps

  while : ; do
    [[ $attempt -gt 1 ]] && out="${base_out%.mp4}_try${attempt}.mp4"

    echo "→ Encode attempt #$attempt at ~${current_video_kbps} kbps video / ${current_audio_kbps} kbps audio -> $out"

    HandBrakeCLI \
      -i "$f" \
      -o "$out" \
      -e "$VIDEO_ENCODER" \
      --${VIDEO_ENCODER}-preset "$X264_PRESET" \
      -b "$current_video_kbps" \
      -B "$current_audio_kbps" \
      ${PASS_FLAG:+$PASS_FLAG} \
      --optimize \
      --verbose=1

    size_bytes=$(stat -c%s "$out")
    if [[ -z "${size_bytes:-}" ]]; then
      # macOS fallback
      size_bytes=$(stat -f%z "$out")
    fi

    echo "Output size:   $(( size_bytes / 1000 / 1000 )) MB"

    if (( size_bytes <= BYTES_TARGET )); then
      # Success under cap
      # If we produced a _tryN file, rename to the base name.
      if [[ "$out" != "$base_out" ]]; then
        mv -f "$out" "$base_out"
      fi
      echo "✅ Success: ${base_out} is ≤ ${TARGET_SIZE_MB} MB"
      break
    fi

    # If we reach here, we exceeded the cap. Prepare another attempt or give up.
    if (( attempt >= RETRIES )); then
      echo "⚠️  Reached max retries ($RETRIES). Result is over ${TARGET_SIZE_MB} MB."
      echo "   You can lower AUDIO_KBPS or X264_PRESET=slower, or switch VIDEO_ENCODER=x265."
      break
    fi

    # Scale down video bitrate based on actual overage (keep a 2% cushion).
    # new_video = old_video * (target_size / actual_size) * 0.98
    ratio=$(awk -v t="$BYTES_TARGET" -v a="$size_bytes" 'BEGIN{ printf "%.6f", (t/a)*0.98 }')
    new_video=$(awk -v v="$current_video_kbps" -v r="$ratio" 'BEGIN{ printf "%d", (v*r<100?100:v*r) }')
    echo "   Over cap; reducing video bitrate by factor ${ratio} → ${new_video} kbps"
    current_video_kbps=$new_video
    attempt=$(( attempt + 1 ))
  done
done

echo "✅ All done."
