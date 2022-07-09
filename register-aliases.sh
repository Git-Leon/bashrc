#!/bin/bash
ECHO Registering aliases...

alias cd='. ~/bashrc/aliases/change-directory.sh $1';
alias git-acp=~/bashrc/aliases/git-acp.sh $*
alias git-fall=~/bashrc/aliases/git-fetch-all.sh
alias git-ignore=~/bashrc/aliases/git-ignore.sh
alias git-reset=~/bashrc/aliases/git-reset.sh
alias create-project.python=~/bashrc/aliases/create-python-project.sh $1
alias mvn.version=~/bashrc/aliases/mvn.project-version.sh
alias mvn.package=~/bashrc/aliases/mvn.package.sh
alias package_cloud.deploy=~/bashrc/aliases/package_cloud.deploy.sh
alias pycharm='C:/Program\ Files\ \(x86\)/JetBrains/PyCharm\ Community\ Edition\ 2022.1.2/bin/pycharm64.exe' $1
alias gitbash='C:/Program\ Files/Git/git-bash.exe'

alias