#!/bin/bash
if [ "$1" ]
  then
    git reset --hard HEAD~$1
  else  
    git add .
    git stash
    git reset --hard
    git fetch --all
    git pull --ff-only
    git branch
fi 