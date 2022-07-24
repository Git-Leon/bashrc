#!/bin/bash
if [ "$1" ]
    then
        git clone https://github.com/curriculeon/maven.projecttemplate $1
        cd $1
        rm -rf .git
    fi