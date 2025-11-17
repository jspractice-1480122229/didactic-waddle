#!/bin/bash
# ==============================================================================
# ULTIMATE CROSS-DISTRO BOOTSTRAP SCRIPT v4.0
# The One Script to Rule Them All
# ==============================================================================
# Combines the best of both worlds:
# - Smart distro detection with normalization (Script 1)
# - Dynamic JDK detection (Script 2)
# - Package availability checking (Script 1)
# - VSCodium/Edge repo setup with error handling (Script 2)
# - fnm-only Node.js approach (Script 2)
# - Vim compilation from source (Script 1)
# - YouCompleteMe setup (Script 1)
# - Inline bash function generation (Script 1)
# - Python build deps (Script 2)
# - Rust tools installation (Script 2)
# - Standalone script downloads (Script 2)
# - Comprehensive testing (Script 1)
# - IDEMPOTENT: Safe to run multiple times
# ==============================================================================

set -euo pipefail

# ==============================================================================
# SECTION 1: FOUNDATION
# ==============================================================================

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_info "Ultimate Bootstrap Script v4.0 starting..."

# ==============================================================================
# SECTION 2: DISTRO DETECTION
# ==============================================================================

# Function to normalize distribution ID
normalize_distro_id() {
    local distro="$1"
    local distro_like="$2"
    
    # Convert to lowercase for comparison
    distro=$(echo "$distro" | tr '[:upper:]' '[:lower:]')
    distro_like=$(echo "$distro_like" | tr '[:upper:]' '[:lower:]')
    
    # Check if distro matches known patterns
    case "$distro" in
        "ubuntu"|"debian"|"linuxmint"|"elementary"|"zorin"|"pop"|"kali"|"raspbian")
            echo "debian"
            ;;
        "fedora"|"rhel"|"centos"|"rocky"|"almalinux"|"oracle")
            echo "fedora"
            ;;
        "arch"|"manjaro"|"endeavouros"|"garuda"|"artix")
            echo "arch"
            ;;
        "opensuse"|"opensuse-leap"|"opensuse-tumbleweed"|"sles")
            echo "opensuse"
            ;;
        *)
            # If no direct match, check ID_LIKE
            if [[ -n "$distro_like" ]]; then
                # Handle space-separated ID_LIKE values
                for like_distro in $distro_like; do
                    case "$like_distro" in
                        "ubuntu"|"debian")
                            echo "debian"
                            return 0
                            ;;
                        "fedora"|"rhel"|"centos")
                            echo "fedora"
                            return 0
                            ;;
                        "arch")
                            echo "arch"
                            return 0
                            ;;
                        "opensuse"|"suse")
                            echo "opensuse"
                            return 0
                            ;;
                    esac
                done
            fi
            # Return original if no match found
            echo "$distro"
            ;;
    esac
}

# Function to detect package manager and distribution
detect_distro() {
    local pkg_manager=""
    local distro=""
    local distro_like=""
    
    if command -v apt &>/dev/null; then
        pkg_manager="apt"
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            distro=$(normalize_distro_id "$ID" "${ID_LIKE:-}")
        fi
    elif command -v dnf5 &>/dev/null; then
        pkg_manager="dnf5"
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            distro=$(normalize_distro_id "$ID" "${ID_LIKE:-}")
        fi
    elif command -v dnf &>/dev/null; then
        pkg_manager="dnf"
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            distro=$(normalize_distro_id "$ID" "${ID_LIKE:-}")
        fi
    elif command -v yum &>/dev/null; then
        pkg_manager="yum"
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            distro=$(normalize_distro_id "$ID" "${ID_LIKE:-}")
        fi
    elif command -v pacman &>/dev/null; then
        pkg_manager="pacman"
        distro="arch"
    elif command -v zypper &>/dev/null; then
        pkg_manager="zypper"
        distro="opensuse"
    else
        log_error "Unsupported package manager. This script supports apt, dnf5, dnf, yum, pacman, and zypper."
        exit 1
    fi
    
    echo "$pkg_manager:$distro"
}

# Function to check if a package is available in repositories
check_package_availability() {
    local pkg_manager="$1"
    local package="$2"
    
    case "$pkg_manager" in
        "apt")
            apt-cache show "$package" &>/dev/null
            ;;
        "dnf5")
            dnf5 info "$package" &>/dev/null
            ;;
        "dnf")
            dnf info "$package" &>/dev/null
            ;;
        "yum")
            yum info "$package" &>/dev/null
            ;;
        "pacman")
            pacman -Si "$package" &>/dev/null
            ;;
        "zypper")
            zypper info "$package" &>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

# ==============================================================================
# SECTION 3: SMART DETECTION HELPERS
# ==============================================================================

# Function to detect latest available JDK
detect_latest_jdk() {
    local pkg_manager="$1"
    case "$pkg_manager" in
        "apt") apt-cache search "^openjdk-[0-9]+-jdk$" 2>/dev/null | grep -oE 'openjdk-[0-9]+-jdk' | sort -V | tail -1 || echo "openjdk-11-jdk" ;;
        "dnf"|"dnf5"|"yum") dnf list available 2>/dev/null | grep -oE 'java-[0-9]+-openjdk-devel' | sort -V | tail -1 || echo "java-11-openjdk-devel" ;;
        "pacman") pacman -Ss 2>/dev/null | grep -oE 'jdk[0-9]+-openjdk' | sort -V | tail -1 || echo "jdk11-openjdk" ;;
        "zypper") zypper search 2>/dev/null | grep -oE 'java-[0-9]+-openjdk-devel' | sort -V | tail -1 || echo "java-11-openjdk-devel" ;;
        *) echo "openjdk-11-jdk" ;;
    esac
}

# Function to ensure DNF5 is available on DNF systems
ensure_dnf5() {
    local pkg_manager="$1"
    
    if [[ "$pkg_manager" == "dnf" ]]; then
        if ! command -v dnf5 &>/dev/null; then
            log_info "DNF5 not found. Installing DNF5..."
            if sudo dnf install -y dnf5; then
                log_info "Successfully installed DNF5"
                return 0
            else
                log_warn "Failed to install DNF5, continuing with DNF"
                return 1
            fi
        fi
    fi
    return 0
}

# Function to check internet connectivity
check_internet_connectivity() {
    if ! curl -s --connect-timeout 5 https://packages.microsoft.com >/dev/null; then
        log_error "Cannot reach package repositories. Check internet connection."
        return 1
    fi
    return 0
}

# ==============================================================================
# SECTION 4: REPO SETUP
# ==============================================================================

