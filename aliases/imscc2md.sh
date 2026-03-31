#!/usr/bin/env bash
set -euo pipefail

# ==================================================================
# imscc2md.sh — Convert Canvas IMS Common Cartridge exports to Markdown
#
# Usage:
#   imscc2md <file1.imscc> [file2.imscc] ...
#   imscc2md                                   # auto-discover *.imscc in cwd
#
# For each .imscc file, produces a directory:
#   <basename>/
#     <basename>.imscc
#     <basename>.zip
#     <basename>.zip_extracted/
#       imsmanifest.xml, *.xml, ...
#     <basename>.zip_extracted_converted-to-markdown/
#       index.md, assignments/, pages/, quizzes/, external/, discussions/, projects/
#
# Requirements: python (3.x), unzip (or 7z)
# ==================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONVERTER="$SCRIPT_DIR/python/imscc-to-markdown.py"

# ── Resolve arguments (default: all .imscc in cwd) ─────────────────────

if [ $# -eq 0 ]; then
  shopt -s nullglob
  IMSCC_FILES=(*.imscc)
  shopt -u nullglob
  if [ ${#IMSCC_FILES[@]} -eq 0 ]; then
    echo "ERROR: No .imscc files provided and none found in $(pwd)"
    echo "Usage: imscc2md [file1.imscc] [file2.imscc] ..."
    echo "       (or run from a directory containing .imscc files)"
    exit 1
  fi
  echo "No arguments provided — found ${#IMSCC_FILES[@]} .imscc file(s) in $(pwd):"
  printf '  %s\n' "${IMSCC_FILES[@]}"
  echo ""
  set -- "${IMSCC_FILES[@]}"
fi

# ── Detect Python ────────────────────────────────────────────────────────

PYTHON=""
for cmd in python py python3; do
  if command -v "$cmd" &>/dev/null; then
    if "$cmd" --version &>/dev/null 2>&1; then
      PYTHON="$cmd"
      break
    fi
  fi
done

if [ -z "$PYTHON" ]; then
  echo "ERROR: No working Python 3 interpreter found."
  echo "Tried: python, py, python3"
  exit 1
fi
echo "Using Python: $PYTHON ($($PYTHON --version 2>&1))"

# ── Detect unzip ─────────────────────────────────────────────────────────

UNZIP_CMD=""
if command -v unzip &>/dev/null; then
  UNZIP_CMD="unzip"
elif command -v 7z &>/dev/null; then
  UNZIP_CMD="7z"
else
  echo "ERROR: No unzip tool found. Install 'unzip' or '7z'."
  exit 1
fi
echo "Using unzip: $UNZIP_CMD"

# ── Verify converter exists ─────────────────────────────────────────────

if [ ! -f "$CONVERTER" ]; then
  echo "ERROR: Converter not found: $CONVERTER"
  exit 1
fi
echo "Using converter: $CONVERTER"
echo ""

# ── Process each .imscc file ────────────────────────────────────────────

TOTAL=$#
SUCCESS=0
FAIL=0

for IMSCC_PATH in "$@"; do

  echo "============================================================"
  echo "Processing: $IMSCC_PATH"
  echo "============================================================"

  # ── Validate input file ──
  if [ ! -f "$IMSCC_PATH" ]; then
    echo "  ERROR: File not found: $IMSCC_PATH"
    FAIL=$((FAIL + 1))
    continue
  fi

  IMSCC_PATH="$(cd "$(dirname "$IMSCC_PATH")" && pwd)/$(basename "$IMSCC_PATH")"

  if [[ "$IMSCC_PATH" != *.imscc ]]; then
    echo "  ERROR: Not an .imscc file: $IMSCC_PATH"
    FAIL=$((FAIL + 1))
    continue
  fi

  # ── Derive names ──
  IMSCC_FILE="$(basename "$IMSCC_PATH")"
  BASENAME="${IMSCC_FILE%.imscc}"
  OUTPUT_DIR="$(pwd)/$BASENAME"
  ZIP_FILE="$BASENAME.zip"
  EXTRACTED_DIR="${ZIP_FILE}_extracted"
  CONVERTED_DIR="${ZIP_FILE}_extracted_converted-to-markdown"

  echo "  Output directory: $OUTPUT_DIR"
  echo "  Basename:         $BASENAME"

  # ── Create output directory (idempotent) ──
  mkdir -p "$OUTPUT_DIR"

  # ── Step 1: Copy .imscc into output directory ──
  if [ ! -f "$OUTPUT_DIR/$IMSCC_FILE" ]; then
    echo "  [1/5] Copying .imscc → $OUTPUT_DIR/"
    cp "$IMSCC_PATH" "$OUTPUT_DIR/$IMSCC_FILE"
  else
    echo "  [1/5] .imscc already present, skipping copy"
  fi

  # ── Step 2: Create .zip copy ──
  if [ ! -f "$OUTPUT_DIR/$ZIP_FILE" ]; then
    echo "  [2/5] Creating .zip copy"
    cp "$OUTPUT_DIR/$IMSCC_FILE" "$OUTPUT_DIR/$ZIP_FILE"
  else
    echo "  [2/5] .zip already present, skipping"
  fi

  # ── Step 3: Extract .zip ──
  if [ ! -d "$OUTPUT_DIR/$EXTRACTED_DIR" ]; then
    echo "  [3/5] Extracting .zip → $EXTRACTED_DIR/"
    mkdir -p "$OUTPUT_DIR/$EXTRACTED_DIR"
    if [ "$UNZIP_CMD" = "unzip" ]; then
      unzip -q -o "$OUTPUT_DIR/$ZIP_FILE" -d "$OUTPUT_DIR/$EXTRACTED_DIR"
    else
      7z x -y -o"$OUTPUT_DIR/$EXTRACTED_DIR" "$OUTPUT_DIR/$ZIP_FILE" > /dev/null
    fi
  else
    echo "  [3/5] Extracted directory already exists, skipping"
  fi

  # ── Validate extraction ──
  if [ ! -f "$OUTPUT_DIR/$EXTRACTED_DIR/imsmanifest.xml" ]; then
    echo "  ERROR: imsmanifest.xml not found after extraction. Invalid .imscc?"
    FAIL=$((FAIL + 1))
    continue
  fi

  # ── Step 4: Copy converter into extracted dir ──
  echo "  [4/5] Copying convert_to_markdown.py"
  cp "$CONVERTER" "$OUTPUT_DIR/$EXTRACTED_DIR/convert_to_markdown.py"

  # ── Step 5: Run the converter ──
  # cd into the extracted dir so that BASE_DIR resolves to a short relative
  # path, avoiding Windows 260-char path length errors on deep filenames.
  if [ ! -d "$OUTPUT_DIR/$CONVERTED_DIR" ]; then
    echo "  [5/5] Running Python converter..."
    (cd "$OUTPUT_DIR/$EXTRACTED_DIR" && $PYTHON convert_to_markdown.py)

    # The converter outputs to _extracted/content/ — rename to match expected structure
    if [ -d "$OUTPUT_DIR/$EXTRACTED_DIR/content" ]; then
      mv "$OUTPUT_DIR/$EXTRACTED_DIR/content" "$OUTPUT_DIR/$CONVERTED_DIR"
      echo "  Moved content/ → $CONVERTED_DIR/"
    else
      echo "  ERROR: Converter did not produce content/ directory"
      FAIL=$((FAIL + 1))
      continue
    fi
  else
    echo "  [5/5] Converted directory already exists, skipping"
  fi

  # ── Verification ──
  MD_COUNT=$(find "$OUTPUT_DIR/$CONVERTED_DIR" -name '*.md' | wc -l)
  echo ""
  echo "  ✓ SUCCESS: $BASENAME"
  echo "    Markdown files produced: $MD_COUNT"
  echo "    Output: $OUTPUT_DIR/"
  echo "    Structure:"
  echo "      $BASENAME/"
  echo "        $IMSCC_FILE"
  echo "        $ZIP_FILE"
  echo "        $EXTRACTED_DIR/"
  echo "        $CONVERTED_DIR/"
  for subdir in "$OUTPUT_DIR/$CONVERTED_DIR"/*/; do
    if [ -d "$subdir" ]; then
      dname=$(basename "$subdir")
      dcount=$(find "$subdir" -name '*.md' | wc -l)
      echo "          $dname/ ($dcount files)"
    fi
  done
  echo ""
  SUCCESS=$((SUCCESS + 1))

done

# ── Summary ─────────────────────────────────────────────────────────────

echo ""
echo "============================================================"
echo "BATCH COMPLETE"
echo "============================================================"
echo "  Total:   $TOTAL"
echo "  Success: $SUCCESS"
echo "  Failed:  $FAIL"
echo ""
