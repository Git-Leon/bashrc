#! /bin/bash   
set -m
tmpFile="$PWD"/.tmp
ECHO "$1" | sed 's/^\///' | sed 's/\//\\/g' | sed 's/^./\0:/' > $tmpFile 
dosPath=$(cat $tmpFile)
echo $dosPath
rm $tmpFile
rm -rf $tmpFile