setup_additional_repos() {
    local pkg_manager="$1"
    
    case "$pkg_manager" in
        "apt")
            log_info "Setting up additional APT repositories for VSCodium and MS Edge..."
            
            # Check internet connectivity first
            if ! check_internet_connectivity; then
                return 1
            fi
            
            # Install repo dependencies (idempotent)
            sudo apt update || { log_error "Failed to update package lists"; return 1; }
            sudo apt install -y curl gpg apt-transport-https || { log_error "Failed to install repo dependencies"; return 1; }
            
            # VSCodium repo (idempotent - overwrites if exists)
            if [[ ! -f /etc/apt/sources.list.d/vscodium.list ]]; then
                log_info "Adding VSCodium repository..."
                if curl -fsSL https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | sudo gpg --dearmor -o /usr/share/keyrings/vscodium-archive-keyring.gpg; then
                    echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' | sudo tee /etc/apt/sources.list.d/vscodium.list
                else
                    log_warn "Failed to add VSCodium repository"
                fi
            else
                log_info "VSCodium repository already configured"
            fi
            
            # Microsoft Edge repo (idempotent - overwrites if exists)
            if [[ ! -f /etc/apt/sources.list.d/microsoft-edge.list ]]; then
                log_info "Adding Microsoft Edge repository..."
                if curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-edge-keyring.gpg; then
                    echo 'deb [ arch=amd64 signed-by=/usr/share/keyrings/microsoft-edge-keyring.gpg ] https://packages.microsoft.com/repos/edge stable main' | sudo tee /etc/apt/sources.list.d/microsoft-edge.list
                else
                    log_warn "Failed to add Microsoft Edge repository"
                fi
            else
                log_info "Microsoft Edge repository already configured"
            fi
            
            sudo apt update
            ;;
        "dnf"|"dnf5"|"yum")
            log_info "Setting up additional DNF repositories for VSCodium and MS Edge..."
            
            # VSCodium repo (idempotent)
            if [[ ! -f /etc/yum.repos.d/vscodium.repo ]]; then
                log_info "Adding VSCodium repository..."
                sudo rpm --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg
                printf "[gitlab.com_paulcarroty_vscodium_repo]\nname=download.vscodium.com\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg\n" | sudo tee /etc/yum.repos.d/vscodium.repo
            else
                log_info "VSCodium repository already configured"
            fi
            
            # Microsoft Edge repo (idempotent)
            if [[ ! -f /etc/yum.repos.d/microsoft-edge.repo ]]; then
                log_info "Adding Microsoft Edge repository..."
                sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
                printf "[microsoft-edge]\nname=Microsoft Edge\nbaseurl=https://packages.microsoft.com/yumrepos/edge/\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc\n" | sudo tee /etc/yum.repos.d/microsoft-edge.repo
            else
                log_info "Microsoft Edge repository already configured"
            fi
            ;;
    esac
}

# ==============================================================================
# SECTION 5: AUR HELPER
# ==============================================================================

install_aur_helper() {
    # Idempotent - skip if already installed
    if command -v paru &>/dev/null || command -v yay &>/dev/null; then
        log_info "AUR helper already installed"
        return
    fi
    
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

# ==============================================================================
# SECTION 6: PACKAGE INSTALLATION
# ==============================================================================

install_packages() {
    local pkg_manager="$1"
    local distro="$2"
    shift 2
    local packages=("$@")
    
    local available_packages=()
    local unavailable_packages=()
    
    # Check package availability
    for pkg in "${packages[@]}"; do
        if check_package_availability "$pkg_manager" "$pkg"; then
            available_packages+=("$pkg")
        else
            unavailable_packages+=("$pkg")
        fi
    done
    
    # Report unavailable packages
    if [[ ${#unavailable_packages[@]} -gt 0 ]]; then
        log_warn "The following packages are not available: ${unavailable_packages[*]}"
    fi
    
    # Install available packages (idempotent - package managers handle this)
    if [[ ${#available_packages[@]} -gt 0 ]]; then
        log_info "Installing packages: ${available_packages[*]}"
        
        case "$pkg_manager" in
            "apt")
                sudo apt update
                sudo apt install -y "${available_packages[@]}"
                ;;
            "dnf5")
                sudo dnf5 install -y "${available_packages[@]}"
                ;;
            "dnf")
                sudo dnf install -y "${available_packages[@]}"
                ;;
            "yum")
                sudo yum install -y "${available_packages[@]}"
                ;;
            "pacman")
                sudo pacman -S --needed --noconfirm "${available_packages[@]}"
                ;;
            "zypper")
                sudo zypper install -y "${available_packages[@]}"
                ;;
        esac
    fi
}

# ==============================================================================
# SECTION 7: VIM COMPILATION
# ==============================================================================

compile_vim_from_source() {
    local pkg_manager="$1"
    
    # Idempotent check - skip if custom vim already compiled
    if [[ -f "${HOME}/.vim_compiled_marker" ]]; then
        log_info "Vim already compiled from source (marker found)"
        return 0
    fi
    
    log_info "Compiling Vim from source..."
    
    # Install build dependencies per distro
    local build_deps=()
    case "$pkg_manager" in
        "apt")
            build_deps=("libncurses5-dev" "libgtk-3-dev" "libatk1.0-dev" "libcairo2-dev" "libx11-dev" "libxpm-dev" "libxt-dev" "python3-dev" "ruby-dev" "lua5.2" "liblua5.2-dev" "libperl-dev" "git")
            ;;
        "dnf"|"dnf5"|"yum")
            build_deps=("ncurses-devel" "gtk3-devel" "atk-devel" "cairo-devel" "libX11-devel" "libXpm-devel" "libXt-devel" "python3-devel" "ruby-devel" "lua-devel" "perl-devel" "git")
            ;;
        "pacman")
            build_deps=("ncurses" "gtk3" "atk" "cairo" "libx11" "libxpm" "libxt" "python" "ruby" "lua" "perl" "git")
            ;;
        "zypper")
            build_deps=("ncurses-devel" "gtk3-devel" "atk-devel" "cairo-devel" "libX11-devel" "libXpm-devel" "libXt-devel" "python3-devel" "ruby-devel" "lua-devel" "perl" "git")
            ;;
    esac
    
    log_info "Installing Vim build dependencies..."
    install_packages "$pkg_manager" "unused" "${build_deps[@]}"
    
    # Clone and build Vim
    local vim_dir="${HOME}/vim_build"
    if [[ -d "$vim_dir" ]]; then
        log_info "Removing old vim build directory..."
        rm -rf "$vim_dir"
    fi
    
    mkdir -p "$vim_dir"
    cd "$vim_dir"
    
    if git clone https://github.com/vim/vim.git; then
        cd vim
        ./configure --with-features=huge \
                    --enable-multibyte \
                    --enable-python3interp=yes \
                    --with-python3-config-dir=$(python3-config --configdir) \
                    --enable-gui=gtk3 \
                    --enable-cscope \
                    --prefix=/usr/local
        
        if make; then
            sudo make install
            log_info "Vim compiled and installed successfully"
            touch "${HOME}/.vim_compiled_marker"
        else
            log_error "Failed to compile Vim"
            cd "$HOME"
            return 1
        fi
    else
        log_error "Failed to clone Vim repository"
        cd "$HOME"
        return 1
    fi
    
    cd "$HOME"
}

