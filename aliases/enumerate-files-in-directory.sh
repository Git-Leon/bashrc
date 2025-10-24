#!/bin/bash

i=1

# Use find to list only regular files (not directories), sorted by mod time
find . -maxdepth 1 -type f ! -name "$(basename "$0")" | sort | while read -r file; do
  # Strip the leading ./ if present
  basefile=$(basename "$file")
  prefix=$(printf "%03d" "$i")
  mv -- "$file" "${prefix}_$basefile"
  ((i++))
done
