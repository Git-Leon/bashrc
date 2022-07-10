cp ~/.bashrc ~/.bashrc_backup
chmod -R u+x .
echo '. ~/bashrc/register-aliases.sh;' > ~/.bashrc
source ~/.bashrc