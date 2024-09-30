#!/bin/bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
if [ "$1" ]
    then
        git clone --recurse-submodules https://github.com/cymatic-productions/mixcraft.projecttemplate $1
        cd $1
        rm -rf .git
fi