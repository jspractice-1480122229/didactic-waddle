#!/bin/bash

# Cross-distro bootstrap script for new nodes - Enhanced v3.0
# Supports: Ubuntu/Debian, Fedora/RHEL/CentOS, Arch Linux, openSUSE
# Now with full fish shell and function support
# Version: 3.0

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

log_info "Cross-distro bootstrap script v3.0 starting..."

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
                sudo pacman -Sy --needed --noconfirm "${available_packages[@]}"
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

# Function to install AUR helper
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
        sudo pacman -S --needed --noconfirm base-devel
    fi
    
    # Install git if not present
    if ! command -v git &>/dev/null; then
        log_info "Installing git..."
        sudo pacman -S --needed --noconfirm git
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

# Function to install ponysay from source
install_ponysay_from_source() {
    log_info "Installing ponysay from source..."
    
    # Install required build dependencies first
    log_info "Installing ponysay build dependencies..."
    case "$pkg_manager" in
        "apt")
            sudo apt install -y python3 python3-setuptools texinfo || log_warn "Failed to install some dependencies"
            ;;
        "dnf5"|"dnf"|"yum")
            sudo $pkg_manager install -y python3 python3-setuptools texinfo || log_warn "Failed to install some dependencies"
            ;;
        "pacman")
            sudo pacman -S --needed --noconfirm python python-setuptools texinfo || log_warn "Failed to install some dependencies"
            ;;
        "zypper")
            sudo zypper install -y python3 python3-setuptools texinfo || log_warn "Failed to install some dependencies"
            ;;
    esac
    
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Clone ponysay repository
    if git clone --depth 1 https://github.com/erkin/ponysay.git; then
        cd ponysay
        
        # Check if Python 3 is available
        if ! command -v python3 &>/dev/null; then
            log_warn "Python 3 not found, skipping ponysay installation"
            cd "$HOME"
            rm -rf "$temp_dir"
            return 1
        fi
        
        # Try to install
        if sudo python3 setup.py install --freedom=partial; then
            log_info "Successfully installed ponysay from source"
            cd "$HOME"
            rm -rf "$temp_dir"
            return 0
        else
            log_warn "Failed to install ponysay from source"
        fi
    else
        log_warn "Failed to clone ponysay repository"
    fi
    
    cd "$HOME"
    rm -rf "$temp_dir"
    return 1
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

