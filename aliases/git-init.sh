#!/bin/bash
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
$SCRIPTPATH/get-gitignore.sh

# ...existing code...
repoName=$1
commitMessage="${@:2}"

# --- File size check (same behavior as git-ac.sh) ---
MAX_SIZE=$((50 * 1024 * 1024))  # 50 MB in bytes

# Find files over 50MB (excluding .git folder)
large_files=$(find . -type f ! -path "./.git/*" -size +${MAX_SIZE}c)

echo checking for large files...
if [ -n "$large_files" ]; then
  echo "❌ Aborting: The following file(s) exceed 50MB and cannot be committed to GitHub:"
  echo ""
  printf "%-80s %10s\n" "File" "Size (MB)"
  printf "%-80s %10s\n" "----" "---------"

  while IFS= read -r file; do
    # Use stat -c%s for GNU stat; fallback to wc -c if needed
    if size_bytes=$(stat -c%s "$file" 2>/dev/null); then
      :
    else
      size_bytes=$(wc -c <"$file" 2>/dev/null || echo 0)
    fi
    size_mb=$(awk "BEGIN {printf \"%.2f\", $size_bytes/1024/1024}")
    printf "%-80s %10s\n" "$file" "$size_mb"
  done <<< "$large_files"

  echo ""
  exit 1
fi
# --- end file size check ---

git init
git add .
git commit -m "$commitMessage"
gh repo create $repoName --public --source=. --remote=upstream --push
origin=$(git remote -v | grep fetch)
origin=$(echo ${origin/"upstream        "/""})
origin=$(echo ${origin/"upstream"/""})
origin=$(echo ${origin// (fetch)/})
origin=$(echo ${origin/"origin"/""})

git remote add origin $origin