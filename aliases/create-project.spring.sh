#!/bin/bash
if [ "$1" ]
    then
        git clone https://github.com/curriculeon/spring.projecttemplate $1
        cd $1
        rm -rf .git
    fi