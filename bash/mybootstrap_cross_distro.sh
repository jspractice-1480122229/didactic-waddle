#!/bin/bash

# Cross-distro bootstrap script for new nodes
# Supports: Ubuntu/Debian, Fedora/RHEL/CentOS, Arch Linux, openSUSE
# Author: Enhanced for cross-distro compatibility
# Version: 2.0

set -euo pipefail  # Exit on error, undefined variables, pipe failures

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

log_info "Cross-distro bootstrap script starting..."

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
# Function to install packages
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
    
    # Install available packages
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
                sudo pacman -Sy --needed "${available_packages[@]}"
                ;;
            "zypper")
                sudo zypper install -y "${available_packages[@]}"
                ;;
        esac
    fi
}

# Function to install COPR packages (similar to AUR)
install_copr_packages() {
    local pkg_manager="$1"
    shift
    local copr_packages=("$@")
    
    if [[ ${#copr_packages[@]} -eq 0 ]]; then
        log_info "No COPR packages to install"
        return 0
    fi
    
    # Check if dnf-plugins-core is installed for COPR support
    if [[ "$pkg_manager" == "dnf5" ]]; then
        if ! dnf5 list installed dnf5-plugins &>/dev/null; then
            log_info "Installing dnf5-plugins for COPR support..."
            sudo dnf5 install -y dnf5-plugins || log_warn "Failed to install dnf5-plugins"
        fi
    elif [[ "$pkg_manager" == "dnf" ]]; then
        if ! dnf list installed dnf-plugins-core &>/dev/null; then
            log_info "Installing dnf-plugins-core for COPR support..."
            sudo dnf install -y dnf-plugins-core || log_warn "Failed to install dnf-plugins-core"
        fi
    fi
    
    log_info "Installing COPR packages..."
    
    for pkg_info in "${copr_packages[@]}"; do
        # Format: "copr_repo:package_name"
        local copr_repo="${pkg_info%:*}"
        local package_name="${pkg_info#*:}"
        
        # Check if package is already installed
        if check_package_availability "$pkg_manager" "$package_name"; then
            log_info "$package_name is already available in standard repos"
            continue
        fi
        
        log_info "Enabling COPR repository: $copr_repo"
        local copr_cmd=""
        if [[ "$pkg_manager" == "dnf5" ]]; then
            copr_cmd="sudo dnf5 copr enable -y $copr_repo"
        else
            copr_cmd="sudo dnf copr enable -y $copr_repo"
        fi
        
        if eval "$copr_cmd"; then
            log_info "Successfully enabled COPR: $copr_repo"
            
            # Try to install the package
            local install_cmd=""
            if [[ "$pkg_manager" == "dnf5" ]]; then
                install_cmd="sudo dnf5 install -y $package_name"
            else
                install_cmd="sudo dnf install -y $package_name"
            fi
            
            if eval "$install_cmd"; then
                log_info "Successfully installed $package_name from COPR"
            else
                log_warn "Failed to install $package_name from COPR: $copr_repo"
            fi
        else
            log_warn "Failed to enable COPR repository: $copr_repo"
        fi
    done
}
install_aur_helper() {
    # Check if an AUR helper is already installed
    if command -v paru &>/dev/null; then
        log_info "Found paru AUR helper"
        echo "paru"
        return 0
    elif command -v yay &>/dev/null; then
        log_info "Found yay AUR helper"
        echo "yay"
        return 0
    fi
    
    # Try to install paru first (recommended), then yay
    log_info "Installing AUR helper..."
    
    # Install base-devel if not present
    if ! pacman -Qi base-devel &>/dev/null; then
        log_info "Installing base-devel group..."
        sudo pacman -S --needed base-devel
    fi
    
    # Install git if not present
    if ! command -v git &>/dev/null; then
        log_info "Installing git..."
        sudo pacman -S --needed git
    fi
    
    # Try to install paru
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    if git clone https://aur.archlinux.org/paru.git; then
        cd paru
        if makepkg -si --noconfirm; then
            log_info "Successfully installed paru"
            cd "$HOME"
            rm -rf "$temp_dir"
            echo "paru"
            return 0
        fi
    fi
    
    # Fallback to yay
    cd "$temp_dir"
    if git clone https://aur.archlinux.org/yay.git; then
        cd yay
        if makepkg -si --noconfirm; then
            log_info "Successfully installed yay"
            cd "$HOME"
            rm -rf "$temp_dir"
            echo "yay"
            return 0
        fi
    fi
    
    cd "$HOME"
    rm -rf "$temp_dir"
    log_warn "Failed to install AUR helper"
    return 1
}

# Function to install AUR packages
install_aur_packages() {
    local aur_helper="$1"
    shift
    local packages=("$@")
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        log_info "No AUR packages to install"
        return 0
    fi
    
    if [[ -z "$aur_helper" ]]; then
        log_warn "No AUR helper available. Skipping AUR packages: ${packages[*]}"
        return 0
    fi
    
    log_info "Installing AUR packages with $aur_helper..."
    
    for pkg in "${packages[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            log_info "Installing $pkg from AUR..."
            if ! "$aur_helper" -S --noconfirm "$pkg"; then
                log_warn "Failed to install $pkg from AUR"
            fi
        else
            log_info "$pkg is already installed"
        fi
    done
}

# Function to enable additional repositories
enable_additional_repos() {
    local pkg_manager="$1"
    local distro="$2"
    
    case "$pkg_manager" in
        "dnf5"|"dnf"|"yum")
            # Enable EPEL for RHEL/CentOS-based systems
            if [[ "$distro" == "fedora" ]]; then
                # Check for RHEL-based systems that report as fedora-like
                if [[ -f /etc/os-release ]]; then
                    . /etc/os-release
                    if [[ "$ID" == "rhel" || "$ID" == "centos" || "$ID" == "rocky" || "$ID" == "almalinux" || "$ID" == "oracle" ]]; then
                        local epel_check=""
                        if [[ "$pkg_manager" == "dnf5" ]]; then
                            epel_check="dnf5 repolist enabled"
                        else
                            epel_check="dnf repolist enabled"
                        fi
                        
                        if ! $epel_check | grep -q epel; then
                            log_info "Enabling EPEL repository for $ID..."
                            if [[ "$pkg_manager" == "dnf5" ]]; then
                                sudo dnf5 install -y epel-release
                            else
                                sudo dnf install -y epel-release
                            fi
                        fi
                    else
                        # Enable RPM Fusion for actual Fedora
                        local fusion_check=""
                        if [[ "$pkg_manager" == "dnf5" ]]; then
                            fusion_check="dnf5 repolist enabled"
                        else
                            fusion_check="dnf repolist enabled"
                        fi
                        
                        if ! $fusion_check | grep -q rpmfusion; then
                            log_info "Enabling RPM Fusion repositories for Fedora..."
                            local fedora_version=$(rpm -E %fedora)
                            local install_cmd=""
                            if [[ "$pkg_manager" == "dnf5" ]]; then
                                install_cmd="sudo dnf5 install -y"
                            else
                                install_cmd="sudo dnf install -y"
                            fi
                            
                            $install_cmd \
                                "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_version}.noarch.rpm" \
                                "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_version}.noarch.rpm" 2>/dev/null || true
                        fi
                    fi
                fi
            fi
            ;;
        "zypper")
            # Enable Packman repository for openSUSE
            if ! zypper repos | grep -q packman; then
                log_info "Enabling Packman repository..."
                sudo zypper addrepo -cfp 90 'https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/' packman || true
            fi
            ;;
    esac
}

# Main execution starts here
main() {
    log_info "Detecting distribution and package manager..."
    
    local distro_info
    distro_info=$(detect_distro)
    local pkg_manager="${distro_info%:*}"
    local distro="${distro_info#*:}"
    
    log_info "Detected: $distro with $pkg_manager package manager"
    
    # Enable additional repositories
    enable_additional_repos "$pkg_manager" "$distro"
    
    # Ensure DNF5 is available if using DNF
    if [[ "$pkg_manager" == "dnf" ]]; then
        if ensure_dnf5 "$pkg_manager"; then
            # Update package manager to dnf5 if successfully installed
            if command -v dnf5 &>/dev/null; then
                log_info "Switching to DNF5 for package management"
                pkg_manager="dnf5"
            fi
        fi
    fi
    
    # Define packages for each distribution
    local core_packages=(
        "wget" "curl" "git" "cmake" "tree" "net-tools" "perl" "gawk" "sed" 
        "openssl" "tar" "unzip" "make" "gcc"
    )
    
    local media_packages=()
    local dev_packages=()
    local util_packages=()
    local aur_packages=()
    local copr_packages=()
    
    case "$pkg_manager" in
        "apt")
            media_packages+=(
                "yt-dlp" "ffmpeg" "lame" "ghostscript" "webp" "imagemagick" 
                "jpegoptim"
            )
            util_packages+=(
                "colordiff" "fortune" "uuid-runtime" "unrar" "p7zip-full" 
                "cmark" "screenfetch"
            )
            dev_packages+=("ghostwriter")
            ;;
        "dnf5"|"dnf"|"yum")
            media_packages+=(
                "yt-dlp" "ffmpeg" "lame" "ghostscript" "libwebp-tools" 
                "imagemagick" "jpegoptim"
            )
            util_packages+=(
                "colordiff" "fortune-mod" "util-linux" "unrar" "p7zip" 
                "cmark" "screenfetch"
            )
            # COPR packages for Fedora/RHEL-based systems
            if [[ "$distro" == "fedora" ]]; then
                copr_packages+=("deathwish/ghostwriter:ghostwriter")
            fi
            ;;
        "pacman")
            media_packages+=(
                "yt-dlp" "ffmpeg" "lame" "ghostscript" "libwebp" "imagemagick" 
                "jpegoptim"
            )
            util_packages+=(
                "fortune-mod" "util-linux" "unrar" "p7zip" "cmark"
            )
            # AUR packages for Arch-based systems
            aur_packages+=("colordiff" "screenfetch")
            dev_packages+=("ghostwriter")
            ;;
        "zypper")
            media_packages+=(
                "yt-dlp" "ffmpeg" "lame" "ghostscript" "libwebp-tools" 
                "ImageMagick" "jpegoptim"
            )
            util_packages+=(
                "colordiff" "fortune" "util-linux" "unrar" "p7zip" 
                "cmark" "screenfetch"
            )
            ;;
    esac
    
    # Combine all packages
    local all_packages=("${core_packages[@]}" "${media_packages[@]}" "${util_packages[@]}" "${dev_packages[@]}")
    
    # Install regular packages
    install_packages "$pkg_manager" "$distro" "${all_packages[@]}"
    
    # Handle AUR packages for Arch Linux
    if [[ "$pkg_manager" == "pacman" && ${#aur_packages[@]} -gt 0 ]]; then
        log_info "Handling AUR packages..."
        local aur_helper=""
        if aur_helper=$(install_aur_helper); then
            install_aur_packages "$aur_helper" "${aur_packages[@]}"
        else
            log_warn "Could not install AUR helper. Skipping AUR packages: ${aur_packages[*]}"
        fi
    fi
    
    # Handle COPR packages for Fedora/RHEL
    if [[ ("$pkg_manager" == "dnf5" || "$pkg_manager" == "dnf" || "$pkg_manager" == "yum") && ${#copr_packages[@]} -gt 0 ]]; then
        log_info "Handling COPR packages..."
        install_copr_packages "$pkg_manager" "${copr_packages[@]}"
    fi
    
    # Backup existing .bashrc
    if [[ -f "${HOME}/.bashrc" ]]; then
        log_info "Backing up existing .bashrc to .bashrc.backup"
        cp "${HOME}/.bashrc" "${HOME}/.bashrc.backup"
    fi
    
    # Download bash configuration files
    log_info "Downloading bash configuration files..."
    local config_files=(
        ".bashrc"
        ".bash_aliases"
        ".bash_functions"
        ".gitconfig"
        ".git-credentials"
    )
    
    for config_file in "${config_files[@]}"; do
        if wget -q "https://raw.githubusercontent.com/jspractice-1480122229/didactic-waddle/master/bash/$config_file" -O "${HOME}/$config_file"; then
            log_info "Downloaded $config_file"
        else
            log_warn "Failed to download $config_file"
        fi
    done
    
    # Download global gitignore
    if curl -s -o "${HOME}/.gitignore_global.txt" "https://raw.githubusercontent.com/padosoft/gitignore/master/gitignore_global.txt"; then
        log_info "Downloaded .gitignore_global.txt"
    else
        log_warn "Failed to download .gitignore_global.txt"
    fi
    
    # Install fnm (Fast Node Manager)
    log_info "Installing fnm (Fast Node Manager)..."
    if curl -fsSL https://fnm.vercel.app/install | bash; then
        log_info "Successfully installed fnm"
    else
        log_warn "Failed to install fnm"
    fi
    
    # System update and cleanup
    log_info "Updating system and cleaning up..."
    case "$pkg_manager" in
        "apt")
            sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y --purge
            ;;
        "dnf5")
            sudo dnf5 update -y && sudo dnf5 autoremove -y
            ;;
        "dnf")
            sudo dnf update -y && sudo dnf autoremove -y
            ;;
        "yum")
            sudo yum update -y && sudo yum autoremove -y
            ;;
        "pacman")
            sudo pacman -Syu --noconfirm
            ;;
        "zypper")
            sudo zypper update -y && sudo zypper clean -a
            ;;
    esac
    
    # Install Vim configuration
    log_info "Setting up Vim configuration..."
    if [[ -d "${HOME}/.vim_runtime" ]]; then
        log_info "Vim runtime already exists, backing up..."
        mv "${HOME}/.vim_runtime" "${HOME}/.vim_runtime.backup"
    fi
    
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
    
    # Setup Vundle for Vim plugins
    log_info "Setting up Vundle for Vim plugins..."
    if [[ ! -d "${HOME}/.vim/bundle" ]]; then
        mkdir -p "${HOME}/.vim/bundle"
    fi
    
    if git clone https://github.com/VundleVim/Vundle.vim.git "${HOME}/.vim/bundle/Vundle.vim"; then
        log_info "Successfully installed Vundle"
        
        # Create custom vim configuration
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
        log_info "Created custom vim configuration"
    else
        log_warn "Failed to install Vundle"
    fi
    
    # Final message
    log_info "Bootstrap completed successfully!"
    log_info "Distribution: $distro ($pkg_manager)"
    log_info "Please run 'source ~/.bashrc' to load the new configuration"
    
    if [[ "$pkg_manager" == "pacman" ]]; then
        log_info "Note: You may need to restart your terminal for AUR helper to be available"
    fi
}

# Run main function
main "$@"
