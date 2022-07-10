#!/bin/bash
ECHO Registering aliases...
aliases=~/bashrc/aliases

alias cd='. $aliases/change-directory.sh $1';
alias git-acp=$aliases/git-acp.sh $*
alias git-fall=$aliases/git-fetch-all.sh
alias git-ignore=$aliases/git-ignore.sh
alias git-reset=$aliases/git-reset.sh
alias create-project.python=$aliases/create-python-project.sh $1
alias mvn.version=$aliases/mvn.project-version.sh
alias mvn.package=$aliases/mvn.package.sh
alias pc.deploy=$aliases/package_cloud.deploy.sh
alias kill-port=$aliases/kill-port.sh $1
alias pycharm='$aliases/pycharm.sh' $1
alias gitbash='$aliases/gitbash.sh & exit'

alias