#!/bin/bash
MAX_SIZE=$((50 * 1024 * 1024))  # 100 MB in bytes

# Check for files over 100MB
large_files=$(find . -type f ! -path "./.git/*" -size +${MAX_SIZE}c)

if [ -n "$large_files" ]; then
  echo "❌ Aborting: The following file(s) exceed 100MB and cannot be committed to GitHub:"
  echo "$large_files"
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
