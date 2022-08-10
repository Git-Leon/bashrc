killScript=$HOME/bashrc/aliases/kill-process.sh
$killScript discord.exe
echo '
SET discordPath=%appData%/../Local/Discord/Update.exe 
start "" %discordPath% --processStart discord.exe
' > .tmp.bat
cat .tmp.bat
cmd "/C .tmp.bat"
rm .tmp.bat