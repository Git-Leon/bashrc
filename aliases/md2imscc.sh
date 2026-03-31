#!/usr/bin/env bash
set -euo pipefail
# ──────────────────────────────────────────────────────────────────────
# md2imscc  –  Convert a *_converted-to-markdown/ directory to .imscc
#
# Usage:
#   md2imscc <path/to/name.zip_extracted_converted-to-markdown>
#
# The output .imscc file is written next to the input directory.
# For a directory named  "foo.zip_extracted_converted-to-markdown",
# the output is           "foo.imscc".
#
# Requires: Python 3.x (no extra pip packages)
# ──────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="${SCRIPT_DIR}/python/markdown-to-imscc.py"

# ── Detect Python ────────────────────────────────────────────────────

find_python() {
    # Prefer explicit Windows path (avoids Microsoft Store alias intercept)
    if [[ -x "/c/Python311/python.exe" ]]; then
        echo "/c/Python311/python.exe"
        return
    fi
    for cmd in python3 python py; do
        if command -v "$cmd" &>/dev/null; then
            # Verify it actually runs (not a Store redirect)
            if "$cmd" --version &>/dev/null; then
                echo "$cmd"
                return
            fi
        fi
    done
    echo ""
}

PYTHON="$(find_python)"
if [[ -z "$PYTHON" ]]; then
    echo "ERROR: Python not found. Install Python 3.x and ensure it is on PATH." >&2
    exit 1
fi

# ── Usage ─────────────────────────────────────────────────────────────

usage() {
    cat <<'EOF'
md2imscc — Convert markdown directory → IMS Common Cartridge (.imscc)

Usage:
    md2imscc <input_directory>

Arguments:
    <input_directory>  Path to a *_converted-to-markdown/ directory
                       produced by imscc2md.

Output:
    Writes <name>.imscc next to the input directory.

Examples:
    md2imscc public-course.zip_extracted_converted-to-markdown
    md2imscc /c/exports/my-course.zip_extracted_converted-to-markdown/
EOF
}

if [[ $# -lt 1 ]]; then
    usage
    exit 1
fi

INPUT_DIR="$1"

# ── Validate ──────────────────────────────────────────────────────────

# Strip trailing slashes
INPUT_DIR="${INPUT_DIR%/}"

if [[ ! -d "$INPUT_DIR" ]]; then
    echo "ERROR: Directory not found: $INPUT_DIR" >&2
    exit 1
fi

if [[ ! -f "${INPUT_DIR}/index.md" ]]; then
    echo "ERROR: index.md not found in ${INPUT_DIR}" >&2
    echo "       This does not look like a directory produced by imscc2md." >&2
    exit 1
fi

# ── Derive output path ───────────────────────────────────────────────

# Input pattern:  <name>.zip_extracted_converted-to-markdown
# Output pattern: <name>.imscc
BASE_DIR="$(dirname "$INPUT_DIR")"
DIR_NAME="$(basename "$INPUT_DIR")"

# Strip known suffixes
NAME="$DIR_NAME"
NAME="${NAME%.zip_extracted_converted-to-markdown}"
NAME="${NAME%_converted-to-markdown}"
NAME="${NAME%.zip_extracted}"

OUTPUT_PATH="${BASE_DIR}/${NAME}.imscc"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  md2imscc — Markdown → IMS Common Cartridge                ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║ Input:  ${INPUT_DIR}"
echo "║ Output: ${OUTPUT_PATH}"
echo "╚══════════════════════════════════════════════════════════════╝"
echo

# ── Run Python converter ─────────────────────────────────────────────

if [[ ! -f "$PYTHON_SCRIPT" ]]; then
    echo "ERROR: Python script not found at ${PYTHON_SCRIPT}" >&2
    exit 1
fi

"$PYTHON" "$PYTHON_SCRIPT" "$INPUT_DIR" "$OUTPUT_PATH"

if [[ -f "$OUTPUT_PATH" ]]; then
    SIZE=$(stat --printf="%s" "$OUTPUT_PATH" 2>/dev/null || stat -f "%z" "$OUTPUT_PATH" 2>/dev/null || echo "?")
    echo
    echo "Done ✓  ${OUTPUT_PATH} (${SIZE} bytes)"
else
    echo "ERROR: Output file was not created." >&2
    exit 1
fi
