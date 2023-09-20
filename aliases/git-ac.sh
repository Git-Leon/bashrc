#!/bin/bash
git config core.filemode true
echo git branch
git branch

echo git status
git status

echo git add .
git add .

echo git commit -m \"$*\"
git commit -m "$*"
