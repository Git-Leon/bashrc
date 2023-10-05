#!/bin/bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
if [ "$1" ]
    then
        git clone https://github.com/cymatic-productions/mixcraft.projecttemplate $1
        cd $1
        rm -rf .git
        mv track-render.mp3 $1.mp3
        mv project/project.mx8 project/$1.mx8
        mv project/project-render.mx8 project/$1.mx8
fi