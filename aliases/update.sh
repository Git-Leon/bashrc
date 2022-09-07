#!/bin/bash
echo "Test"
git -C ~/bashrc fetch --all
git -C ~/bashrc pull --all
~/bashrc/aliases/git-reset.sh
~/bashrc/install.sh