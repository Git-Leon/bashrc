@ECHO OFF                                                                              
Wmic process where (Name like '%~1') get commandline | sed -n 2p