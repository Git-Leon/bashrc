#!/bin/bash
if [ "$1" ]
  then
        ECHO hello world
        batFileUnixPath="$PWD"/kill-port.bat
        batFileDosPath="$PWD"/.tmp
        ECHO "$batFileUnixPath" | sed 's/^\///' | sed 's/\//\\/g' | sed 's/^./\0:/' > $batFileDosPath
        
        batFileDosPath=$(cat $batFileDosPath)
        rm $batFileDosPath 
        touch $batFileDosPath
        ECHO taskkill \/f \/im $1 > $batFileDosPath
        ECHO taskkill \/f \/FI "WINDOWTITLE eq $1" >> $batFileDosPath
        cmd "/C $batFileDosPath"
        #rm $batFile 

fi


