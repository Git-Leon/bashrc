#!/bin/bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
if [ "$1" ]
    then
        echo git clone --recurse-submodules https://github.com/cymatic-productions/mixcraft.projecttemplate $1
        git clone --recurse-submodules https://github.com/cymatic-productions/mixcraft.projecttemplate $1
        cd $1
        git submodule init
        git submodule update
        rm -rf .git
fi