#!/bin/bash
## bootstrap for new nodes with BASH
echo "My bootstrap begins..."

# Update and install essential packages
sudo apt update && sudo apt install -y wget curl git cmake tree colordiff net-tools yt-dlp ffmpeg lame ghostscript perl webp fortune gawk sed uuid-runtime imagemagick jpegoptim openssl tar unzip unrar-free p7zip-full make gcc cmark ghostwriter screenfetch

# Backup existing .bashrc
mv -fv "${HOME}/.bashrc" "${HOME}/dotbashrc"

# Download new Bash configurations
wget https://raw.githubusercontent.com/jspractice-1480122229/didactic-waddle/master/bash/.bashrc -O "${HOME}/.bashrc"
wget https://raw.githubusercontent.com/jspractice-1480122229/didactic-waddle/master/bash/.bash_aliases -O "${HOME}/.bash_aliases"
wget https://raw.githubusercontent.com/jspractice-1480122229/didactic-waddle/master/bash/.bash_functions -O "${HOME}/.bash_functions"
wget https://raw.githubusercontent.com/jspractice-1480122229/didactic-waddle/master/bash/.gitconfig -O "${HOME}/.gitconfig"
wget https://raw.githubusercontent.com/jspractice-1480122229/didactic-waddle/master/bash/.git-credentials -O "${HOME}/.git-credentials"
curl -o "${HOME}/.gitignore_global.txt" https://raw.githubusercontent.com/padosoft/gitignore/master/gitignore_global.txt

# Install fnm (Fast Node Manager) and Node.js
# Use fnm from https://github.com/Schniz/fnm
curl -fsSL https://fnm.vercel.app/install | bash

# Update and clean up packages
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y --purge

# Install Vim and the awesome vimrc
git clone --depth=1 https://github.com/amix/vimrc.git "${HOME}/.vim_runtime"
sh "${HOME}/.vim_runtime/install_awesome_vimrc.sh"

echo "Setup Vundle for YouCompleteMe"
# Setup Vundle for YouCompleteMe
git clone https://github.com/VundleVim/Vundle.vim.git "${HOME}/.vim/bundle/Vundle.vim"

# Configure Vim plugins and settings
cat <<EOL > "${HOME}/.vim_runtime/my_configs.vim"
set nocompatible
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

if has("gui_running")
    set guifont=Ubuntu\ Mono\ 15
endif
EOL

# Notify the user to source .bashrc
echo "My bootstrap is done."
echo "--> DO NOT FORGET TO 'source ~/.bashrc' <--"
