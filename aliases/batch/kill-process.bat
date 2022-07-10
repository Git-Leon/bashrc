@ECHO OFF
taskkill /f /im %~1
taskkill /f /FI "WINDOWTITLE eq %~1"