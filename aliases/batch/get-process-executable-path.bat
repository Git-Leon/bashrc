@ECHO OFF                                                                              
Wmic process where (Name like 'notepad.exe') get commandline | sed -n 2p