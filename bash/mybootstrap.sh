#!/bin/bash
## bootstrap for new nodes with BASH
echo "My bootstrap begins..."
sudo apt update && sudo apt upgrade -y && sudo apt autoremove
sudo apt install -y curl wget git
mv -fv "${HOME}"/.bashrc dotbashrc
wget https://raw.githubusercontent.com/jspractice-1480122229/didactic-waddle/master/bash/.bashrc
wget https://raw.githubusercontent.com/jspractice-1480122229/didactic-waddle/master/bash/.bash_aliases
wget https://raw.githubusercontent.com/jspractice-1480122229/didactic-waddle/master/bash/.bash_functions
source "${HOME}"/.bashrc
git clone --depth=1 https://github.com/amix/vimrc.git "${HOME}"/.vim_runtime
sh "${HOME}"/.vim_runtime/install_awesome_vimrc.sh
cd "${HOME}"/.vim_runtime
echo "Setup Vundle for YouCompleteMe"
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim #Vundle is for YCM
echo 'set nocompatible
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
Plugin 'ycm-core/YouCompleteMe'
call vundle#end()
filetype plugin indent on

set number
colorscheme elflord
set t_Co=256

if has("gui_running")
    set guifont=DejaVu\ Sans\ Mono\ 12
endif' > "${HOME}"/.vim_runtime/my_configs.vim
echo "My bootstrap is done"