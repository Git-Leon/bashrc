#!/usr/bin/env bash
# Usage: stems path/to/song.mp3
# Splits audio into stems using Demucs and saves them in <filename>.stems/

set -e

FILE="$1"
if [ -z "$FILE" ]; then
  echo "Usage: stems <path-to-audio-file>"
  exit 1
fi

# Strip path and extension for folder name
BASENAME="$(basename "$FILE")"
NAME="${BASENAME%.*}"
OUTDIR="$(dirname "$FILE")/${NAME}.stems"

# --- Helper: ensure pip packages exist ---
ensure_pkg() {
  local pkg="$1"
  local ver="$2"
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

# --- Install dependencies if missing ---
ensure_pkg torch 2.4.1
ensure_pkg torchaudio 2.4.1
ensure_pkg soundfile
ensure_pkg demucs

# --- Run Demucs ---
echo "🎵 Separating stems for: $FILE"
python -m demucs --two-stems=vocals --out "$OUTDIR" "$FILE"

echo
echo "✅ Done!"
echo "Stems saved in: $OUTDIR"
ls "$OUTDIR"
