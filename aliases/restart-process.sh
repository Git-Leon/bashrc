#!/bin/bash
if [ "$1" ]
  then
    currentDirectory=$HOME/bashrc/aliases
    restartScript=$currentDirectory/batch/restart-process.bat    
    killScript=$($currentDirectory/kill-process.sh $1)
    executablePathUnix="$($currentDirectory/batch/get-process-executable-path.bat $1)"
    executablePathDos=$(echo "$executablePathUnix" | tr -d '"')
    executablePathDos="$($currentDirectory/find-replace.sh \\ \\\\ $executablePathDos)"
    executablePathDos="$($currentDirectory/find-replace.sh \\\& \\\\\& $executablePathDos)"
    executablePathDos="$($currentDirectory/find-replace.sh \\/ \\\\/ $executablePathDos)"
    executablePathDos=$(printf "%q" $executablePathDos)
    executablePathDos="$($currentDirectory/find-replace.sh \  - $executablePathDos)"
    executablePathDosEscaped="$($currentDirectory/find-replace.sh -  \\  $executablePathDos)"

    ECHO $executablePathUnix
    ECHO $executablePathDos
    ECHO $executablePathDosEscaped
    cmd "/C $($currentDirectory/convert-path.sh $restartScript) $1"
    $killScript
    $executablePathDosEscaped &
  fi
