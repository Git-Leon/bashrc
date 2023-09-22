#!/bin/bash
git config core.filemode true

echo git config --global --add --bool push.autoSetupRemote true
git config --global --add --bool push.autoSetupRemote true

echo git branch
git branch

echo git status
git status

echo git add .
git add .

echo git commit --allow-empty-message -m \"$*\"
git commit --allow-empty-message -m "$*"

echo git push -f
git push -f

echo git config --global --add --bool push.autoSetupRemote false
git config --global --add --bool push.autoSetupRemote false