cd $HOME/bashrc
cp $HOME/.bashrc $HOME/.bashrc_backup
chmod -R u+x .
echo '. $HOME/bashrc/register-aliases.sh;' > ~/.bashrc
echo 'builtin cd $HOME' >> ~/.bashrc
source ~/.bashrc