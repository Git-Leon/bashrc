#!/bin/bash
if [ "$1" ]
  then  
    script=$HOME/bashrc/aliases/batch/kill-process.bat
    cmd "/C $($HOME/bashrc/aliases/convert-path.sh $script) $1"
  fi


