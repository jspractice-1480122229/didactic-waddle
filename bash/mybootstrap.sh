#!/bin/bash
## bootstrap for new nodes with BASH
echo "My bootstrap begins..."
sudo apt update
sudo apt install -y wget git cmake tree colordiff net-tools aptitude
mv -fv "${HOME}"/.bashrc dotbashrc
wget https://raw.githubusercontent.com/jspractice-1480122229/didactic-waddle/master/bash/.bashrc
wget https://raw.githubusercontent.com/jspractice-1480122229/didactic-waddle/master/bash/.bash_aliases
wget https://raw.githubusercontent.com/jspractice-1480122229/didactic-waddle/master/bash/.bash_functions
curl -o "${HOME}"/.gitignore_global.txt https://raw.githubusercontent.com/padosoft/gitignore/master/gitignore_global.txt
#wget https://raw.githubusercontent.com/padosoft/gitignore/master/gitignore_global.txt -O "${HOME}"/.gitignore_global.txt
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt update && sudo apt upgrade -y && sudo apt -y autoremove --purge
git clone --depth=1 https://github.com/amix/vimrc.git "${HOME}"/.vim_runtime
sh "${HOME}"/.vim_runtime/install_awesome_vimrc.sh
echo "Setup Vundle for YouCompleteMe"
#Vundle is for YCM
git clone https://github.com/VundleVim/Vundle.vim.git "${HOME}"/.vim/bundle/Vundle.vim
echo "set nocompatible
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
Plugin 'ycm-core/YouCompleteMe'
call vundle#end()
filetype plugin indent on

set number
colorscheme slate
set t_Co=256
set encoding=utf-8

if has(\"gui_running\")
    set guifont=Source\ Code\ Pro\ 12
endif" >"${HOME}"/.vim_runtime/my_configs.vim
echo "My bootstrap is done.
--> DO NOT FORGET TO 'source ~/.bashrc' <--"
