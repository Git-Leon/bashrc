@ECHO OFF
taskkill /f /im %~1
taskkill /f /FI "WINDOWTITLE eq %~1"
START CMD /C %~1