setup_vim_config() {
    # Idempotent - backup if exists
    if [[ -d "${HOME}/.vim_runtime" ]]; then
        if [[ ! -d "${HOME}/.vim_runtime.backup" ]]; then
            log_info "Backing up existing vim runtime..."
            mv "${HOME}/.vim_runtime" "${HOME}/.vim_runtime.backup"
        else
            log_info "Vim runtime already exists, skipping backup"
            return 0
        fi
    fi
    
    log_info "Setting up Vim configuration..."
    if git clone --depth=1 https://github.com/amix/vimrc.git "${HOME}/.vim_runtime"; then
        log_info "Downloaded vim configuration"
        if bash "${HOME}/.vim_runtime/install_awesome_vimrc.sh"; then
            log_info "Installed awesome vimrc"
        else
            log_warn "Failed to install awesome vimrc"
        fi
    else
        log_warn "Failed to clone vim configuration"
    fi
}

install_ycm() {
    # Idempotent check
    if [[ -f "${HOME}/.ycm_installed_marker" ]]; then
        log_info "YouCompleteMe already installed (marker found)"
        return 0
    fi
    
    log_info "Setting up YouCompleteMe..."
    
    # Setup Vundle if not already installed
    if [[ ! -d "${HOME}/.vim/bundle/Vundle.vim" ]]; then
        log_info "Installing Vundle..."
        mkdir -p "${HOME}/.vim/bundle"
        if git clone https://github.com/VundleVim/Vundle.vim.git "${HOME}/.vim/bundle/Vundle.vim"; then
            log_info "Successfully installed Vundle"
        else
            log_error "Failed to install Vundle"
            return 1
        fi
    else
        log_info "Vundle already installed"
    fi
    
    # Create custom vim configuration
    log_info "Creating custom vim configuration for YCM..."
    cat > "${HOME}/.vim_runtime/my_configs.vim" << 'EOL'
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
    
    # Install plugins via Vundle
    log_info "Installing Vim plugins (this may take a while)..."
    vim +PluginInstall +qall
    
    # Compile YCM
    if [[ -d "${HOME}/.vim/bundle/YouCompleteMe" ]]; then
        log_info "Compiling YouCompleteMe..."
        cd "${HOME}/.vim/bundle/YouCompleteMe"
        if python3 install.py --all; then
            log_info "YouCompleteMe compiled successfully"
            touch "${HOME}/.ycm_installed_marker"
        else
            log_error "Failed to compile YouCompleteMe"
            cd "$HOME"
            return 1
        fi
        cd "$HOME"
    else
        log_error "YouCompleteMe plugin not found"
        return 1
    fi
}

# ==============================================================================
# SECTION 8: BASH CONFIG GENERATION
# ==============================================================================

generate_bash_functions() {
    local file="${HOME}/.bash_functions"
    
    # Idempotent - backup if exists
    if [[ -f "$file" ]]; then
        if [[ ! -f "${file}.backup" ]]; then
            log_info "Backing up existing .bash_functions..."
            cp "$file" "${file}.backup"
        fi
    fi
    
    log_info "Generating .bash_functions..."
    cat > "$file" << 'EOL'
# ~/.bash_functions
# Generated by Ultimate Bootstrap Script v4.0

# ==============================================================================
# MEDIA FUNCTIONS
# ==============================================================================

# YouTube downloader wrapper
ytdl() {
    if ! command -v yt-dlp &>/dev/null; then
        echo "yt-dlp not installed"
        return 1
    fi
    yt-dlp "$@"
}

# Download audio only
ytdl_audio() {
    if ! command -v yt-dlp &>/dev/null; then
        echo "yt-dlp not installed"
        return 1
    fi
    yt-dlp -x --audio-format mp3 --audio-quality 0 "$@"
}

# Download playlist
ytdl_playlist() {
    if ! command -v yt-dlp &>/dev/null; then
        echo "yt-dlp not installed"
        return 1
    fi
    yt-dlp -f best -o "%(playlist_index)s-%(title)s.%(ext)s" "$@"
}

# Convert video to mp3
vid2mp3() {
    if ! command -v ffmpeg &>/dev/null; then
        echo "ffmpeg not installed"
        return 1
    fi
    local input="$1"
    local output="${input%.*}.mp3"
    ffmpeg -i "$input" -vn -ar 44100 -ac 2 -b:a 192k "$output"
}

# Convert video to different format
convert_video() {
    if ! command -v ffmpeg &>/dev/null; then
        echo "ffmpeg not installed"
        return 1
    fi
    local input="$1"
    local format="$2"
    local output="${input%.*}.$format"
    ffmpeg -i "$input" "$output"
}

# Extract audio from video
extract_audio() {
    if ! command -v ffmpeg &>/dev/null; then
        echo "ffmpeg not installed"
        return 1
    fi
    local input="$1"
    local output="${input%.*}.mp3"
    ffmpeg -i "$input" -q:a 0 -map a "$output"
}

# ==============================================================================
# IMAGE FUNCTIONS
# ==============================================================================

# Convert image to WebP
img2webp() {
    if ! command -v cwebp &>/dev/null; then
        echo "cwebp not installed"
        return 1
    fi
    local input="$1"
    local output="${input%.*}.webp"
    cwebp -q 80 "$input" -o "$output"
}

# Batch convert images to WebP
batch_webp() {
    if ! command -v cwebp &>/dev/null; then
        echo "cwebp not installed"
        return 1
    fi
    for img in *.{jpg,jpeg,png,JPG,JPEG,PNG}; do
        [[ -f "$img" ]] || continue
        local output="${img%.*}.webp"
        echo "Converting $img to $output..."
        cwebp -q 80 "$img" -o "$output"
    done
}

# Optimize JPEG images
optimize_jpg() {
    if ! command -v jpegoptim &>/dev/null; then
        echo "jpegoptim not installed"
        return 1
    fi
    jpegoptim --max=85 --strip-all "$@"
}

# Resize image
resize_img() {
    if ! command -v convert &>/dev/null; then
        echo "imagemagick not installed"
        return 1
    fi
    local input="$1"
    local size="$2"
    local output="${input%.*}_resized.${input##*.}"
    convert "$input" -resize "$size" "$output"
}

# Create thumbnail
thumbnail() {
    if ! command -v convert &>/dev/null; then
        echo "imagemagick not installed"
        return 1
    fi
    local input="$1"
    local size="${2:-200x200}"
    local output="${input%.*}_thumb.${input##*.}"
    convert "$input" -thumbnail "$size" "$output"
}

# Remove EXIF data from images
strip_exif() {
    if ! command -v exiftool &>/dev/null; then
        echo "exiftool not installed"
        return 1
    fi
    exiftool -all= "$@"
}

# ==============================================================================
# SYSTEM FUNCTIONS
# ==============================================================================

# Update system
sysupdate() {
    if command -v apt &>/dev/null; then
        sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
    elif command -v dnf &>/dev/null; then
        sudo dnf upgrade -y && sudo dnf autoremove -y
    elif command -v pacman &>/dev/null; then
        sudo pacman -Syu --noconfirm
    elif command -v zypper &>/dev/null; then
        sudo zypper update -y && sudo zypper clean -a
    else
        echo "Unsupported package manager"
        return 1
    fi
}

# Clean system
sysclean() {
    if command -v apt &>/dev/null; then
        sudo apt autoremove -y && sudo apt autoclean -y
    elif command -v dnf &>/dev/null; then
        sudo dnf autoremove -y && sudo dnf clean all
    elif command -v pacman &>/dev/null; then
        sudo pacman -Scc --noconfirm
    elif command -v zypper &>/dev/null; then
        sudo zypper clean -a
    else
        echo "Unsupported package manager"
        return 1
    fi
}

# Show disk usage
diskusage() {
    if command -v dust &>/dev/null; then
        dust
    else
        du -h --max-depth=1 | sort -hr
    fi
}

# Show system information
sysinfo() {
    echo "=== System Information ==="
    echo "Hostname: $(hostname)"
    echo "OS: $(uname -s)"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "Distribution: $PRETTY_NAME"
    fi
    echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
    echo "Memory: $(free -h | awk '/^Mem:/ {print $3 " / " $2}')"
    echo "Disk: $(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 " used)"}')"
}

