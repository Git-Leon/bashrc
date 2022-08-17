#!/bin/bash
if [ "$1" ]
  then
    currentDirectory=$HOME/bashrc/aliases
    pycharm=$currentDirectory/pycharm.sh    

    mkdir $1
    cd $1

    mkdir -p src/main/
    mkdir -p src/test/

    touch src/main/main_application.py
    touch src/test/main_application_test.py

    echo "My Project Description!" > README.md
fi