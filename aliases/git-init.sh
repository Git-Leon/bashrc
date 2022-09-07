#!/bin/bash
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
$SCRIPTPATH/get-gitignore.sh

repoName=$1
commitMessage="${@:2}"
echo $commitMessage

git init
git add .
git commit -m "$commitMessage"
gh repo create $repoName --public --source=. --remote=upstream --push