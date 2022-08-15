#!/bin/bash
git branch -r | grep -v '\->' |\
while read remote; do
    git branch --track "${remote#origin/}" "$remote";
    git pull
done
git fetch --all
git pull --all
git branch
