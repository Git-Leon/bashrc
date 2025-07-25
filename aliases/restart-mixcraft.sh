#!/bin/bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
$SCRIPT_DIR/kill-process.sh mixcraft8
start project/project.mx8