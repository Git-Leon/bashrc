#!/bin/bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
commitMessage="${@:2}"
if [ "$1" ] && [ "$commitMessage" ]
    then
        git clone https://github.com/cymatic-productions/mixcraft.projecttemplate $1
        cd $1
        rm -rf .git
        $SCRIPT_DIR/git-init.sh cymatic-productions/$1 $commitMessage
fi