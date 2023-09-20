#!/bin/bash
declare -A colorMap

colorMap['off']='\033[0m'
colorMap['black']='\033[30m'
colorMap['red']='\033[31m'
colorMap['green']='\033[32m'
colorMap['yellow']='\033[33m'
colorMap['blue']='\033[34m'
colorMap['purple']='\033[35m'
colorMap['cyan']='\033[36m'
colorMap['white']='\033[37m'

colorMap['light-black']='\033[1;30m'
colorMap['light-red']='\033[1;31m'
colorMap['light-green']='\033[1;32m'
colorMap['light-yellow']='\033[1;33m'
colorMap['light-blue']='\033[1;34m'
colorMap['light-purple']='\033[1;35m'
colorMap['light-cyan']='\033[1;36m'
colorMap['light-white']='\033[1;37m'

defaultColor=${colorMap['off']}
selectedColor=${colorMap[$1{1,,}]}
contentToEcho=("${@:2}")
echo -e "$selectedColor$contentToEcho$defaultColor"