#!/bin/bash
if [ "$1" ]
  then
    currentDirectory=$HOME/bashrc/aliases
    script=$currentDirectory/batch/restart-process.bat    
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
    cmd "/C $($currentDirectory/convert-path.sh $script) $1"
    $executablePathDosEscaped &
  fi
