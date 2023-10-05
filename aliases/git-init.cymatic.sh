#!/bin/bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
commitMessage="${@:2}"
if [ "$1" ] && [ "$commitMessage" ]
    then
        $SCRIPT_DIR/git-init.sh cymatic-productions/$1 $commitMessage
fi