# ==============================================================================
# FILE OPERATION FUNCTIONS
# ==============================================================================

# Safe delete with confirmation
saferm() {
    for file in "$@"; do
        if [[ -e "$file" ]]; then
            read -p "Delete $file? (y/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -rf "$file"
                echo "Deleted: $file"
            fi
        else
            echo "File not found: $file"
        fi
    done
}

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract any archive
extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *.xz)        xz -d "$1"       ;;
            *)           echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Create archive
compress() {
    local format="$1"
    local output="$2"
    shift 2
    
    case "$format" in
        tar.gz|tgz)
            tar czf "$output" "$@"
            ;;
        tar.bz2|tbz2)
            tar cjf "$output" "$@"
            ;;
        tar.xz|txz)
            tar cJf "$output" "$@"
            ;;
        zip)
            zip -r "$output" "$@"
            ;;
        7z)
            7z a "$output" "$@"
            ;;
        *)
            echo "Unsupported format: $format"
            echo "Supported: tar.gz, tar.bz2, tar.xz, zip, 7z"
            return 1
            ;;
    esac
}

# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================

# Generate random password
genpass() {
    local length="${1:-16}"
    tr -dc 'A-Za-z0-9!@#$%^&*()_+=' < /dev/urandom | head -c "$length"
    echo
}

# Generate UUID
genuuid() {
    if command -v uuidgen &>/dev/null; then
        uuidgen
    else
        cat /proc/sys/kernel/random/uuid
    fi
}

# Find files by name
ff() {
    find . -type f -iname "*$1*"
}

# Find directories by name
fd() {
    find . -type d -iname "*$1*"
}

# Grep in files (recursive search)
search() {
    if command -v rg &>/dev/null; then
        rg "$@"
    else
        grep -r "$@" .
    fi
}

# Show PATH in readable format
showpath() {
    echo "$PATH" | tr ':' '\n'
}

# Weather report
weather() {
    local location="${1:-}"
    curl "wttr.in/${location}"
}

# Cheat sheet
cheat() {
    curl "cheat.sh/$1"
}

# ==============================================================================
# FINDER FUNCTIONS
# ==============================================================================

# Find largest files
largest() {
    local count="${1:-10}"
    if command -v dust &>/dev/null; then
        dust -n "$count"
    else
        du -ah . | sort -rh | head -n "$count"
    fi
}

# Find duplicate files
finddups() {
    find . -type f -exec md5sum {} + | sort | uniq -w32 -D
}

# Find empty directories
findempty() {
    find . -type d -empty
}

# Find broken symlinks
findbroken() {
    find . -type l ! -exec test -e {} \; -print
}

# ==============================================================================
# VIM COMPILATION FUNCTIONS
# ==============================================================================

install_vim() {
    echo "This will compile Vim from source with Python3 support"
    read -p "Continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 0
    fi
    
    # This calls the script's compile function
    compile_vim_from_source "$(detect_distro | cut -d: -f1)"
}

install_ycm() {
    echo "This will install YouCompleteMe for Vim"
    read -p "Continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 0
    fi
    
    # This calls the script's YCM install function
    install_ycm
}

# ==============================================================================
# FUN FUNCTIONS
# ==============================================================================

# Random cowsay fortune
moo() {
    if command -v fortune &>/dev/null && command -v cowsay &>/dev/null; then
        fortune | cowsay
    elif command -v fortune &>/dev/null; then
        fortune
    else
        echo "Install fortune and cowsay for this function"
    fi
}

# Ponysay wrapper
ponies() {
    if command -v ponysay &>/dev/null; then
        if command -v fortune &>/dev/null; then
            fortune | ponysay
        else
            ponysay "Install fortune for random quotes!"
        fi
    elif command -v cowsay &>/dev/null; then
        echo "Ponysay not installed, using cowsay instead..."
        if command -v fortune &>/dev/null; then
            fortune | cowsay
        else
            cowsay "Install ponysay for pony magic!"
        fi
    else
        echo "Install ponysay or cowsay for pony fun!"
    fi
}

