#!/bin/bash
restartScript=$HOME/bashrc/aliases/restart-process.sh
for process in notepad.exe discord.exe notepad++.exe firefox.exe
do
   echo restarting $process...
   $restartScript $process $1
   echo $process restarted!
done