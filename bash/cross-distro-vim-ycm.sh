#!/bin/bash
# cross-distro-vim-ycm.sh
# Sourced by fish wrappers: install_vim / install_ycm
# Supports: apt (Ubuntu/Debian), dnf5/dnf (Fedora/RHEL), pacman (Arch), zypper (openSUSE)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
log_info()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

_detect_pkg_manager() {
    if command -v dnf5  &>/dev/null; then echo "dnf5";
    elif command -v dnf &>/dev/null; then echo "dnf";
    elif command -v apt  &>/dev/null; then echo "apt";
    elif command -v pacman &>/dev/null; then echo "pacman";
    elif command -v zypper &>/dev/null; then echo "zypper";
    else log_error "No supported package manager found."; return 1; fi
}

_install_pkgs() {
    local pm="$1"; shift
    case "$pm" in
        apt)    sudo apt update && sudo apt install -y "$@" ;;
        dnf5)   sudo dnf5 install -y "$@" ;;
        dnf)    sudo dnf  install -y "$@" ;;
        pacman) sudo pacman -S --needed --noconfirm "$@" ;;
        zypper) sudo zypper install -y "$@" ;;
    esac
}

_remove_pkgs() {
    local pm="$1"; shift
    case "$pm" in
        apt)    sudo apt purge -y "$@" && sudo apt autoremove -y ;;
        dnf5)   sudo dnf5 remove -y "$@" ;;
        dnf)    sudo dnf  remove -y "$@" ;;
        pacman) sudo pacman -Rns --noconfirm "$@" 2>/dev/null || true ;;
        zypper) sudo zypper remove -y "$@" ;;
    esac
}

# ------------------------------------------------------------
# install_vim — compile Vim from source with full interpreter
#               and GTK GUI support, then set as system default
# ------------------------------------------------------------
install_vim() {
    local pm
    pm=$(_detect_pkg_manager) || return 1
    log_info "Package manager: $pm"

    log_info "Installing Vim build dependencies..."
    case "$pm" in
        apt)
            _install_pkgs apt \
                build-essential cmake git \
                libncurses5-dev libgtk2.0-dev libatk1.0-dev libcairo2-dev \
                libx11-dev libxpm-dev libxt-dev \
                python3-dev ruby-dev \
                lua5.4 liblua5.4-dev \
                libperl-dev
            ;;
        dnf5|dnf)
            _install_pkgs "$pm" \
                gcc gcc-c++ make cmake git \
                ncurses-devel gtk2-devel atk-devel cairo-devel \
                libX11-devel libXpm-devel libXt-devel \
                python3-devel ruby-devel \
                lua-devel \
                perl-devel perl-ExtUtils-Embed
            ;;
        pacman)
            _install_pkgs pacman \
                base-devel cmake git \
                gtk2 atk cairo libx11 libxpm libxt \
                python ruby \
                lua \
                perl
            ;;
        zypper)
            _install_pkgs zypper \
                gcc gcc-c++ make cmake git \
                ncurses-devel gtk2-devel atk-devel cairo-devel \
                libX11-devel libXpm-devel libXt-devel \
                python3-devel ruby-devel \
                lua54-devel \
                perl-devel
            ;;
    esac

    log_info "Removing distro-packaged Vim..."
    case "$pm" in
        apt)    _remove_pkgs apt    vim vim-runtime gvim vim-tiny vim-common vim-gui-common vim-nox ;;
        dnf5|dnf) _remove_pkgs "$pm" vim-enhanced vim-X11 vim-common vim-filesystem ;;
        pacman) _remove_pkgs pacman vim gvim ;;
        zypper) _remove_pkgs zypper vim gvim ;;
    esac

    local VIM_SRC="${HOME}/src/vim"
    if [[ -d "$VIM_SRC" ]]; then
        log_info "Updating existing Vim source..."
        cd "$VIM_SRC"
        git pull --rebase
    else
        log_info "Cloning Vim source..."
        mkdir -p "${HOME}/src"
        git clone https://github.com/vim/vim.git "$VIM_SRC"
        cd "$VIM_SRC"
    fi

    make clean distclean 2>/dev/null || true

    local VIM_MAJOR VIM_MINOR VIMRUNTIMEDIR
    VIM_MAJOR=$(awk '/VIM_VERSION_MAJOR[[:space:]]/ {print $3; exit}' src/version.h)
    VIM_MINOR=$(awk  '/VIM_VERSION_MINOR[[:space:]]/ {print $3; exit}' src/version.h)
    VIMRUNTIMEDIR="/usr/local/share/vim/vim${VIM_MAJOR}${VIM_MINOR}"
    log_info "Building Vim ${VIM_MAJOR}.${VIM_MINOR} — runtime: $VIMRUNTIMEDIR"

    ./configure \
        --with-features=huge \
        --enable-multibyte \
        --enable-rubyinterp=yes \
        --with-x \
        --enable-perlinterp=yes \
        --enable-luainterp=yes \
        --enable-gui=gtk2 \
        --enable-cscope \
        --prefix=/usr/local \
        --enable-python3interp=yes \
        --with-python3-config-dir="$(python3-config --configdir)" \
        --with-python3-command=python3

    make VIMRUNTIMEDIR="$VIMRUNTIMEDIR"
    sudo make install

    log_info "Setting Vim as system default..."
    case "$pm" in
        apt|zypper)
            sudo update-alternatives --install /usr/bin/editor editor /usr/local/bin/vim 1
            sudo update-alternatives --set    editor /usr/local/bin/vim
            sudo update-alternatives --install /usr/bin/vi vi /usr/local/bin/vim 1
            sudo update-alternatives --set    vi /usr/local/bin/vim
            ;;
        dnf5|dnf)
            sudo alternatives --install /usr/bin/vi  vi  /usr/local/bin/vim 1
            sudo alternatives --set     vi  /usr/local/bin/vim
            sudo alternatives --install /usr/bin/vim vim /usr/local/bin/vim 1
            sudo alternatives --set     vim /usr/local/bin/vim
            ;;
        pacman)
            sudo ln -sf /usr/local/bin/vim /usr/bin/vim  2>/dev/null || true
            sudo ln -sf /usr/local/bin/vim /usr/bin/vi   2>/dev/null || true
            sudo ln -sf /usr/local/bin/gvim /usr/bin/gvim 2>/dev/null || true
            ;;
    esac

    log_info "Vim $(vim --version | head -1) installed successfully."
}

