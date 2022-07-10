#!/bin/bash
if [ "$1" ]
  then
    { #try 
        kill -9 $(lsof -t -i:$1) 2>/dev/null
    } || { # catch
        script=$HOME/bashrc/aliases/batch/kill-port.bat
        cmd "/C $($HOME/bashrc/aliases/convert-path.sh $script) $1"
    }
fi

