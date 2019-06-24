git submodule update --init

ln -s $(dirname $(realpath $0))/.zshrc $HOME/.zshrc
ln -s $(dirname $(realpath $0))/.virtualenv.zsh $HOME/.virtualenv.zsh
