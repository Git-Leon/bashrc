#!/bin/bash
if [ "$1" ]
  then
    currentDirectory=$HOME/bashrc/aliases
    script=$currentDirectory/batch/restart-process.bat
    cmd "/C $($currentDirectory/convert-path.sh $script) $1"
  fi
