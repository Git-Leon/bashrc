#!/bin/bash
git stash
git reset --hard
git fetch --all
git pull --all
git branch