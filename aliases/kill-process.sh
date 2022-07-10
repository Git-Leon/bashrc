#!/bin/bash
if [ "$1" ]
  then
    currentDirectory=$HOME/bashrc/aliases
    script=$currentDirectory/batch/kill-process.bat
    cmd "/C $($currentDirectory/convert-path.sh $script) $1"
  fi
