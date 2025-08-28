#!/bin/bash
# ==============================================================================
# Cross-distro bootstrap script v3.7 (Node.js Purged, JDK Dynamic)
# Installs core environment; sources existing repo config files.
# ==============================================================================

set -euo pipefail

# --- Logging functions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

detect_distro() {
    local pkg_manager=""
    if command -v apt &>/dev/null; then pkg_manager="apt";
    elif command -v dnf &>/dev/null; then pkg_manager="dnf";
    elif command -v pacman &>/dev/null; then pkg_manager="pacman";
    elif command -v zypper &>/dev/null; then pkg_manager="zypper";
    else log_error "Unsupported package manager." && exit 1; fi
    echo "$pkg_manager"
}

detect_latest_jdk() {
    local pkg_manager="$1"
    case "$pkg_manager" in
        "apt") apt-cache search "^openjdk-[0-9]+-jdk$" 2>/dev/null | grep -oE 'openjdk-[0-9]+-jdk' | sort -V | tail -1 || echo "openjdk-11-jdk" ;;
        "dnf") dnf list available 2>/dev/null | grep -oE 'java-[0-9]+-openjdk-devel' | sort -V | tail -1 || echo "java-11-openjdk-devel" ;;
        "pacman") pacman -Ss 2>/dev/null | grep -oE 'jdk[0-9]+-openjdk' | sort -V | tail -1 || echo "jdk11-openjdk" ;;
        "zypper") zypper search 2>/dev/null | grep -oE 'java-[0-9]+-openjdk-devel' | sort -V | tail -1 || echo "java-11-openjdk-devel" ;;
        *) echo "openjdk-11-jdk" ;;
    esac
}

setup_additional_repos() {
    local pkg_manager="$1"
    
    case "$pkg_manager" in
        "apt")
            log_info "Setting up additional APT repositories for VSCodium and MS Edge..."
            # Test internet connectivity first
            if ! curl -s --connect-timeout 5 https://packages.microsoft.com >/dev/null; then
                log_error "Cannot reach package repositories. Check internet connection."
                return 1
            fi
            
            sudo apt update || { log_error "Failed to update package lists"; return 1; }
            sudo apt install -y curl gpg apt-transport-https || { log_error "Failed to install repo dependencies"; return 1; }
            
            if ! curl -fsSL https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | sudo gpg --dearmor -o /usr/share/keyrings/vscodium-archive-keyring.gpg; then
                log_error "Failed to add VSCodium repository key"
                return 1
            fi
            echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' | sudo tee /etc/apt/sources.list.d/vscodium.list
            
            if ! curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-edge-keyring.gpg; then
                log_error "Failed to add Microsoft Edge repository key"
                return 1
            fi
            echo 'deb [ arch=amd64 signed-by=/usr/share/keyrings/microsoft-edge-keyring.gpg ] https://packages.microsoft.com/repos/edge stable main' | sudo tee /etc/apt/sources.list.d/microsoft-edge.list
            sudo apt update
            ;;
        "dnf")
            log_info "Setting up additional DNF repositories for VSCodium and MS Edge..."
            sudo rpm --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg
            printf "[gitlab.com_paulcarroty_vscodium_repo]\nname=download.vscodium.com\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg\n" | sudo tee /etc/yum.repos.d/vscodium.repo
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            printf "[microsoft-edge]\nname=Microsoft Edge\nbaseurl=https://packages.microsoft.com/yumrepos/edge/\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc\n" | sudo tee /etc/yum.repos.d/microsoft-edge.repo
            ;;
    esac
}

install_aur_helper() {
    if command -v paru &>/dev/null || command -v yay &>/dev/null; then return; fi
    log_info "Installing AUR helper (paru)..."
    sudo pacman -S --needed --noconfirm base-devel git
    local temp_dir; temp_dir=$(mktemp -d)
    trap 'log_info "Cleaning up temp directory..."; rm -rf "$temp_dir"' EXIT
    cd "$temp_dir"
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm
    cd "$HOME"
}

