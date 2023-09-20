#!/bin/bash
declare -A colors

colors['off']='\033[0m'
colors['black']='\033[30m'
colors['red']='\033[31m'
colors['green']='\033[32m'
colors['yellow']='\033[33m'
colors['blue']='\033[34m'
colors['purple']='\033[35m'
colors['cyan']='\033[36m'
colors['white']='\033[37m'

colors['light-black']='\033[1;30m'
colors['light-red']='\033[1;31m'
colors['light-green']='\033[1;32m'
colors['light-yellow']='\033[1;33m'
colors['light-blue']='\033[1;34m'
colors['light-purple']='\033[1;35m'
colors['light-cyan']='\033[1;36m'
colors['light-white']='\033[1;37m'

defaultColor=${colors['off']}
color=${colors[$1{1,,}]}
contentToEcho=("${@:2}")
echo -e "$color$contentToEcho$defaultColor"