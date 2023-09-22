#!/bin/bash
git config --global --add --bool push.autoSetupRemote true

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
$SCRIPT_DIR/git-ac.sh $*

echo git push -f
git push -f

git config --global --add --bool push.autoSetupRemote false