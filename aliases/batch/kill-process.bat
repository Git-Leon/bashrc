@ECHO OFF
GOTO:MAIN

:killProcess
    SETLOCAL ENABLEDELAYEDEXPANSION
        SET process=%~1
        
        taskkill /f /im %process%
        taskkill /f /FI "WINDOWTITLE eq %process%"
    ENDLOCAL
EXIT /B 0

:MAIN
SET firstArg=%~1
call:killProcess %firstArg%