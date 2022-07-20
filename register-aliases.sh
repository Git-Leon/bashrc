#!/bin/bash
ECHO Registering aliases...
aliases=~/bashrc/aliases

alias cd='. $aliases/change-directory.sh $1'
alias cd-temp='. $aliases/change-directory.sh ~/dev/.tmp'
alias convert-path='$aliases/convert-path.sh'
alias create-project.python='$aliases/create-project.python.sh'
alias find-replace='$aliases/find-replace.sh'
alias generate-gitignore='$aliases/get-gitignore.sh'
alias get-gitignore='$aliases/generate-gitignore.sh'
alias get-process='$aliases/get-process.sh'
alias git-acp='~/bashrc/aliases/git-acp.sh'
alias git-fall='$aliases/git-fetch-all.sh'
alias git-ignore='$aliases/git-ignore.sh'
alias git-fork-sync='$aliases/git-fork-sync.sh'
alias git-reset='$aliases/git-reset.sh'
alias gitbash='$aliases/gitbash.sh & exit'
alias idea='$aliases/idea.sh'
alias kill-bloat='$aliases/kill-bloat.sh'
alias kill-port='$aliases/kill-port.sh'
alias kill-process='$aliases/kill-process.sh'
alias ll='ls -la --color=auto'
alias ls='ls -F --color=auto --show-control-chars'
alias mvn.package='$aliases/mvn.package.sh'
alias mvn.version='$aliases/mvn.project-version.sh'
alias node='winpty node.exe'
alias pc.deploy='$aliases/package_cloud.deploy.sh'
alias php='winpty php.exe'
alias pycharm='C:/Program\ Files\ \(x86\)/JetBrains/PyCharm\ Community\ Edition\ 2022.1.2/bin/pycharm64.exe'
alias restart-discord='$aliases/restart-discord.sh'
alias restart-process='$aliases/restart-process.sh'

alias