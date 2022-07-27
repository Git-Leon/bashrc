#!/bin/bash
if [ "$1" ]
  then
    { #try
      currentDirectory=$HOME/bashrc/aliases
      script=$currentDirectory/batch/kill-process.bat
      cmd "/C $($currentDirectory/convert-path.sh $script) $1" 2>null
    } || { #catch      
      ps -ef | grep $1 | grep -v grep | awk '{print $2}' | xargs -r kill -9
    }
  fi
