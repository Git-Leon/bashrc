#!/bin/bash
if [ "$1" ]
  then
    currentDirectory=$HOME/bashrc/aliases
    script=$currentDirectory/batch/restart-process.bat
    executablePath="$($currentDirectory/batch/get-process-executable-path.bat $1)"
    executablePath=$(echo "$executablePath" | tr -d '"')
    cmd "/C $($currentDirectory/convert-path.sh $script) $1"
    $executablePath &
  fi
