#!/bin/bash
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
repoName=git@github.com:the-quick-demonstrator/$1
commitMessage="${@:2}"

$SCRIPTPATH/git-init.sh $repoName $commitMessage