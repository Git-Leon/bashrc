cd ~/bashrc
cp ~/.bashrc ~/.bashrc_backup
chmod -R u+x .
echo '. ~/bashrc/register-aliases.sh;' > ~/.bashrc
echo 'builtin cd ~' >> ~/.bashrc
source ~/.bashrc