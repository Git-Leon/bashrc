#!/bin/bash
cd ~/bashrc
git stash
git reset --hard
git fetch --all
git pull --ff-only
git branch
./install.sh