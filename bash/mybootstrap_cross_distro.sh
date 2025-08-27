#!/bin/bash

# Cross-distro bootstrap script for new nodes - Enhanced v3.1 (Final)
# Supports: Ubuntu/Debian, Fedora/RHEL/CentOS, Arch Linux, openSUSE
# Incorporates all refinements from the red team review.
# Version: 3.1

set -euo pipefail # Exit on error, undefined variables, pipe failures

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Function to detect package manager and distribution (no changes needed)
detect_distro() {
    local pkg_manager=""
    if command -v apt &>/dev/null; then pkg_manager="apt";
    elif command -v dnf &>/dev/null; then pkg_manager="dnf";
    elif command -v pacman &>/dev/null; then pkg_manager="pacman";
    elif command -v zypper &>/dev/null; then pkg_manager="zypper";
    else log_error "Unsupported package manager." && exit 1; fi
    echo "$pkg_manager"
}

# Function to set up third-party repositories for APT and DNF
setup_additional_repos() {
    local pkg_manager="$1"

    case "$pkg_manager" in
        "apt")
            log_info "Setting up additional APT repositories for VSCodium and MS Edge..."
            sudo apt update
            sudo apt install -y curl gpg apt-transport-https

            # VSCodium Repo
            curl -fsSL https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | sudo gpg --dearmor -o /usr/share/keyrings/vscodium-archive-keyring.gpg
            echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' | sudo tee /etc/apt/sources.list.d/vscodium.list

            # Microsoft Edge Repo
            curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-edge-keyring.gpg
            echo 'deb [ arch=amd64 signed-by=/usr/share/keyrings/microsoft-edge-keyring.gpg ] https://packages.microsoft.com/repos/edge stable main' | sudo tee /etc/apt/sources.list.d/microsoft-edge.list
            
            sudo apt update
            ;;
        "dnf")
            log_info "Setting up additional DNF repositories for VSCodium and MS Edge..."
            # VSCodium Repo
            sudo rpm --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg
            printf "[gitlab.com_paulcarroty_vscodium_repo]\nname=download.vscodium.com\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg\n" | sudo tee /etc/yum.repos.d/vscodium.repo

            # Microsoft Edge Repo
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            printf "[microsoft-edge]\nname=Microsoft Edge\nbaseurl=https://packages.microsoft.com/yumrepos/edge/\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc\n" | sudo tee /etc/yum.repos.d/microsoft-edge.repo
            ;;
    esac
}

# Function to install AUR helper with trap for cleanup
install_aur_helper() {
    if command -v paru &>/dev/null || command -v yay &>/dev/null; then return; fi
    log_info "Installing AUR helper (paru)..."
    sudo pacman -S --needed --noconfirm base-devel git
    
    local temp_dir
    temp_dir=$(mktemp -d)
    trap 'log_info "Cleaning up temp directory..."; rm -rf "$temp_dir"' EXIT

    cd "$temp_dir"
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm
    cd "$HOME"
}

# Function to install ponysay from source using pyenv (safer)
install_ponysay_from_source() {
    log_info "Installing ponysay from source using pyenv..."

    local temp_dir
    temp_dir=$(mktemp -d)
    trap 'log_info "Cleaning up temp directory..."; rm -rf "$temp_dir"' EXIT

    cd "$temp_dir" || return 1
    if git clone --depth 1 https://github.com/erkin/ponysay.git; then
        cd ponysay
        log_info "Ensuring a pyenv Python version is installed..."
        pyenv install 3.11.9 --skip-existing
        pyenv global 3.11.9
        eval "$(pyenv init -)"

        log_info "Installing ponysay with pip into pyenv..."
        if pip install .; then
            log_info "Successfully installed ponysay via pyenv"
        else
            log_warn "Failed to install ponysay with pip"
        fi
    else
        log_warn "Failed to clone ponysay repository"
    fi
    cd "$HOME"
}

