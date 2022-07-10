#!/bin/bash

{ #try 
    kill -9 $(lsof -t -i:$1) 2>/dev/null
} || { # catch
    ECHO hello world
    batFile="$PWD"/kill-port.bat
    ECHO FOR \/F \"tokens=4 delims= \" \%\%P IN \(\'netstat -a -n -o \^\| findstr :$1\'\) DO TaskKill.exe /PID \%\%P > $batFile
    rm $batFile 
}