#! /bin/bash   
set -m
tmpFile=$HOME/bashrc/aliases/.tmp
ECHO "$1" | sed 's/^\///' | sed 's/\//\\/g' | sed 's/^./\0:/' > $tmpFile 
dosPath=$(cat $tmpFile)
echo $dosPath
rm -rf $tmpFile
rm -rf $tmpFile