# Main execution
main() {
    log_info "Cross-distro bootstrap script v3.1 starting..."
    local pkg_manager
    pkg_manager=$(detect_distro)
    log_info "Detected package manager: $pkg_manager"

    # Call the new function to add repos
    setup_additional_repos "$pkg_manager"

    # Define packages
    local core_packages=("wget" "curl" "git" "cmake" "tree" "net-tools" "perl" "gawk" "sed" "openssl" "tar" "unzip" "make" "gcc" "fish" "build-essential")
    local media_packages=()
    local dev_packages=()
    local util_packages=()
    local shell_packages=()
    local aur_packages=()

    case "$pkg_manager" in
        "apt")
            media_packages=("yt-dlp" "ffmpeg" "lame" "ghostscript" "webp" "imagemagick" "jpegoptim" "cowsay")
            dev_packages=("python3" "python3-pip" "golang" "nodejs" "npm" "codium" "microsoft-edge-stable")
            shell_packages=("fzf" "podman" "podman-compose")
            util_packages=("colordiff" "fortune" "uuid-runtime" "unrar" "p7zip-full")
            sudo apt update
            ;;
        "dnf")
            media_packages=("yt-dlp" "ffmpeg" "lame" "ghostscript" "libwebp-tools" "ImageMagick" "jpegoptim" "cowsay")
            dev_packages=("python3" "python3-pip" "golang" "nodejs" "npm" "codium" "microsoft-edge-stable")
            shell_packages=("fzf" "podman" "podman-compose" "starship")
            util_packages=("colordiff" "fortune-mod" "util-linux" "unrar" "p7zip")
            ;;
        "pacman")
            media_packages=("yt-dlp" "ffmpeg" "lame" "ghostscript" "libwebp" "imagemagick" "jpegoptim" "cowsay")
            dev_packages=("python" "python-pip" "go" "nodejs" "npm" "pyenv")
            shell_packages=("fzf" "podman" "podman-compose" "starship" "zoxide" "eza")
            util_packages=("colordiff" "fortune-mod")
            aur_packages=("microsoft-edge-stable" "vscodium")
            ;;
        "zypper")
            media_packages=("yt-dlp" "ffmpeg" "lame" "ghostscript" "libwebp-tools" "ImageMagick" "jpegoptim" "cowsay")
            dev_packages=("python3" "python3-pip" "go" "nodejs" "npm")
            shell_packages=("fzf" "podman" "podman-compose")
            util_packages=("colordiff" "fortune" "unrar" "p7zip")
            ;;
    esac

    # Install packages
    local all_packages=("${core_packages[@]}" "${media_packages[@]}" "${dev_packages[@]}" "${util_packages[@]}" "${shell_packages[@]}")
    log_info "Installing main packages..."
    case "$pkg_manager" in
        apt) sudo apt install -y "${all_packages[@]}" ;;
        dnf) sudo dnf install -y "${all_packages[@]}" ;;
        pacman) sudo pacman -S --needed --noconfirm "${all_packages[@]}" ;;
        zypper) sudo zypper install -y "${all_packages[@]}" ;;
    esac

    # Handle AUR
    if [[ "$pkg_manager" == "pacman" && ${#aur_packages[@]} -gt 0 ]]; then
        install_aur_helper
        log_info "Installing AUR packages..."
        paru -S --noconfirm "${aur_packages[@]}"
    fi

    # Fish shell setup with safer aliases
    log_info "Setting up fish shell configuration..."
    local fish_config_dir="${HOME}/.config/fish"
    mkdir -p "$fish_config_dir/functions" && mkdir -p "$fish_config_dir/conf.d"
    
    # Main config.fish
    cat > "$fish_config_dir/config.fish" << 'EOL'
set -g fish_greeting
set -gx EDITOR vim
set -gx PATH $HOME/.local/bin $HOME/bin /usr/local/go/bin $HOME/.cargo/bin $PATH
if test -d $HOME/.pyenv; set -gx PATH $HOME/.pyenv/bin $PATH; status is-interactive; and pyenv init - | source; end
if command -v starship >/dev/null; starship init fish | source; end
if command -v fnm >/dev/null; fnm env --use-on-cd | source; end
if command -v zoxide >/dev/null; zoxide init fish | source; end
# Source personal configs if they exist
if test -f ~/.config/fish/config.personal.fish; source ~/.config/fish/config.personal.fish; end
EOL

    # Aliases with safer interactive flags
    cat > "$fish_config_dir/conf.d/aliases.fish" << 'EOL'
# Aliases with interactive safety and eza fallback
alias cp='cp -iv'; alias mv='mv -iv'; alias rm='rm -iv'
alias ..='cd ..'; alias ...='cd ../..'; alias ll='ls -l'
if command -v eza &>/dev/null
    alias ls 'eza -F --header --icons --git'
    alias ll 'eza -l --header --git --icons'
    alias la 'eza -al --header --git --icons'
    alias lt 'eza -lT'
else
    alias ls 'ls -F --color=auto'
    alias ll 'ls -alF --color=auto'
    alias la 'ls -A --color=auto'
end
EOL

    # Timestamped backup of .bashrc
    if [[ -f "${HOME}/.bashrc" ]]; then
        local timestamp
        timestamp=$(date +%Y%m%d_%H%M%S)
        log_info "Backing up existing .bashrc to .bashrc.backup_${timestamp}"
        mv "${HOME}/.bashrc" "${HOME}/.bashrc.backup_${timestamp}"
    fi

    # Download Bash configs
    log_info "Downloading bash configuration files..."
    wget -q https://raw.githubusercontent.com/jspractice-1480122229/didactic-waddle/master/bash/.bashrc -O "${HOME}/.bashrc"
    wget -q https://raw.githubusercontent.com/jspractice-1480122229/didactic-waddle/master/bash/.bash_aliases -O "${HOME}/.bash_aliases"
    wget -q https://raw.githubusercontent.com/jspractice-1480122229/didactic-waddle/master/bash/.bash_functions -O "${HOME}/.bash_functions"

    # Install pyenv
    if ! command -v pyenv &>/dev/null; then
        log_info "Installing pyenv..."
        curl https://pyenv.run | bash
    fi
    
    # Install fnm
    if ! command -v fnm &>/dev/null; then
        log_info "Installing fnm..."
        curl -fsSL https://fnm.vercel.app/install | bash
        # Idempotent config add
        if ! grep -q "fnm env" "$fish_config_dir/config.fish"; then
            echo 'fnm env --use-on-cd | source' >> "$fish_config_dir/config.fish"
        fi
    fi

    # Install Rust
    if ! command -v cargo &>/dev/null; then
        log_info "Installing Rust via rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi

    # Install modern CLI tools via cargo
    log_info "Installing/updating modern CLI tools via cargo..."
    local rust_tools=("eza" "bat" "ripgrep" "fd-find" "sd" "dust" "procs" "bottom" "zoxide" "starship")
    cargo install "${rust_tools[@]}"

    # Install ponysay if not found
    if ! command -v ponysay &>/dev/null; then
        install_ponysay_from_source
    fi

    log_info "Bootstrap completed successfully!"
    log_info "Please run 'source ~/.bashrc' or restart your terminal."
    log_info "Then type 'fish' to start the Fish shell."
}

main "$@"