EOL
    
    log_info ".bash_functions created successfully"
}

generate_bash_aliases() {
    local file="${HOME}/.bash_aliases"
    
    # Idempotent - backup if exists
    if [[ -f "$file" ]]; then
        if [[ ! -f "${file}.backup" ]]; then
            log_info "Backing up existing .bash_aliases..."
            cp "$file" "${file}.backup"
        fi
    fi
    
    log_info "Generating .bash_aliases..."
    cat > "$file" << 'EOL'
# ~/.bash_aliases
# Generated by Ultimate Bootstrap Script v4.0

# Safety aliases
alias rm='rm -iv'
alias cp='cp -iv'
alias mv='mv -iv'
alias mkdir='mkdir -pv'

# Navigation aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# ls aliases (with eza fallback)
if command -v eza &>/dev/null; then
    alias ls='eza --icons'
    alias ll='eza -l --icons'
    alias la='eza -la --icons'
    alias lt='eza --tree --icons'
else
    alias ls='ls -F --color=auto'
    alias ll='ls -alF --color=auto'
    alias la='ls -A --color=auto'
    alias l='ls -CF --color=auto'
fi

# grep aliases
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# Modern tool aliases
if command -v bat &>/dev/null; then
    alias cat='bat'
fi

if command -v rg &>/dev/null; then
    alias grep='rg'
fi

if command -v dust &>/dev/null; then
    alias du='dust'
fi

if command -v procs &>/dev/null; then
    alias ps='procs'
fi

if command -v bottom &>/dev/null; then
    alias top='btm'
    alias htop='btm'
fi

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph'
alias gd='git diff'

# Utility aliases
alias h='history'
alias j='jobs -l'
alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%T"'
alias nowdate='date +"%Y-%m-%d"'

# System aliases
alias update='sysupdate'
alias clean='sysclean'
alias ports='netstat -tulanp'

# Podman aliases
alias pd='podman'
alias pdc='podman-compose'
alias pdi='podman images'
alias pdps='podman ps'
alias pdpsa='podman ps -a'

EOL
    
    log_info ".bash_aliases created successfully"
}

generate_bashrc() {
    local file="${HOME}/.bashrc"
    
    # Idempotent - backup existing
    if [[ -f "$file" ]]; then
        local timestamp; timestamp=$(date +%Y%m%d_%H%M%S)
        if [[ ! -f "${file}.bootstrap_backup_${timestamp}" ]]; then
            log_info "Backing up existing .bashrc to .bashrc.bootstrap_backup_${timestamp}"
            cp "$file" "${file}.bootstrap_backup_${timestamp}"
        fi
    fi
    
    log_info "Generating minimal .bashrc (sources repo config files)..."
    cat > "$file" << 'EOL'
# ~/.bashrc: generated by Ultimate Bootstrap Script v4.0
# This config sources external files from your repo

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History settings
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend
shopt -s checkwinsize

# Make less more friendly
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Enable color prompt
force_color_prompt=yes
if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
    else
        PS1='\u@\h:\w\$ '
    fi
fi
unset force_color_prompt

# Enable programmable completion
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# PATH setup
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.pyenv/bin:$PATH"

# Source configuration files from repo and generated configs
if [ -f ~/.bash_aliases ]; then . ~/.bash_aliases; fi
if [ -f ~/.bash_functions ]; then . ~/.bash_functions; fi
if [ -f ~/.bash_personal ]; then . ~/.bash_personal; fi

# Tool initialization
if command -v pyenv 1>/dev/null 2>&1; then
    eval "$(pyenv init -)"
fi

if command -v fnm 1>/dev/null 2>&1; then
    eval "$(fnm env --use-on-cd)"
fi

if command -v starship 1>/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

if command -v zoxide 1>/dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi

EOL
    
    log_info ".bashrc created successfully"
}

# ==============================================================================
# SECTION 9: FISH SHELL SETUP
# ==============================================================================