# Function to create fish config directory and files
setup_fish_config() {
    log_info "Setting up fish shell configuration..."
    
    # Create fish config directory structure
    local fish_config_dir="${HOME}/.config/fish"
    mkdir -p "$fish_config_dir/functions"
    mkdir -p "$fish_config_dir/conf.d"
    
    # Create a comprehensive config.fish
    cat > "$fish_config_dir/config.fish" << 'EOL'
# Fish Shell Configuration

# Disable greeting
set -g fish_greeting

# Set environment variables
set -gx EDITOR vim
set -gx VISUAL gvim

# Set up PATH
set -gx PATH $HOME/.local/bin $HOME/binnie /usr/local/go/bin $HOME/.cargo/bin $PATH

# GOPATH setup
set -gx GOPATH $HOME/go
set -gx PATH $PATH $GOPATH/bin

# Pyenv setup
if test -d $HOME/.pyenv
    set -gx PATH $HOME/.pyenv/bin $PATH
    status is-interactive; and pyenv init - | source
end

# Starship prompt (if available)
if command -v starship >/dev/null 2>&1
    starship init fish | source
end

# FNM (Fast Node Manager) setup
if command -v fnm >/dev/null 2>&1
    fnm env --use-on-cd | source
end

# Enable FZF keybindings (if available)
if command -v fzf >/dev/null 2>&1
    if test -f /usr/share/fish/vendor_functions.d/fzf_key_bindings.fish
        source /usr/share/fish/vendor_functions.d/fzf_key_bindings.fish
    else if test -f $HOME/.fzf/shell/key-bindings.fish
        source $HOME/.fzf/shell/key-bindings.fish
    end
    # Try to enable fzf keybindings if function exists
    if functions -q fzf_key_bindings
        fzf_key_bindings
    end
end

# Enable Zoxide (if available)
if command -v zoxide >/dev/null 2>&1
    zoxide init fish | source
end

# Load custom functions
for file in $HOME/.config/fish/functions/*.fish
    source $file
end

# Load conf.d files
for file in $HOME/.config/fish/conf.d/*.fish
    source $file
end
EOL
    log_info "Created main fish config file"
    
    # Create aliases configuration in conf.d
    cat > "$fish_config_dir/conf.d/aliases.fish" << 'EOL'
# Basic aliases
alias rm 'rm -v'
alias cp 'cp -v'
alias mv 'mv -v'
alias du 'du -kh'
alias df 'df -kTh'
alias grep 'grep --color'
alias awk 'gawk'
alias mkdir 'mkdir -p'
alias h 'history'
alias j 'jobs -l'
alias .. 'cd ..'
alias ... 'cd ../..'
alias .... 'cd ../../..'
alias ..... 'cd ../../../..'
alias ...... 'cd ../../../../..'

# Enhanced aliases
alias path 'echo -e (string replace -a ":" "\n" $PATH)'
alias rd 'rm -frv'
alias diff 'colordiff -s'
alias cls 'clear'
alias vi 'vim'
alias fortune 'fortune -a -s -n 125'
alias purtyjson 'python -m json.tool'

# eza/ls aliases (with fallback to ls if eza not available)
if command -v eza >/dev/null 2>&1
    # eza is available
    alias ls 'eza -F --header --icons --git --group-directories-first'
    alias ll 'eza -l --header --git --icons --group-directories-first'
    alias la 'eza -al --header --git --icons --group-directories-first'
    alias l 'eza --classify --color-scale'
    alias dir 'eza --oneline'
    alias vdir 'eza --long'
    alias lx 'eza --long --sort=extension --ignore-glob="*~"'
    alias lk 'eza --long --sort=size --reverse'
    alias ltime 'eza --long --sort=modified --reverse'
    alias lc 'eza --long --sort=changed --reverse'
    alias lu 'eza --long --sort=accessed --reverse'
    alias lr 'eza --long --recurse --git'
    alias lm 'eza --long --all --git --color=always | more'
    alias l. 'eza -a | grep -e "^\."'
    alias lh 'eza -Al'
    alias ldir 'eza -l --group-directories-first'
    alias lt 'eza --long --sort=modified --reverse'
else
    # Fallback to standard ls
    alias ls 'ls -F --color=auto --group-directories-first'
    alias ll 'ls -alF --color=auto'
    alias la 'ls -A --color=auto'
    alias l 'ls -CF --color=auto'
end

# Cowsay/fortune fun (with fallbacks)
if command -v cowsay >/dev/null 2>&1; and command -v fortune >/dev/null 2>&1
    alias moo 'fortune -c | cowthink -f (find /usr/share/cowsay/cows -type f 2>/dev/null | shuf -n 1)'
else if command -v fortune >/dev/null 2>&1
    alias moo 'fortune -c'
end

# Container management (if podman is available)
if command -v podman >/dev/null 2>&1
    alias aye 'cd $HOME/pickles/dox/ai_rag/ && podman-compose down && podman-compose pull && podman-compose up -d --build'
end

# Date/time aliases
alias dia 'date +%s'
alias tstamp 'date +%Y-%m-%dT%T%:z'
EOL
    log_info "Created aliases configuration"
    
    # Create a fallback ponies function
    cat > "$fish_config_dir/functions/ponies.fish" << 'EOL'
function ponies -d "PONIES!!! (with intelligent fallback)"
    if command -v ponysay >/dev/null 2>&1
        fortune | ponysay
    else if command -v ponythink >/dev/null 2>&1
        fortune | ponythink -b unicode
    else if command -v cowsay >/dev/null 2>&1; and command -v fortune >/dev/null 2>&1
        fortune | cowsay
    else if command -v fortune >/dev/null 2>&1
        echo "🦄 PONIES!!! 🦄"
        fortune
    else
        echo "🦄 PONIES!!! 🦄"
        echo "Install fortune and cowsay/ponysay for the full experience!"
    end
end
EOL
    
    log_info "Fish shell configuration completed"
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
        "openssl" "tar" "unzip" "make" "gcc" "fish" "build-essential"  # Removed vim - compiled from source
    )
    
    local media_packages=()
    local dev_packages=()
    local util_packages=()
    local shell_packages=()  # New category for shell enhancements
    local aur_packages=()
    local copr_packages=()
    
    case "$pkg_manager" in
        "apt")
            media_packages+=(
                "yt-dlp" "ffmpeg" "lame" "ghostscript" "webp" "imagemagick" 
                "jpegoptim" "cowsay" "cwebp"
            )
            util_packages+=(
                "colordiff" "fortune" "uuid-runtime" "unrar" "p7zip-full" 
                "cmark" "screenfetch" "xz-utils" "coreutils" "texinfo"  # Added texinfo for ponysay
            )
            shell_packages+=(
                "fzf" "dircolors" "podman" "podman-compose"
            )
            dev_packages+=(
                "ghostwriter" "python3" "python3-pip" "python3-setuptools" "golang" "cargo" 
                "rustc" "nodejs" "npm" "snapd"  # Added snapd for snap packages
            )
            ;;
        "dnf5"|"dnf"|"yum")
            media_packages+=(
                "yt-dlp" "ffmpeg" "lame" "ghostscript" "libwebp-tools" 
                "ImageMagick" "jpegoptim" "cowsay"
            )
            util_packages+=(
                "colordiff" "fortune-mod" "util-linux" "unrar" "p7zip" 
                "cmark" "screenfetch" "xz" "coreutils" "texinfo"  # Added texinfo
            )
            shell_packages+=(
                "fzf" "podman" "podman-compose" "starship"
            )
            dev_packages+=(
                "ghostwriter" "python3" "python3-pip" "python3-setuptools" "golang" "cargo" "rust" 
                "nodejs" "npm"
            )
            # COPR packages for Fedora/RHEL-based systems
            if [[ "$distro" == "fedora" ]]; then
                # Only add if truly COPR-only packages needed
                copr_packages=()  # Empty for now, ready for COPR-only packages
            fi
            ;;
        "pacman")
            media_packages+=(
                "yt-dlp" "ffmpeg" "lame" "ghostscript" "libwebp" "imagemagick" 
                "jpegoptim" "cowsay"
            )
            util_packages+=(
                "colordiff" "fortune-mod" "util-linux" "unrar" "p7zip" "cmark" 
                "xz" "coreutils" "fzf" "podman" "podman-compose" "screenfetch" "texinfo"  # Added texinfo
            )
            shell_packages+=(
                "starship" "zoxide" "eza" "fnm" "ponysay"  # ponysay is in community repo for Arch
            )
            dev_packages+=(
                "ghostwriter" "python" "python-pip" "python-setuptools" "go" "rust" 
                "nodejs" "npm" "pyenv"
            )
            # AUR packages for Arch-based systems
            aur_packages=("microsoft-edge-stable")  # Add other AUR-only packages as needed
            ;;
        "zypper")
            media_packages+=(
                "yt-dlp" "ffmpeg" "lame" "ghostscript" "libwebp-tools" 
                "ImageMagick" "jpegoptim" "cowsay"
            )
            util_packages+=(
                "colordiff" "fortune" "util-linux" "unrar" "p7zip" 
                "cmark" "screenfetch" "xz" "coreutils" "texinfo"  # Added texinfo
            )
            shell_packages+=(
                "fzf" "podman" "podman-compose"
            )
            dev_packages+=(
                "python3" "python3-pip" "python3-setuptools" "go" "cargo" "rust" 
                "nodejs" "npm"
            )
            ;;
    esac
    
    # Combine all packages
    local all_packages=("${core_packages[@]}" "${media_packages[@]}" "${util_packages[@]}" "${dev_packages[@]}" "${shell_packages[@]}")
    
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
    
    # Try to install ponysay if not already installed
    if ! command -v ponysay &>/dev/null && ! command -v ponythink &>/dev/null; then
        log_info "Attempting to install ponysay..."
        
        case "$pkg_manager" in
            "apt")
                # First check if snap is available and try snap installation
                if command -v snap &>/dev/null; then
                    log_info "Trying to install ponysay via snap..."
                    if sudo snap install ponysay; then
                        log_info "Successfully installed ponysay via snap"
                    else
                        # Fallback to source installation
                        install_ponysay_from_source
                    fi
                else
                    # Try apt first, then source
                    if ! sudo apt install -y ponysay 2>/dev/null; then
                        install_ponysay_from_source
                    fi
                fi
                ;;
            "dnf5"|"dnf"|"yum")
                # Try from package manager
                if ! sudo $pkg_manager install -y ponysay 2>/dev/null; then
                    # Fallback to source
                    install_ponysay_from_source
                fi
                ;;
            "pacman")
                # Should be handled by package manager already
                if ! command -v ponysay &>/dev/null; then
                    log_info "ponysay should have been installed from community repo"
                    install_ponysay_from_source
                fi
                ;;
            "zypper")
                # Try from package manager
                if ! sudo zypper install -y ponysay 2>/dev/null; then
                    # Fallback to source
                    install_ponysay_from_source
                fi
                ;;
        esac
    fi
    
    # Set up fish shell configuration
    setup_fish_config
    
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
        
        # Add fnm to fish config if not already there
        local fish_config="${HOME}/.config/fish/config.fish"
        if [[ -f "$fish_config" ]] && ! grep -q "fnm.fish" "$fish_config"; then
            echo "" >> "$fish_config"
            echo "# fnm (Fast Node Manager)" >> "$fish_config"
            echo 'fnm env --use-on-cd | source' >> "$fish_config"
        fi
    else
        log_warn "Failed to install fnm"
    fi
    
    # Install additional shell tools that require special handling
    install_shell_tools() {
        log_info "Installing additional shell tools..."
        
        # Install Rust toolchain (needed for modern CLI tools)
        if ! command -v rustc &>/dev/null; then
            log_info "Installing Rust toolchain..."
            if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
                log_info "Successfully installed Rust"
                # Source cargo environment
                source "$HOME/.cargo/env"
            else
                log_warn "Failed to install Rust toolchain"
            fi
        else
            log_info "Rust toolchain already installed"
        fi
        
        # Install modern CLI tools via cargo
        if command -v cargo &>/dev/null; then
            log_info "Installing modern CLI tools..."
            
            # Essential modern replacements
            local rust_tools=(
                "eza"       # Better ls
                "bat"       # Better cat
                "ripgrep"   # Better grep (rg command)
                "fd-find"   # Better find (fd command)
                "sd"        # Better sed
                "dust"      # Better du
                "procs"     # Better ps
                "bottom"    # Better top (btm command)
                "zoxide"    # Better cd
                "starship"  # Better prompt
            )
            
            for tool in "${rust_tools[@]}"; do
                if ! command -v "${tool%% *}" &>/dev/null; then
                    log_info "Installing $tool via cargo..."
                    cargo install "$tool" || log_warn "Failed to install $tool"
                else
                    log_info "$tool already installed"
                fi
            done
            
            # Special handling for tools with different binary names
            if ! command -v rg &>/dev/null; then
                cargo install ripgrep || log_warn "Failed to install ripgrep"
            fi
            
            if ! command -v fd &>/dev/null; then
                cargo install fd-find || log_warn "Failed to install fd-find"
            fi
            
            if ! command -v btm &>/dev/null; then
                cargo install bottom || log_warn "Failed to install bottom"
            fi
        fi
        
        # Install eza (modern ls replacement)
        if ! command -v eza &>/dev/null; then
            log_info "Installing eza..."
            case "$pkg_manager" in
                "apt")
                    # For Ubuntu/Debian, eza needs manual installation
                    local eza_version="0.18.0"
                    local eza_url="https://github.com/eza-community/eza/releases/download/v${eza_version}/eza_x86_64-unknown-linux-gnu.tar.gz"
                    local temp_dir=$(mktemp -d)
                    if wget -q "$eza_url" -O "$temp_dir/eza.tar.gz"; then
                        tar -xzf "$temp_dir/eza.tar.gz" -C "$temp_dir"
                        sudo mv "$temp_dir/eza" /usr/local/bin/
                        sudo chmod +x /usr/local/bin/eza
                        log_info "Successfully installed eza"
                    else
                        log_warn "Failed to download eza"
                    fi
                    rm -rf "$temp_dir"
                    ;;
                "dnf5"|"dnf"|"yum")
                    # Try to install from package manager
                    if ! sudo $pkg_manager install -y eza 2>/dev/null; then
                        # Fallback to manual installation
                        local eza_version="0.18.0"
                        local eza_url="https://github.com/eza-community/eza/releases/download/v${eza_version}/eza_x86_64-unknown-linux-gnu.tar.gz"
                        local temp_dir=$(mktemp -d)
                        if wget -q "$eza_url" -O "$temp_dir/eza.tar.gz"; then
                            tar -xzf "$temp_dir/eza.tar.gz" -C "$temp_dir"
                            sudo mv "$temp_dir/eza" /usr/local/bin/
                            sudo chmod +x /usr/local/bin/eza
                            log_info "Successfully installed eza"
                        else
                            log_warn "Failed to download eza"
                        fi
                        rm -rf "$temp_dir"
                    fi
                    ;;
                "pacman")
                    # Should be installed via package manager already
                    log_info "eza should be installed via pacman"
                    ;;
                "zypper")
                    # Try cargo installation as fallback
                    if command -v cargo &>/dev/null; then
                        cargo install eza
                    else
                        log_warn "Cannot install eza - cargo not available"
                    fi
                    ;;
            esac
        fi
        
        # Install pyenv for Python version management
        if ! command -v pyenv &>/dev/null; then
            log_info "Installing pyenv..."
            if curl https://pyenv.run | bash; then
                log_info "Successfully installed pyenv"
                # Add to PATH
                export PATH="$HOME/.pyenv/bin:$PATH"
            else
                log_warn "Failed to install pyenv"
            fi
        fi
    }
    
    # Call the function to install shell tools
    install_shell_tools
    
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
    
    # Copy fish functions if they exist
    log_info "Setting up fish functions..."
    local fish_functions_dir="${HOME}/.config/fish/functions"
    
    # Download the big fish functions file if provided
    if wget -q "https://raw.githubusercontent.com/jspractice-1480122229/didactic-waddle/master/fish/big_file_o_fish.txt" -O "${fish_functions_dir}/custom_functions.fish"; then
        log_info "Downloaded fish functions"
    else
        log_warn "Fish functions file not found in repository, you'll need to add them manually"
    fi
    
    # Create a comprehensive test function
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
    
    # Create a helper function to check missing dependencies
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
    
    # Final message
    log_info "Bootstrap completed successfully!"
    log_info "Distribution: $distro ($pkg_manager)"
    echo ""
    log_info "=== Next Steps ==="
    log_info "1. Run 'source ~/.bashrc' to load the new bash configuration"
    log_info "2. Enter fish shell by typing: fish"
    log_info "3. Set fish as default shell (optional): chsh -s $(which fish)"
    log_info "4. In fish, run these commands to test:"
    log_info "   - test_install   # Check all installed tools"
    log_info "   - check_deps     # Check for missing dependencies"
    log_info "   - ponies         # Test the ponies function"
    log_info "   - moo           # Test cowsay with fortune"
    log_info ""
    log_info "5. Compile Vim from source (system test):"
    log_info "   - bash -c 'source ~/.bash_functions && install_vim'"
    log_info "   - bash -c 'source ~/.bash_functions && install_ycm'"
    
    if [[ "$pkg_manager" == "pacman" ]]; then
        log_info ""
        log_info "Note: You may need to restart your terminal for AUR helper to be available"
    fi
    
    # Environment variables reminder
    echo ""
    log_info "=== Environment Variables to Set ==="
    log_info "Add these to your fish config if needed:"
    log_info "  set -Ux HF_TOKEN 'your-huggingface-token'"
    log_info "  set -Ux CEREBRAS_API_KEY 'your-cerebras-key'"
    log_info "  set -Ux GHCR_TOKEN 'your-github-container-token'"
    log_info "  set -Ux DISCOGS_TOKEN 'your-discogs-token'"
    
    # Check what's installed
    echo ""
    log_info "=== Installation Summary ==="
    command -v fish &>/dev/null && log_info "✓ Fish shell installed" || log_error "✗ Fish shell NOT installed"
    command -v eza &>/dev/null && log_info "✓ eza (ls replacement) installed" || log_warn "✗ eza NOT installed (using ls fallback)"
    command -v starship &>/dev/null && log_info "✓ Starship prompt installed" || log_warn "✗ Starship NOT installed"
    command -v zoxide &>/dev/null && log_info "✓ Zoxide installed" || log_warn "✗ Zoxide NOT installed"
    command -v fzf &>/dev/null && log_info "✓ FZF installed" || log_warn "✗ FZF NOT installed"
    command -v fnm &>/dev/null && log_info "✓ FNM installed" || log_warn "✗ FNM NOT installed"
    command -v pyenv &>/dev/null && log_info "✓ pyenv installed" || log_warn "✗ pyenv NOT installed"
    command -v cowsay &>/dev/null && log_info "✓ Cowsay installed" || log_warn "✗ Cowsay NOT installed"
    command -v ponysay &>/dev/null && log_info "✓ Ponysay installed" || log_warn "✗ Ponysay NOT installed (fallback available)"
    command -v colordiff &>/dev/null && log_info "✓ Colordiff installed" || log_warn "✗ Colordiff NOT installed"
    command -v cwebp &>/dev/null && log_info "✓ WebP tools installed" || log_warn "✗ WebP tools NOT installed"
    command -v xz &>/dev/null && log_info "✓ XZ utils installed" || log_warn "✗ XZ utils NOT installed"
    command -v fortune &>/dev/null && log_info "✓ Fortune installed" || log_warn "✗ Fortune NOT installed"
    command -v yt-dlp &>/dev/null && log_info "✓ yt-dlp installed" || log_warn "✗ yt-dlp NOT installed"
    command -v ffmpeg &>/dev/null && log_info "✓ FFmpeg installed" || log_warn "✗ FFmpeg NOT installed"
    command -v podman &>/dev/null && log_info "✓ Podman installed" || log_warn "✗ Podman NOT installed"
    command -v go &>/dev/null && log_info "✓ Go installed" || log_warn "✗ Go NOT installed"
    command -v cargo &>/dev/null && log_info "✓ Rust/Cargo installed" || log_warn "✗ Rust/Cargo NOT installed"
    command -v node &>/dev/null && log_info "✓ Node.js installed" || log_warn "✗ Node.js NOT installed"
    command -v vim &>/dev/null && log_warn "⚠️ Vim found (should be compiled from source)" || log_info "✓ Vim not installed (will compile from source)"
    
    echo ""
    log_info "==========================="
}

# Run main function
main "$@"
