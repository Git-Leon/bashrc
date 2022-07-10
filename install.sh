cp ~/.bashrc ~/.bashrc_backup
echo '. ~/bashrc/register-aliases.sh;' > ~/.bashrc
source ~/.bashrc
chmod -R u+x .