generate_fish_config() {
    local fish_config_dir="${HOME}/.config/fish"
    local fish_functions_dir="${fish_config_dir}/functions"
    local fish_conf_d="${fish_config_dir}/conf.d"
    
    # Idempotent - create directories if needed
    mkdir -p "$fish_functions_dir" "$fish_conf_d"
    
    # Main config.fish (idempotent - overwrites)
    log_info "Generating Fish shell configuration..."
    cat > "$fish_config_dir/config.fish" << 'EOL'
# config.fish: generated by Ultimate Bootstrap Script v4.0
set -gx PATH $HOME/.local/bin $HOME/.cargo/bin $PATH

# Tool initialization
if command -v starship >/dev/null
    starship init fish | source
end

if command -v pyenv >/dev/null
    pyenv init - | source
end

if command -v fnm >/dev/null
    fnm env --use-on-cd | source
end

if command -v zoxide >/dev/null
    zoxide init fish | source
end

# Source personal config from repo if exists
if test -f ~/.config/fish/config.personal.fish
    source ~/.config/fish/config.personal.fish
end
EOL
    
    # Aliases (idempotent - overwrites)
    cat > "$fish_conf_d/aliases.fish" << 'EOL'
# aliases.fish: generated by Ultimate Bootstrap Script v4.0

# Safety aliases
alias rm 'rm -iv'
alias cp 'cp -iv'
alias mv 'mv -iv'

# Navigation
alias .. 'cd ..'
alias ... 'cd ../..'
alias .... 'cd ../../..'

# ls aliases with eza
if command -v eza >/dev/null
    alias ls 'eza --icons'
    alias ll 'eza -l --icons'
    alias la 'eza -la --icons'
    alias lt 'eza --tree --icons'
else
    alias ls 'ls -F --color=auto'
    alias ll 'ls -alF --color=auto'
end

# Modern tool aliases
if command -v bat >/dev/null
    alias cat 'bat'
end

if command -v rg >/dev/null
    alias grep 'rg'
end

if command -v dust >/dev/null
    alias du 'dust'
end

if command -v procs >/dev/null
    alias ps 'procs'
end

if command -v bottom >/dev/null
    alias top 'btm'
    alias htop 'btm'
end

# Git aliases
alias gs 'git status'
alias ga 'git add'
alias gc 'git commit'
alias gp 'git push'
alias gl 'git log --oneline --graph'

# System aliases
alias update 'sysupdate'
alias clean 'sysclean'

# Podman aliases
alias pd 'podman'
alias pdc 'podman-compose'
alias pdi 'podman images'
alias pdps 'podman ps'
EOL
    
    # Function wrappers for standalone scripts (idempotent - overwrites)
    cat > "$fish_functions_dir/wrappers.fish" << 'EOL'
# Fish function wrappers for standalone scripts
function media; bmedia $argv; end
function img; bimg $argv; end
function sys; bsys $argv; end
function fileops; bfileops $argv; end
function utils; butils $argv; end
function finder; bfinder $argv; end
function archive; barchive $argv; end
EOL
    
    # Download big_file_o_fish.txt if not already downloaded
    if [[ ! -f "${fish_functions_dir}/custom_functions.fish" ]]; then
        log_info "Downloading fish functions from repo..."
        if wget -q "https://raw.githubusercontent.com/jspractice-1480122229/didactic-waddle/master/fish/big_file_o_fish.txt" -O "${fish_functions_dir}/custom_functions.fish"; then
            log_info "Downloaded fish functions"
        else
            log_warn "Fish functions file not found in repository, you'll need to add them manually"
        fi
    else
        log_info "Fish custom functions already downloaded"
    fi
    
    # Test function (idempotent - overwrites)
    cat > "${fish_functions_dir}/test_install.fish" << 'EOL'
function test_install -d "Test if fish installation is working"
    echo "✅ Fish shell is installed and working!"
    echo "🐟 Fish version: $FISH_VERSION"
    echo "📁 Config directory: $__fish_config_dir"
    echo ""
    echo "=== Core Shell Tools ==="
    command -v fish >/dev/null 2>&1 && echo "✓ fish" || echo "✗ fish"
    command -v eza >/dev/null 2>&1 && echo "✓ eza (ls replacement)" || echo "✗ eza (using ls fallback)"
    command -v starship >/dev/null 2>&1 && echo "✓ starship prompt" || echo "✗ starship"
    command -v zoxide >/dev/null 2>&1 && echo "✓ zoxide" || echo "✗ zoxide"
    command -v fzf >/dev/null 2>&1 && echo "✓ fzf" || echo "✗ fzf"
    command -v fnm >/dev/null 2>&1 && echo "✓ fnm" || echo "✗ fnm"
    command -v pyenv >/dev/null 2>&1 && echo "✓ pyenv" || echo "✗ pyenv"
    
    echo ""
    echo "=== Media Tools ==="
    command -v yt-dlp >/dev/null 2>&1 && echo "✓ yt-dlp" || echo "✗ yt-dlp"
    command -v ffmpeg >/dev/null 2>&1 && echo "✓ ffmpeg" || echo "✗ ffmpeg"
    command -v lame >/dev/null 2>&1 && echo "✓ lame" || echo "✗ lame"
    command -v cwebp >/dev/null 2>&1 && echo "✓ cwebp" || echo "✗ cwebp"
    command -v magick >/dev/null 2>&1 && echo "✓ imagemagick" || echo "✗ imagemagick"
    
    echo ""
    echo "=== Fun Tools ==="
    command -v cowsay >/dev/null 2>&1 && echo "✓ cowsay" || echo "✗ cowsay"
    command -v ponysay >/dev/null 2>&1 && echo "✓ ponysay" || echo "✗ ponysay (using fallback)"
    command -v fortune >/dev/null 2>&1 && echo "✓ fortune" || echo "✗ fortune"
    
    echo ""
    echo "=== Development Tools ==="
    command -v git >/dev/null 2>&1 && echo "✓ git" || echo "✗ git"
    command -v vim >/dev/null 2>&1 && echo "✓ vim" || echo "✗ vim"
    command -v gvim >/dev/null 2>&1 && echo "✓ gvim" || echo "✗ gvim"
    command -v go >/dev/null 2>&1 && echo "✓ go" || echo "✗ go"
    command -v cargo >/dev/null 2>&1 && echo "✓ cargo/rust" || echo "✗ cargo/rust"
    command -v node >/dev/null 2>&1 && echo "✓ node.js" || echo "✗ node.js"
    command -v python3 >/dev/null 2>&1 && echo "✓ python3" || echo "✗ python3"
    
    echo ""
    echo "=== Container Tools ==="
    command -v podman >/dev/null 2>&1 && echo "✓ podman" || echo "✗ podman"
    command -v podman-compose >/dev/null 2>&1 && echo "✓ podman-compose" || echo "✗ podman-compose"
    
    echo ""
    echo "=== Utility Tools ==="
    command -v colordiff >/dev/null 2>&1 && echo "✓ colordiff" || echo "✗ colordiff"
    command -v xz >/dev/null 2>&1 && echo "✓ xz" || echo "✗ xz"
    command -v unrar >/dev/null 2>&1 && echo "✓ unrar" || echo "✗ unrar"
    command -v 7z >/dev/null 2>&1 && echo "✓ 7z" || echo "✗ 7z"
    
    echo ""
    echo "🎉 Run 'ponies' to test the ponies function!"
    echo "📝 Run 'moo' for a random cowsay fortune!"
    echo "🚀 Your fish shell is ready to go!"
end
EOL
    
    # Dependency checker (idempotent - overwrites)
    cat > "${fish_functions_dir}/check_deps.fish" << 'EOL'
function check_deps -d "Check for missing dependencies for fish functions"
    set -l missing_deps
    
    # Check critical dependencies
    set -l deps yt-dlp ffmpeg lame imagemagick cwebp xz unrar 7z colordiff fortune cowsay
    
    for dep in $deps
        if not command -v $dep >/dev/null 2>&1
            set missing_deps $missing_deps $dep
        end
    end
    
    if test (count $missing_deps) -gt 0
        echo "⚠️  Missing dependencies: $missing_deps"
        echo "Install them with your package manager to enable all functions"
        return 1
    else
        echo "✅ All core dependencies are installed!"
        return 0
    end
end
EOL
    
    log_info "Fish shell configuration created successfully"
}

# ==============================================================================
# SECTION 10: STANDALONE SCRIPTS
# ==============================================================================

download_standalone_scripts() {
    log_info "Installing standalone scripts to ~/.local/bin..."
    local bin_dir="${HOME}/.local/bin"
    mkdir -p "$bin_dir"
    
    local scripts_url_base="https://raw.githubusercontent.com/jspractice-1480122229/didactic-waddle/master/bash/scripts"
    local scripts=("install_ponysay.sh" "bmedia" "bimg" "bsys" "bfileops" "butils" "bfinder" "barchive")
    
    for script in "${scripts[@]}"; do
        # Idempotent - skip if already exists and is executable
        if [[ -x "${bin_dir}/${script}" ]]; then
            log_info "${script} already installed, skipping"
            continue
        fi
        
        log_info "Downloading ${script}..."
        if wget -q "${scripts_url_base}/${script}" -O "${bin_dir}/${script}"; then
            chmod +x "${bin_dir}/${script}"
            log_info "Installed ${script}"
        else
            log_warn "Failed to download ${script}"
        fi
    done
}

