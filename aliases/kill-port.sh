#!/bin/bash
if [ "$1" ]
  then
    portNumbers=$(netstat -a -n -b -o | grep $1 | sed -e "s/[[:space:]]\+/ /g" | cut -d ' ' -f6)        
    echo "Attempting to kill process running port number $1"
    for portNumber in $portNumbers; do
      { #try 
          echo "Attempting to kill process running port number $1 using CYGWIN syntax"
            taskkill //F //PID "$portNumber"
          echo "Process on $1 killed."
      } || { # catch
          echo "Attempting to kill process running port number $1 using BASH syntax"        
            taskkill /F /PID "$portNumber" 
          echo "Process on $1 killed."
      } || {
          echo "Process on $1 NOT killed."
      }
    done 
fi