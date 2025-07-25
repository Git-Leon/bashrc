#!/bin/bash
if [ "$1" ]; then
  processName="${1%.exe}"
  echo "Attempting to kill $processName..."

  powershell.exe -Command "Get-Process | Where-Object { \$_.ProcessName -like '*$processName*' } | Stop-Process -Force"
fi