# ==============================================================================
# SECTION 11: VERSION MANAGERS
# ==============================================================================

install_pyenv() {
    # Idempotent check
    if command -v pyenv &>/dev/null; then
        log_info "pyenv already installed"
        return 0
    fi
    
    log_info "Installing pyenv..."
    if curl https://pyenv.run | bash; then
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init --path)"
        log_info "pyenv installed successfully"
    else
        log_error "Failed to install pyenv"
        return 1
    fi
}

install_fnm() {
    # Idempotent check
    if command -v fnm &>/dev/null; then
        log_info "fnm already installed"
        return 0
    fi
    
    log_info "Installing fnm (Node.js version manager)..."
    if curl -fsSL https://fnm.vercel.app/install | bash; then
        log_info "fnm installed successfully"
    else
        log_error "Failed to install fnm"
        return 1
    fi
}

install_rust() {
    # Idempotent check
    if command -v cargo &>/dev/null; then
        log_info "Rust already installed"
        return 0
    fi
    
    log_info "Installing Rust via rustup..."
    if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
        source "$HOME/.cargo/env"
        log_info "Rust installed successfully"
    else
        log_error "Failed to install Rust"
        return 1
    fi
}

# ==============================================================================
# SECTION 12: RUST CLI TOOLS
# ==============================================================================

install_rust_tools() {
    if ! command -v cargo &>/dev/null; then
        log_warn "Cargo not available, skipping Rust tools installation"
        return 1
    fi
    
    log_info "Installing/updating modern CLI tools via cargo..."
    local rust_tools=("eza" "bat" "ripgrep" "fd-find" "sd" "du-dust" "procs" "bottom" "zoxide" "starship")
    
    for tool in "${rust_tools[@]}"; do
        # Idempotent - cargo install handles this
        log_info "Installing $tool..."
        cargo install "$tool" 2>&1 | grep -v "already installed" || true
    done
    
    log_info "Rust tools installation complete"
}

# ==============================================================================
# SECTION 13: MAIN ORCHESTRATION
# ==============================================================================