# ------------------------------------------------------------
# install_ycm — install/update YouCompleteMe via Vundle and
#               compile it with all available completers
# ------------------------------------------------------------
install_ycm() {
    local pm
    pm=$(_detect_pkg_manager) || return 1
    log_info "Package manager: $pm"

    log_info "Installing YCM build dependencies..."

    # Detect latest available JDK package name
    local jdk_pkg
    case "$pm" in
        apt)
            jdk_pkg=$(apt-cache search '^openjdk-[0-9]+-jdk$' 2>/dev/null \
                | grep -oE 'openjdk-[0-9]+-jdk' | sort -V | tail -1)
            jdk_pkg="${jdk_pkg:-openjdk-17-jdk}"
            _install_pkgs apt cmake python3-dev mono-complete "$jdk_pkg" shellcheck golang
            ;;
        dnf5|dnf)
            jdk_pkg=$(${pm} list available 2>/dev/null \
                | grep -oE 'java-[0-9]+-openjdk-devel' | sort -V | tail -1)
            jdk_pkg="${jdk_pkg:-java-17-openjdk-devel}"
            _install_pkgs "$pm" cmake python3-devel mono-complete "$jdk_pkg" ShellCheck golang
            ;;
        pacman)
            jdk_pkg=$(pacman -Ss jdk-openjdk 2>/dev/null \
                | grep -oE 'extra/jdk[0-9]+-openjdk' | sort -V | tail -1 | cut -d/ -f2)
            jdk_pkg="${jdk_pkg:-jdk-openjdk}"
            _install_pkgs pacman cmake python mono "$jdk_pkg" shellcheck go
            ;;
        zypper)
            jdk_pkg=$(zypper search -t package 'java-*-openjdk-devel' 2>/dev/null \
                | grep -oE 'java-[0-9]+-openjdk-devel' | sort -V | tail -1)
            jdk_pkg="${jdk_pkg:-java-17-openjdk-devel}"
            _install_pkgs zypper cmake python3-devel mono-complete "$jdk_pkg" ShellCheck go
            ;;
    esac

    log_info "Setting up Vundle..."
    local VUNDLE_DIR="${HOME}/.vim/bundle/Vundle.vim"
    if [[ -d "$VUNDLE_DIR" ]]; then
        cd "$VUNDLE_DIR" && git pull --rebase && cd -
    else
        mkdir -p "${HOME}/.vim/bundle"
        git clone https://github.com/VundleVim/Vundle.vim.git "$VUNDLE_DIR"
    fi

    # Write a minimal vimrc if none exists, so Vundle can run headlessly
    local VIMRC="${HOME}/.vimrc"
    if [[ ! -f "$VIMRC" ]]; then
        log_warn "No ~/.vimrc found — writing a minimal one."
        cat > "$VIMRC" <<'VIMRC'
set nocompatible
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
Plugin 'ycm-core/YouCompleteMe'
call vundle#end()
filetype plugin indent on
VIMRC
    fi

    local YCM_DIR="${HOME}/.vim/bundle/YouCompleteMe"
    if [[ -d "$YCM_DIR" ]]; then
        log_info "Updating YouCompleteMe via Vundle..."
        vim +PluginUpdate +qall
    else
        log_info "Installing YouCompleteMe via Vundle..."
        vim +PluginInstall +qall
    fi

    if [[ ! -d "$YCM_DIR" ]]; then
        log_error "YouCompleteMe directory not found after Vundle install — aborting."
        return 1
    fi

    log_info "Compiling YouCompleteMe (--all completers)..."
    cd "$YCM_DIR"
    git submodule update --init --recursive
    python3 install.py --all

    log_info "YouCompleteMe installed successfully."
}
