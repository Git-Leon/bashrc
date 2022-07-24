#!/bin/bash
if [ "$1" ]
    then
        directoryName=`echo "${1%.*}"`
        rm -rf unjarred/$directoryName
        mkdir -p unjarred/$directoryName
        cp $1 unjarred/$directoryName/$1
        cd unjarred/$directoryName
        jar xf $1
        classes=$(jar -tf $1 | grep class | sed 's/.class//g')
        echo $classes > .tmp.txt
        for class in $(cat .tmp.txt); do javap -classpath $1 -c $class; done
        cat .tmp.txt
        rm .tmp.txt
    fi