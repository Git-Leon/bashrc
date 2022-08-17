#!/bin/bash
if [ "$1" ]
  then
    git add .
    git commit -m "$1"
  else
    git commit -m "stashing changes..."
fi
git stash pop