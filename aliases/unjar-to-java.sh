#!/bin/bash
if [ "$1" ]
    then
        directoryName=`echo "${1%.*}"`
        rm -rf unjarred/$directoryName
        mkdir -p unjarred/$directoryName
        cp $1 unjarred/$directoryName/$1
        cd unjarred/$directoryName
        jar xf $1
        javap -classpath $1 -c $(jar -tf $1 | grep class | sed 's/.class//g')
    fi