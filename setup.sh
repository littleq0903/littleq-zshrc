git submodule update --init

sudo apt install -y zsh-syntax-highlighting

ln -s $(dirname $(realpath $0))/.zshrc $HOME/.zshrc
ln -s $(dirname $(realpath $0))/.virtualenv.zsh $HOME/.virtualenv.zsh
