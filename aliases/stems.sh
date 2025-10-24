#!/usr/bin/env bash
# Usage: stems path/to/song.mp3
# Splits audio into stems using Demucs and saves them in <filename>.stems/
# Output files are renamed to <filename>.<stem>.wav
# Exits if the destination folder already exists.

set -euo pipefail

FILE="${1:-}"
if [ -z "$FILE" ]; then
  echo "Usage: stems <path-to-audio-file>"
  exit 1
fi

# Strip path and extension for folder name
BASENAME="$(basename "$FILE")"
NAME="${BASENAME%.*}"
BASEDIR="$(cd "$(dirname "$FILE")" && pwd)"
OUTDIR="${BASEDIR}/${NAME}.stems"

# Exit if destination exists
if [ -d "$OUTDIR" ]; then
  echo "❌ Output directory already exists:"
  echo "   $OUTDIR"
  echo "Refusing to overwrite. Delete it or choose a different input."
  exit 2
fi

# --- Helper: ensure pip packages exist ---
ensure_pkg() {
  local pkg="$1"
  local ver="${2:-}"
  if ! python -m pip show "$pkg" >/dev/null 2>&1; then
    if [ -n "$ver" ]; then
      echo "Installing $pkg==$ver ..."
      python -m pip install "$pkg==$ver" -q
    else
      echo "Installing $pkg ..."
      python -m pip install "$pkg" -q
    fi
  fi
}

# --- Install dependencies if missing (stable combo) ---
ensure_pkg torch 2.4.1
ensure_pkg torchaudio 2.4.1
ensure_pkg soundfile
ensure_pkg demucs

echo "🎵 Separating stems for: $FILE"
python -m demucs --out "$OUTDIR" "$FILE"

# --- Flatten directory structure (model-agnostic) ---
# Expect: $OUTDIR/<model>/<song>/*.wav  → move into $OUTDIR
MODEL_DIR="$(find "$OUTDIR" -mindepth 1 -maxdepth 1 -type d | head -n 1 || true)"
SONG_DIR=""
if [ -n "${MODEL_DIR}" ] && [ -d "$MODEL_DIR" ]; then
  SONG_DIR="$(find "$MODEL_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1 || true)"
fi

mkdir -p "$OUTDIR.tmp"

if [ -n "$SONG_DIR" ] && [ -d "$SONG_DIR" ]; then
  # Move only WAVs from expected song dir
  shopt -s nullglob
  WAVS=( "$SONG_DIR"/*.wav )
  if [ "${#WAVS[@]}" -gt 0 ]; then
    mv "${WAVS[@]}" "$OUTDIR.tmp"/
  fi
  shopt -u nullglob
else
  # Fallback: grab any wavs under OUTDIR recursively
  find "$OUTDIR" -type f -name '*.wav' -exec mv {} "$OUTDIR.tmp"/ \;
fi

# If nothing moved, error out
if ! ls "$OUTDIR.tmp"/*.wav >/dev/null 2>&1; then
  echo "❌ No WAV stems found to move. Something went wrong."
  exit 3
fi

# Clean old nested folders, keep OUTDIR
find "$OUTDIR" -mindepth 1 -maxdepth 1 ! -name "$(basename "$OUTDIR.tmp")" -exec rm -rf {} +

# Put the wavs back into OUTDIR
mv "$OUTDIR.tmp"/* "$OUTDIR"/
rmdir "$OUTDIR.tmp"

# --- Rename stems to <filename>.<stem>.wav ---
echo "🎶 Renaming stems..."
cd "$OUTDIR"

# Map Demucs names -> your desired names
declare -A MAP=(
  ["vocals"]="vocal"
  ["drums"]="drum"
  ["bass"]="bass"
  ["other"]="other"
  ["accompaniment"]="instrumental"  # if you ever use 2-stem
)

shopt -s nullglob nocaseglob
for f in *.wav; do
  stem="$(basename "$f" .wav)"
  stem_lc="${stem,,}"
  newstem="${MAP[$stem_lc]:-$stem_lc}"
  mv -f -- "$f" "${NAME}.${newstem}.wav"
done
shopt -u nullglob nocaseglob

echo
echo "✅ Done!"
echo "Stems saved in: $OUTDIR"
ls -1 "$OUTDIR"
