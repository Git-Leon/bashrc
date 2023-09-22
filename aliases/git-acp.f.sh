#!/bin/bash
echo git config --global --add --bool push.autoSetupRemote true
git config --global --add --bool push.autoSetupRemote true

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
$SCRIPT_DIR/git-ac.sh $*

echo git push -f
git push -f

echo git config --global --add --bool push.autoSetupRemote false
git config --global --add --bool push.autoSetupRemote false