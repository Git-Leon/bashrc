#!/bin/bash
killPort() {
  if [ "$1" ]
    then
    echo "Attempting to kill process on $1"
      processIds=$(netstat -a -n -b -o | grep $1 | sed -e "s/[[:space:]]\+/ /g" | cut -d ' ' -f6)
      for processId in $processIds; do
        { #try 
          echo "Attempting to kill process on $1, using BASH syntax"
          taskkill /PID /F "$processId" 2>null
          echo "Process on $1 killed."
          return
        } || { # catch
          echo "Attempting to kill process on $1, using cygwin syntax"
          taskkill //F //PID "$processId"
          echo "Process on $1 killed."
          return
        }
      done
      echo "Process on $1 NOT killed."
  fi
}

killPort $1