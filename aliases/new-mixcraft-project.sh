#!/bin/bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
DATE=$(date +%m%d%Y)
VERSION=1

# Find a unique project folder name
while true; do
    PROJECT_FOLDER="mixcraft.${DATE}_v${VERSION}"
    if [ ! -d "$PROJECT_FOLDER" ]; then
        break
    fi
    VERSION=$((VERSION + 1))
done

$SCRIPT_DIR/create-project.mixcraft.sh "$PROJECT_FOLDER"
cd "$PROJECT_FOLDER" || exit
start project/project.mx8