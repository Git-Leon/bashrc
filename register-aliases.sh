#!/bin/bash
ECHO Registering aliases...
aliases=~/bashrc/aliases

scriptWorkingDirectory() {
    echo YER
    SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
    ECHO $SWD
}

alias cd='. $aliases/change-directory.sh $1';
alias pycharm='C:/Program\ Files\ \(x86\)/JetBrains/PyCharm\ Community\ Edition\ 2022.1.2/bin/pycharm64.exe' $1
#alias pycharm='$aliases/pycharm.sh' $1
alias gitbash='$aliases/gitbash.sh & exit'
alias idea='$aliases/idea.sh' $1
alias cd-temp='. $aliases/change-directory.sh ~/dev/.tmp'
alias git-acp='$aliases/git-acp.sh' $*
alias git-fall='$aliases/git-fetch-all.sh'
alias git-ignore='$aliases/git-ignore.sh'
alias git-reset='$aliases/git-reset.sh'
alias create-project.python='$aliases/create-project.python.sh' $1
alias mvn.version='$aliases/mvn.project-version.sh'
alias mvn.package='$aliases/mvn.package.sh'
alias pc.deploy='$aliases/package_cloud.deploy.sh'
alias get-process='$aliases/get-process.sh'
alias kill-port='$aliases/kill-port.sh' $1
alias kill-process='$aliases/kill-process.sh' $1
alias restart-process='$aliases/restart-process.sh'
alias convert-path='$aliases/convert-path.sh' $1
alias find-replace='$aliases/find-replace.sh' $1 $2 $3
alias get-gitignore='$aliases/generate-gitignore.sh'
alias restart-discord='$aliases/restart-discord.sh'

alias