main() {
    log_info "Bootstrap v3.7 (Node.js Purged, JDK Dynamic) starting..."
    local pkg_manager
    pkg_manager=$(detect_distro)
    log_info "Detected package manager: $pkg_manager"
    
    # Detect latest JDK globally
    local jdk_package
    jdk_package=$(detect_latest_jdk "$pkg_manager")
    log_info "Latest JDK detected: $jdk_package"

    setup_additional_repos "$pkg_manager"

    local core_packages=("wget" "curl" "git" "cmake" "tree" "net-tools" "perl" "gawk" "sed" "openssl" "tar" "unzip" "make" "gcc" "fish" "build-essential")
    local media_packages=()
    local dev_packages=()
    local util_packages=()
    local shell_packages=()
    local aur_packages=()
    local python_build_deps=()

    case "$pkg_manager" in
        "apt")
            media_packages=("yt-dlp" "ffmpeg" "lame" "ghostscript" "webp" "imagemagick" "jpegoptim" "cowsay" "libimage-exiftool-perl")
            dev_packages=("python3" "python3-pip" "golang" "codium" "microsoft-edge-stable" "$jdk_package")
            shell_packages=("fzf" "podman" "podman-compose")
            util_packages=("colordiff" "fortune-mod" "uuid-runtime" "unrar" "p7zip-full")
            python_build_deps=("libssl-dev" "libncurses-dev" "libsqlite3-dev" "libreadline-dev" "tk-dev" "libgdbm-dev" "libdb-dev" "libbz2-dev" "libexpat1-dev" "liblzma-dev" "zlib1g-dev" "libffi-dev")
            ;;
        "dnf")
            media_packages=("yt-dlp" "ffmpeg" "lame" "ghostscript" "libwebp-tools" "ImageMagick" "jpegoptim" "cowsay" "perl-Image-ExifTool")
            dev_packages=("python3" "python3-pip" "golang" "codium" "microsoft-edge-stable" "$jdk_package")
            shell_packages=("fzf" "podman" "podman-compose" "starship")
            util_packages=("colordiff" "fortune-mod" "util-linux" "unrar" "p7zip")
            python_build_deps=("openssl-devel" "ncurses-devel" "sqlite-devel" "readline-devel" "tk-devel" "gdbm-devel" "libdb-devel" "bzip2-devel" "expat-devel" "xz-devel" "zlib-devel" "libffi-devel")
            ;;
        "pacman")
            media_packages=("yt-dlp" "ffmpeg" "lame" "ghostscript" "libwebp" "imagemagick" "jpegoptim" "cowsay" "perl-image-exiftool")
            dev_packages=("python" "python-pip" "go" "pyenv" "$jdk_package")
            shell_packages=("fzf" "podman" "podman-compose" "starship" "zoxide" "eza")
            util_packages=("colordiff" "fortune-mod")
            python_build_deps=("openssl" "ncurses" "sqlite" "readline" "tk" "gdbm" "db" "bzip2" "expat" "xz" "zlib" "libffi")
            aur_packages=("microsoft-edge-stable" "vscodium")
            ;;
        "zypper")
            media_packages=("yt-dlp" "ffmpeg" "lame" "ghostscript" "libwebp-tools" "ImageMagick" "jpegoptim" "cowsay" "exiftool")
            dev_packages=("python3" "python3-pip" "go" "$jdk_package")
            shell_packages=("fzf" "podman" "podman-compose")
            util_packages=("colordiff" "fortune" "unrar" "p7zip")
            python_build_deps=("openssl-devel" "ncurses-devel" "sqlite3-devel" "readline-devel" "tk-devel" "gdbm-devel" "libdb-4_8-devel" "libbz2-devel" "libexpat-devel" "liblzma-devel" "zlib-devel" "libffi-devel")
            ;;
    esac

    local all_packages=("${core_packages[@]}" "${media_packages[@]}" "${dev_packages[@]}" "${util_packages[@]}" "${shell_packages[@]}" "${python_build_deps[@]}")
    log_info "Installing main packages (including $jdk_package)..."
    case "$pkg_manager" in
        apt) sudo apt update && sudo apt install -y "${all_packages[@]}" ;;
        dnf) sudo dnf install -y "${all_packages[@]}" ;;
        pacman) sudo pacman -S --needed --noconfirm "${all_packages[@]}" ;;
        zypper) sudo zypper install -y "${all_packages[@]}" ;;
    esac

    if [[ "$pkg_manager" == "pacman" && ${#aur_packages[@]} -gt 0 ]]; then
        install_aur_helper
        log_info "Installing AUR packages..."
        paru -S --noconfirm "${aur_packages[@]}"
    fi

    log_info "Installing standalone scripts to ~/.local/bin..."
    local bin_dir="${HOME}/.local/bin"
    mkdir -p "$bin_dir"
    local scripts_url_base="https://raw.githubusercontent.com/jspractice-1480122229/didactic-waddle/master/bash/scripts"
    local scripts=("install_ponysay.sh" "bmedia" "bimg" "bsys" "bfileops" "butils" "bfinder" "barchive")

    for script in "${scripts[@]}"; do
        log_info "Downloading ${script}..."
        if wget -q "${scripts_url_base}/${script}" -O "${bin_dir}/${script}"; then
            chmod +x "${bin_dir}/${script}"
        else
            log_warn "Failed to download ${script}"
        fi
    done

    # Create minimal .bashrc that sources repo config files
    if [[ -f "${HOME}/.bashrc" ]]; then
        local timestamp; timestamp=$(date +%Y%m%d_%H%M%S)
        log_info "Backing up existing .bashrc to .bashrc.backup_${timestamp}"
        mv "${HOME}/.bashrc" "${HOME}/.bashrc.backup_${timestamp}"
    fi

    log_info "Generating minimal .bashrc (sources repo config files)..."
    cat > "${HOME}/.bashrc" << 'EOL'
# ~/.bashrc: generated by bootstrap script - sources repo configuration
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.pyenv/bin:$PATH"

# Source configuration files from repo
if [ -f ~/.bash_aliases ]; then . ~/.bash_aliases; fi
if [ -f ~/.bash_functions ]; then . ~/.bash_functions; fi
if [ -f ~/.bash_personal ]; then . ~/.bash_personal; fi

# Tool initialization
if command -v pyenv 1>/dev/null 2>&1; then eval "$(pyenv init -)"; fi
if command -v fnm 1>/dev/null 2>&1; then eval "$(fnm env --use-on-cd)"; fi
EOL

    log_info "Generating Fish shell configuration..."
    local fish_config_dir="${HOME}/.config/fish"
    mkdir -p "$fish_config_dir/conf.d" "$fish_config_dir/functions"

    cat > "$fish_config_dir/config.fish" << 'EOL'
# config.fish: generated by bootstrap script
set -gx PATH $HOME/.local/bin $HOME/.cargo/bin $PATH
if command -v starship >/dev/null; starship init fish | source; end
if command -v pyenv >/dev/null; pyenv init - | source; end
if command -v fnm >/dev/null; fnm env --use-on-cd | source; end
if command -v zoxide >/dev/null; zoxide init fish | source; end
if test -f ~/.config/fish/config.personal.fish; source ~/.config/fish/config.personal.fish; end
EOL

    cat > "$fish_config_dir/conf.d/aliases.fish" << 'EOL'
# aliases.fish: generated by bootstrap script
alias rm 'rm -iv'
alias cp 'cp -iv'
alias mv 'mv -iv'
alias .. 'cd ..'
alias ... 'cd ../..'
if command -v eza >/dev/null
    alias ls 'eza --icons'
    alias ll 'eza -l --icons'
    alias la 'eza -la --icons'
else
    alias ls 'ls -F --color=auto'
    alias ll 'ls -alF --color=auto'
end
EOL

    cat > "$fish_config_dir/functions/wrappers.fish" << 'EOL'
# Fish function wrappers for standalone scripts
function media; bmedia $argv; end
function img; bimg $argv; end
function sys; bsys $argv; end
function fileops; bfileops $argv; end
function utils; butils $argv; end
function finder; bfinder $argv; end
function archive; barchive $argv; end
EOL

    if ! command -v pyenv &>/dev/null; then
        log_info "Installing pyenv..."
        curl https://pyenv.run | bash
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init --path)"
    fi

    if ! command -v fnm &>/dev/null; then
        log_info "Installing fnm (Node.js version manager)..."
        curl -fsSL https://fnm.vercel.app/install | bash
    fi

    if ! command -v cargo &>/dev/null; then
        log_info "Installing Rust via rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi

    log_info "Installing/updating modern CLI tools via cargo..."
    local rust_tools=("eza" "bat" "ripgrep" "fd-find" "sd" "du-dust" "procs" "bottom" "zoxide" "starship")
    cargo install "${rust_tools[@]}"

    log_info "Bootstrap v3.7 complete!"
    log_info "JDK installed: $jdk_package"
    log_info "Shell configurations source your repo files (.bash_aliases, .bash_functions, .bash_personal)"
    log_info "Node.js management: Use 'fnm install <version>' and 'fnm use <version>'"
    log_info "Please run 'source ~/.bashrc' or restart your terminal."
    log_info "To install ponysay, run the separate 'install_ponysay.sh' script."
}

main "$@"
