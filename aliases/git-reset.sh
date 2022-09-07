#!/bin/bash
git add .
git stash

if [ "$1" ]
  then
    git reset --hard HEAD~$1
  else  
    git reset --hard
    git fetch --all
    git pull --ff-only
    git branch
fi 