main() {
    log_info "Ultimate Bootstrap v4.0 starting..."
    
    # Detect distro and package manager
    local distro_info
    distro_info=$(detect_distro)
    local pkg_manager="${distro_info%%:*}"
    local distro="${distro_info##*:}"
    
    log_info "Detected package manager: $pkg_manager"
    log_info "Detected distribution: $distro"
    
    # Ensure DNF5 on DNF systems
    ensure_dnf5 "$pkg_manager"
    if command -v dnf5 &>/dev/null; then
        pkg_manager="dnf5"
        log_info "Using DNF5"
    fi
    
    # Detect latest JDK
    local jdk_package
    jdk_package=$(detect_latest_jdk "$pkg_manager")
    log_info "Latest JDK detected: $jdk_package"
    
    # Setup additional repositories
    setup_additional_repos "$pkg_manager"
    
    # Define package arrays per distro
    local core_packages=("wget" "curl" "git" "cmake" "tree" "net-tools" "perl" "gawk" "sed" "openssl" "tar" "unzip" "make" "gcc" "fish")
    local media_packages=()
    local dev_packages=()
    local util_packages=()
    local shell_packages=()
    local aur_packages=()
    local python_build_deps=()
    
    case "$pkg_manager" in
        "apt")
            core_packages+=("build-essential")
            media_packages=("yt-dlp" "ffmpeg" "lame" "ghostscript" "webp" "imagemagick" "jpegoptim" "cowsay" "libimage-exiftool-perl")
            dev_packages=("python3" "python3-pip" "golang" "codium" "microsoft-edge-stable" "$jdk_package")
            shell_packages=("fzf" "podman" "podman-compose")
            util_packages=("colordiff" "fortune-mod" "uuid-runtime" "unrar" "p7zip-full")
            python_build_deps=("libssl-dev" "libncurses-dev" "libsqlite3-dev" "libreadline-dev" "tk-dev" "libgdbm-dev" "libdb-dev" "libbz2-dev" "libexpat1-dev" "liblzma-dev" "zlib1g-dev" "libffi-dev")
            ;;
        "dnf"|"dnf5"|"yum")
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
    
    # Install main packages
    local all_packages=("${core_packages[@]}" "${media_packages[@]}" "${dev_packages[@]}" "${util_packages[@]}" "${shell_packages[@]}" "${python_build_deps[@]}")
    log_info "Installing main packages (including $jdk_package)..."
    install_packages "$pkg_manager" "$distro" "${all_packages[@]}"
    
    # Install AUR packages if Arch
    if [[ "$pkg_manager" == "pacman" && ${#aur_packages[@]} -gt 0 ]]; then
        install_aur_helper
        if command -v paru &>/dev/null; then
            log_info "Installing AUR packages..."
            paru -S --noconfirm "${aur_packages[@]}"
        fi
    fi
    
    # Compile Vim from source
    compile_vim_from_source "$pkg_manager"
    
    # Setup Vim config
    setup_vim_config
    
    # Install YouCompleteMe
    install_ycm
    
    # Generate bash configurations
    generate_bash_functions
    generate_bash_aliases
    generate_bashrc
    
    # Generate fish configuration
    generate_fish_config
    
    # Download standalone scripts
    download_standalone_scripts
    
    # Install version managers
    install_pyenv
    install_fnm
    install_rust
    
    # Install Rust CLI tools
    install_rust_tools
    
    # System update and cleanup
    log_info "Running system update and cleanup..."
    case "$pkg_manager" in
        "apt")
            sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt autoclean -y
            ;;
        "dnf5")
            sudo dnf5 upgrade -y && sudo dnf5 autoremove -y && sudo dnf5 clean all
            ;;
        "dnf")
            sudo dnf upgrade -y && sudo dnf autoremove -y && sudo dnf clean all
            ;;
        "yum")
            sudo yum update -y && sudo yum autoremove -y && sudo yum clean all
            ;;
        "pacman")
            sudo pacman -Syu --noconfirm
            ;;
        "zypper")
            sudo zypper update -y && sudo zypper clean -a
            ;;
    esac
    
    # ==============================================================================
    # SECTION 14: INSTALLATION SUMMARY
    # ==============================================================================
    
    log_info "Bootstrap completed successfully!"
    log_info "Distribution: $distro ($pkg_manager)"
    log_info "JDK installed: $jdk_package"
    echo ""
    
    log_info "=== Installation Summary ==="
    
    echo ""
    echo "=== Core Shell Tools ==="
    command -v fish &>/dev/null && log_info "✓ Fish shell installed" || log_error "✗ Fish shell NOT installed"
    command -v eza &>/dev/null && log_info "✓ eza (ls replacement) installed" || log_warn "✗ eza NOT installed (using ls fallback)"
    command -v starship &>/dev/null && log_info "✓ Starship prompt installed" || log_warn "✗ Starship NOT installed"
    command -v zoxide &>/dev/null && log_info "✓ Zoxide installed" || log_warn "✗ Zoxide NOT installed"
    command -v fzf &>/dev/null && log_info "✓ FZF installed" || log_warn "✗ FZF NOT installed"
    command -v bat &>/dev/null && log_info "✓ bat (cat replacement) installed" || log_warn "✗ bat NOT installed"
    command -v rg &>/dev/null && log_info "✓ ripgrep installed" || log_warn "✗ ripgrep NOT installed"
    
    echo ""
    echo "=== Version Managers ==="
    command -v fnm &>/dev/null && log_info "✓ FNM (Node.js manager) installed" || log_warn "✗ FNM NOT installed"
    command -v pyenv &>/dev/null && log_info "✓ pyenv installed" || log_warn "✗ pyenv NOT installed"
    command -v cargo &>/dev/null && log_info "✓ Rust/Cargo installed" || log_warn "✗ Rust/Cargo NOT installed"
    
    echo ""
    echo "=== Media Tools ==="
    command -v yt-dlp &>/dev/null && log_info "✓ yt-dlp installed" || log_warn "✗ yt-dlp NOT installed"
    command -v ffmpeg &>/dev/null && log_info "✓ FFmpeg installed" || log_warn "✗ FFmpeg NOT installed"
    command -v lame &>/dev/null && log_info "✓ lame installed" || log_warn "✗ lame NOT installed"
    command -v cwebp &>/dev/null && log_info "✓ WebP tools installed" || log_warn "✗ WebP tools NOT installed"
    command -v convert &>/dev/null && log_info "✓ ImageMagick installed" || log_warn "✗ ImageMagick NOT installed"
    
    echo ""
    echo "=== Fun Tools ==="
    command -v cowsay &>/dev/null && log_info "✓ Cowsay installed" || log_warn "✗ Cowsay NOT installed"
    command -v ponysay &>/dev/null && log_info "✓ Ponysay installed" || log_warn "✗ Ponysay NOT installed (run install_ponysay.sh)"
    command -v fortune &>/dev/null && log_info "✓ Fortune installed" || log_warn "✗ Fortune NOT installed"
    
    echo ""
    echo "=== Development Tools ==="
    command -v git &>/dev/null && log_info "✓ git installed" || log_warn "✗ git NOT installed"
    command -v vim &>/dev/null && log_info "✓ vim installed" || log_warn "✗ vim NOT installed"
    [[ -f "${HOME}/.vim_compiled_marker" ]] && log_info "✓ vim compiled from source" || log_warn "⚠️  vim not compiled from source yet"
    [[ -f "${HOME}/.ycm_installed_marker" ]] && log_info "✓ YouCompleteMe installed" || log_warn "⚠️  YouCompleteMe not installed yet"
    command -v go &>/dev/null && log_info "✓ Go installed" || log_warn "✗ Go NOT installed"
    command -v java &>/dev/null && log_info "✓ Java ($jdk_package) installed" || log_warn "✗ Java NOT installed"
    command -v python3 &>/dev/null && log_info "✓ Python3 installed" || log_warn "✗ Python3 NOT installed"
    command -v codium &>/dev/null && log_info "✓ VSCodium installed" || log_warn "✗ VSCodium NOT installed"
    command -v microsoft-edge &>/dev/null && log_info "✓ Microsoft Edge installed" || log_warn "✗ Microsoft Edge NOT installed"
    
    echo ""
    echo "=== Container Tools ==="
    command -v podman &>/dev/null && log_info "✓ Podman installed" || log_warn "✗ Podman NOT installed"
    command -v podman-compose &>/dev/null && log_info "✓ podman-compose installed" || log_warn "✗ podman-compose NOT installed"
    
    echo ""
    echo "=== Utility Tools ==="
    command -v colordiff &>/dev/null && log_info "✓ Colordiff installed" || log_warn "✗ Colordiff NOT installed"
    command -v xz &>/dev/null && log_info "✓ XZ utils installed" || log_warn "✗ XZ utils NOT installed"
    command -v unrar &>/dev/null && log_info "✓ unrar installed" || log_warn "✗ unrar NOT installed"
    command -v 7z &>/dev/null && log_info "✓ 7z installed" || log_warn "✗ 7z NOT installed"
    
    echo ""
    log_info "=== Next Steps ==="
    log_info "1. Run 'source ~/.bashrc' to load the new bash configuration"
    log_info "2. Enter fish shell by typing: fish"
    log_info "3. Set fish as default shell (optional): chsh -s \$(which fish)"
    log_info "4. In fish, run these commands to test:"
    log_info "   - test_install   # Check all installed tools"
    log_info "   - check_deps     # Check for missing dependencies"
    log_info "   - ponies         # Test the ponies function"
    log_info "   - moo            # Test cowsay with fortune"
    log_info ""
    log_info "5. Install Node.js version (via fnm):"
    log_info "   - fnm install 20  # Install Node.js 20"
    log_info "   - fnm use 20      # Use Node.js 20"
    log_info ""
    log_info "6. To install ponysay, run: install_ponysay.sh"
    
    if [[ "$pkg_manager" == "pacman" ]]; then
        log_info ""
        log_info "Note: You may need to restart your terminal for AUR helper to be available"
    fi
    
    echo ""
    log_info "=== Environment Variables to Set ==="
    log_info "Add these to your fish config if needed:"
    log_info "  set -Ux HF_TOKEN 'your-huggingface-token'"
    log_info "  set -Ux CEREBRAS_API_KEY 'your-cerebras-key'"
    log_info "  set -Ux GHCR_TOKEN 'your-github-container-token'"
    log_info "  set -Ux DISCOGS_TOKEN 'your-discogs-token'"
    
    echo ""
    log_info "==========================="
    log_info "This script is IDEMPOTENT - safe to run multiple times!"
    log_info "==========================="
}

# ==============================================================================
# SECTION 15: EXECUTION
# ==============================================================================

main "$@"
