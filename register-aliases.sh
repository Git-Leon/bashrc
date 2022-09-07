#!/bin/bash
ECHO Registering aliases...
aliases=~/bashrc/aliases

alias bashrc-update='$aliases/bashrc-update.sh'
alias cd='. $aliases/change-directory.sh $1'
alias cd-temp='. $aliases/change-directory.sh ~/dev/.tmp'
alias convert-path='$aliases/convert-path.sh'
alias create-project.python='$aliases/create-project.python.sh'
alias create-project.maven='$aliases/create-project.maven.sh'
alias deldir='$aliases/deldir.sh $1'
alias find-replace='$aliases/find-replace.sh'
alias get-gitignore='$aliases/get-gitignore.sh'
alias get-process='$aliases/get-process.sh'
alias get-path='$aliases/get-path.sh'
alias git-delete='$aliases/git-delete.sh $1'
alias git-acp='~/bashrc/aliases/git-acp.sh'
alias git-fall='$aliases/git-fetch-all.sh'
alias git-ignore='$aliases/git-ignore.sh'
alias git-fork-sync='$aliases/git-fork-sync.sh'
alias git-migrate='$aliases/git-migrate.sh'
alias git-reset='$aliases/git-reset.sh'
alias git-stash-pop='$aliases/git-stash-pop.sh'
alias gitbash='$aliases/gitbash.sh & exit'
alias idea='$aliases/idea.sh'
alias kill-bloat='$aliases/kill-bloat.sh'
alias kill-port='$aliases/kill-port.sh'
alias kill-process='$aliases/kill-process.sh'
alias ll='ls -la --color=auto'
alias ls='$aliases/ls.sh'
alias mvn.package='$aliases/mvn.package.sh'
alias mvn.version='$aliases/mvn.project-version.sh'
alias node='winpty node.exe'
alias npp='notepad++ $1'
alias pc.deploy='$aliases/package_cloud.deploy.sh'
alias php='winpty php.exe'
alias pycharm='C:/Program\ Files\ \(x86\)/JetBrains/PyCharm\ Community\ Edition\ 2022.1.2/bin/pycharm64.exe'
alias unjar='$aliases/unjar-to-java.sh $1'
alias restart-discord='$aliases/restart-discord.sh'
alias restart-process='$aliases/restart-process.sh'

alias