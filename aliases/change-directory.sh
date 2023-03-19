#!/bin/bash
builtin cd $1
pwd
ls -a
if [ -f .git ]; then
    git branch
    git status
fi