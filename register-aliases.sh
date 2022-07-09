#!/bin/bash
ECHO Registering aliases...

alias cd='. ~/bashrc/aliases/change-directory.sh $1';
alias git-acp=~/bashrc/aliases/git-acp.sh $*
alias git-fall=~/bashrc/aliases/git-fetch-all.sh
alias git-ignore=~/bashrc/aliases/git-ignore.sh
alias git-reset=~/bashrc/aliases/git-reset.sh
alias gitbash='C:/Program\ Files/Git/git-bash.exe'