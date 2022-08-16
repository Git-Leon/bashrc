cp ~/.bashrc ~/.bashrc_backup
chmod -R u+x ~/bashrc
echo '. ~/bashrc/register-aliases.sh;' > ~/.bashrc
source ~/.bashrc