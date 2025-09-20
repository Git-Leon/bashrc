#!/bin/bash
MAX_SIZE=$((50 * 1024 * 1024))  # 50 MB in bytes

# Find files over 50MB (excluding .git folder)
large_files=$(find . -type f ! -path "./.git/*" -size +${MAX_SIZE}c)

# If large files exist, display a table and exit
echo checking for large files...
if [ -n "$large_files" ]; then
  echo "❌ Aborting: The following file(s) exceed 50MB and cannot be committed to GitHub:"
  echo ""
  printf "%-80s %10s\n" "File" "Size (MB)"
  printf "%-80s %10s\n" "----" "---------"

  while IFS= read -r file; do
    size_bytes=$(stat -c%s "$file")
    size_mb=$(awk "BEGIN {printf \"%.2f\", $size_bytes/1024/1024}")
    printf "%-80s %10s\n" "$file" "$size_mb"
  done <<< "$large_files"

  echo ""
  exit 1
fi

git config core.filemode true
echo "git branch"
git branch

echo "git status"
git status

echo "git add ."
git add .

echo "git commit -m \"$*\""
git commit -m "$*"
