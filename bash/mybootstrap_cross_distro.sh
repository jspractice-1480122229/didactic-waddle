#!/bin/bash

# ==============================================================================
# FILE 1: mybootstrap_cross_distro.sh
#
# This is the main, master script. It detects the OS, installs packages,
# downloads the standalone helper scripts from the /scripts/ directory,
# and generates the simple shell configuration files that call them.
# Ponysay has been removed and is now an optional, separate install.
# ==============================================================================

# Cross-distro bootstrap script v3.6 (Ponysay Optional)
# Installs core environment; ponysay is now in a separate script.
# Version: 3.6

set -euo pipefail

# --- Logging functions and other helpers ---
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

# ⚡️ RUN-ABLE - Better error handling
setup_additional_repos() {
    local pkg_manager="$1"
    log_info "Setting up additional repositories..."

    case "$pkg_manager" in
        "apt")
            # Test internet connectivity first
            if ! curl -s --connect-timeout 5 https://packages.microsoft.com >/dev/null; then
                log_error "Cannot reach package repositories. Check internet connection."
                return 1
            fi

            # Verify each step
            sudo apt update || { log_error "Failed to update package lists"; return 1; }
            sudo apt install -y curl gpg apt-transport-https || { log_error "Failed to install repo dependencies"; return 1; }

            # Add repos with verification
            if ! curl -fsSL https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | sudo gpg --dearmor -o /usr/share/keyrings/vscodium-archive-keyring.gpg; then
                log_error "Failed to add VSCodium repository key"
                return 1
            fi
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
    log_info "Bootstrap v3.6 (Ponysay Optional) starting..."
    local pkg_manager
    pkg_manager=$(detect_distro)
    log_info "Detected package manager: $pkg_manager"

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
            dev_packages=("python3" "python3-pip" "golang" "nodejs" "npm" "codium" "microsoft-edge-stable")
            shell_packages=("fzf" "podman" "podman-compose")
            util_packages=("colordiff" "fortune-mod" "uuid-runtime" "unrar" "p7zip-full")
            python_build_deps=("libssl-dev" "libncurses-dev" "libsqlite3-dev" "libreadline-dev" "tk-dev" "libgdbm-dev" "libdb-dev" "libbz2-dev" "libexpat1-dev" "liblzma-dev" "zlib1g-dev" "libffi-dev")
            ;;
        "dnf")
            media_packages=("yt-dlp" "ffmpeg" "lame" "ghostscript" "libwebp-tools" "ImageMagick" "jpegoptim" "cowsay" "perl-Image-ExifTool")
            dev_packages=("python3" "python3-pip" "golang" "nodejs" "npm" "codium" "microsoft-edge-stable")
            shell_packages=("fzf" "podman" "podman-compose" "starship")
            util_packages=("colordiff" "fortune-mod" "util-linux" "unrar" "p7zip")
            python_build_deps=("openssl-devel" "ncurses-devel" "sqlite-devel" "readline-devel" "tk-devel" "gdbm-devel" "libdb-devel" "bzip2-devel" "expat-devel" "xz-devel" "zlib-devel" "libffi-devel")
            ;;
        "pacman")
            media_packages=("yt-dlp" "ffmpeg" "lame" "ghostscript" "libwebp" "imagemagick" "jpegoptim" "cowsay" "perl-image-exiftool")
            dev_packages=("python" "python-pip" "go" "nodejs" "npm" "pyenv")
            shell_packages=("fzf" "podman" "podman-compose" "starship" "zoxide" "eza")
            util_packages=("colordiff" "fortune-mod")
            python_build_deps=("openssl" "ncurses" "sqlite" "readline" "tk" "gdbm" "db" "bzip2" "expat" "xz" "zlib" "libffi")
            aur_packages=("microsoft-edge-stable" "vscodium")
            ;;
        "zypper")
            media_packages=("yt-dlp" "ffmpeg" "lame" "ghostscript" "libwebp-tools" "ImageMagick" "jpegoptim" "cowsay" "exiftool")
            dev_packages=("python3" "python3-pip" "go" "nodejs" "npm")
            shell_packages=("fzf" "podman" "podman-compose")
            util_packages=("colordiff" "fortune" "unrar" "p7zip")
            python_build_deps=("openssl-devel" "ncurses-devel" "sqlite3-devel" "readline-devel" "tk-devel" "gdbm-devel" "libdb-4_8-devel" "libbz2-devel" "libexpat-devel" "liblzma-devel" "zlib-devel" "libffi-devel")
            ;;
    esac

    local all_packages=("${core_packages[@]}" "${media_packages[@]}" "${dev_packages[@]}" "${util_packages[@]}" "${shell_packages[@]}" "${python_build_deps[@]}")
    log_info "Installing main packages..."
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

    if [[ -f "${HOME}/.bashrc" ]]; then
        local timestamp; timestamp=$(date +%Y%m%d_%H%M%S)
        log_info "Backing up existing .bashrc to .bashrc.backup_${timestamp}"
        mv "${HOME}/.bashrc" "${HOME}/.bashrc.backup_${timestamp}"
    fi

    log_info "Generating new .bashrc..."
    cat > "${HOME}/.bashrc" << 'EOL'
# ~/.bashrc: generated by bootstrap script.
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.pyenv/bin:$PATH"
if [ -f ~/.bash_aliases ]; then . ~/.bash_aliases; fi
if [ -f ~/.bash_functions ]; then . ~/.bash_functions; fi
if [ -f ~/.bash_personal ]; then . ~/.bash_personal; fi
if command -v pyenv 1>/dev/null 2>&1; then eval "$(pyenv init -)"; fi
if command -v fnm 1>/dev/null 2>&1; then eval "$(fnm env --use-on-cd)"; fi
EOL

    log_info "Generating new .bash_aliases..."
    cat > "${HOME}/.bash_aliases" << 'EOL'
# ~/.bash_aliases: generated by bootstrap script.
alias rm='rm -iv'
alias cp='cp -iv'
alias mv='mv -iv'
alias ..='cd ..'
alias ...='cd ../..'
if command -v eza &>/dev/null; then
    alias ls='eza --icons'
    alias ll='eza -l --icons'
    alias la='eza -la --icons'
else
    alias ls='ls -F --color=auto'
    alias ll='ls -alF --color=auto'
fi
EOL

    log_info "Generating new .bash_functions..."
    cat > "${HOME}/.bash_functions" << 'EOL'
# ~/.bash_functions: generated by bootstrap script.
media() { bmedia "$@"; }
img() { bimg "$@"; }
sys() { bsys "$@"; }
fileops() { bfileops "$@"; }
utils() { butils "$@"; }
finder() { bfinder "$@"; }
archive() { barchive "$@"; }

install_vim() {
    echo "Installing Vim from source (cross-distro)..."
    local pkg_manager; local install_cmd; local dependencies
    if command -v apt &>/dev/null; then
        pkg_manager="apt"; install_cmd="sudo apt install -y"
        dependencies=("libncurses5-dev" "libgtk2.0-dev" "libatk1.0-dev" "python3-dev" "git" "build-essential" "cmake")
    elif command -v dnf &>/dev/null; then
        pkg_manager="dnf"; install_cmd="sudo dnf install -y"
        dependencies=("ncurses-devel" "gtk2-devel" "atk-devel" "python3-devel" "git" "gcc-c++" "make" "cmake")
    elif command -v pacman &>/dev/null; then
        pkg_manager="pacman"; install_cmd="sudo pacman -S --noconfirm --needed"
        dependencies=("ncurses" "gtk2" "atk" "python" "git" "base-devel" "cmake")
    else echo "Unsupported package manager." && return 1; fi
    echo "Installing build dependencies using $pkg_manager..."
    $install_cmd "${dependencies[@]}"
    local vim_src="$HOME/src/vim"
    [ ! -d "$vim_src" ] && git clone https://github.com/vim/vim.git "$vim_src"
    cd "$vim_src" || return 1
    git pull --rebase && make distclean
    ./configure --with-features=huge --enable-python3interp=yes --prefix=/usr/local
    make && sudo make install
    echo "Vim installation completed."
}
install_ycm() {
    echo "Installing YouCompleteMe dependencies (cross-distro)..."
    local pkg_manager; local install_cmd; local dependencies
    if command -v apt &>/dev/null; then
        pkg_manager="apt"; install_cmd="sudo apt install -y"
        dependencies=("mono-complete" "openjdk-17-jdk" "shellcheck" "golang" "nodejs" "npm")
    elif command -v dnf &>/dev/null; then
        pkg_manager="dnf"; install_cmd="sudo dnf install -y"
        dependencies=("mono-core" "java-17-openjdk-devel" "ShellCheck" "golang" "nodejs" "npm")
    elif command -v pacman &>/dev/null; then
        pkg_manager="pacman"; install_cmd="sudo pacman -S --noconfirm --needed"
        dependencies=("mono" "jdk17-openjdk" "shellcheck" "go" "nodejs" "npm")
    else echo "Unsupported package manager." && return 1; fi
    echo "Installing YCM dependencies using $pkg_manager..."
    $install_cmd "${dependencies[@]}"
    echo "Running YCM installation..."
    vim +PluginInstall +qall
    python3 "$HOME/.vim/bundle/YouCompleteMe/install.py" --all
    echo "YouCompleteMe setup completed."
}
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
        log_info "Installing fnm..."
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

    log_info "Bootstrap refactoring complete!"
    log_info "Shell configurations are now simple wrappers for standalone scripts."
    log_info "Please run 'source ~/.bashrc' or restart your terminal."
    log_info "To install ponysay, run the separate 'install_ponysay.sh' script."
}

main "$@"

# ==============================================================================
# FILE 2: install_ponysay.sh
#
# This is a new, standalone script for optionally installing ponysay.
# It first tries the system package manager and falls back to building from
# source with pyenv if the package is not found.
# ==============================================================================
#!/bin/bash
# Standalone script to install ponysay, with fallback to pyenv build.

set -euo pipefail

# --- Logging functions ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

detect_distro() {
    local pkg_manager=""
    if command -v apt &>/dev/null; then pkg_manager="apt";
    elif command -v dnf &>/dev/null; then pkg_manager="dnf";
    elif command -v pacman &>/dev/null; then pkg_manager="pacman";
    elif command -v zypper &>/dev/null; then pkg_manager="zypper";
    else echo "unknown" && return 1; fi
    echo "$pkg_manager"
}

install_from_source() {
    log_warn "Falling back to building from source with pyenv..."
    if ! command -v pyenv &>/dev/null; then
        log_error "pyenv not found. Please run the main bootstrap script first."
        exit 1
    fi

    local temp_dir; temp_dir=$(mktemp -d)
    trap 'log_info "Cleaning up temp directory..."; rm -rf "$temp_dir"' EXIT
    cd "$temp_dir" || return 1

    log_info "Cloning ponysay repository..."
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
            return 1
        fi
    else
        log_warn "Failed to clone ponysay repository"
        return 1
    fi
    cd "$HOME"
}

main() {
    if command -v ponysay &>/dev/null; then
        log_info "Ponysay is already installed."
        exit 0
    fi

    log_info "Attempting to install ponysay from package manager..."
    local pkg_manager
    pkg_manager=$(detect_distro)
    local install_success=false

    case "$pkg_manager" in
        "apt") sudo apt install -y ponysay && install_success=true ;;
        "dnf") sudo dnf install -y ponysay && install_success=true ;;
        "pacman") sudo pacman -S --noconfirm ponysay && install_success=true ;;
        "zypper") sudo zypper install -y ponysay && install_success=true ;;
        *) log_warn "Could not detect a supported package manager." ;;
    esac

    if [ "$install_success" = true ]; then
        log_info "Successfully installed ponysay from $pkg_manager."
    else
        log_warn "Could not install ponysay from package manager."
        install_from_source
    fi
}

main "$@"


# ==============================================================================
# FILE 3: scripts/bmedia
# ==============================================================================
#!/usr/bin/env bash
# Standalone script for media processing

if [ -z "$1" ]; then
    echo "Usage: bmedia [rip|audio|video|louder|compress|convert|play] [args]"
    exit 1
fi

operation="$1"; shift

safer_glob() {
    trap 'shopt -u nullglob' RETURN
    shopt -s nullglob
}

case "$operation" in
    rip) yt-dlp -f bestaudio --extract-audio --prefer-ffmpeg --audio-format m4a --embed-thumbnail --add-metadata -o '%(title)s.%(ext)s' "$@" ;;
    audio) yt-dlp -f bestaudio "$@" ;;
    video) yt-dlp -f best "$@" ;;
    louder)
        if [ -z "$1" ]; then echo "Usage: bmedia louder FILE.mp3"; exit 1; fi
        lame --scale 2 "$1" "/tmp/tmp_$$.mp3" && mv "/tmp/tmp_$$.mp3" "$1" ;;
    compress)
        output_dir="${2:-compressed}"; mkdir -p "$output_dir"
        for f in *.mp3; do [ -f "$f" ] && ffmpeg -n -i "$f" -ac 1 -ab 40k -ar 22050 "$output_dir/$f"; done ;;
    convert)
        format="${1:-mp3}"; output_dir="${format}_version"; mkdir -p "$output_dir"
        safer_glob
        for f in *.wav *.ogg *.flac; do
            ffmpeg -i "$f" -vn -ar 44100 -ac 2 -b:a 192k "$output_dir/${f%.*}.$format"
        done ;;
    play)
        dir="${1:-.}"; while IFS= read -r f; do ffplay -autoexit -nodisp "$f" >/dev/null 2>&1; done < <(find "$dir" -type f \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.wav" \) | shuf) ;;
    *) echo "Unknown operation: $operation" ;;
esac

# ==============================================================================
# FILE 4: scripts/bimg
# ==============================================================================
#!/usr/bin/env bash
# Standalone script for image processing

if [ -z "$1" ]; then
    echo "Usage: bimg [resize|clean|thumb|favicon] [args]"
    exit 1
fi

operation="$1"; shift

safer_glob() {
    trap 'shopt -u nullglob' RETURN
    shopt -s nullglob
}

case "$operation" in
    resize)
        width="${1:-800}"; quality="${2:-60}"
        safer_glob
        for f in *.jpg *.jpeg *.png *.gif *.bmp; do
            base="${f%.*}"
            magick "$f" -resize "${width}x>" -quality "$quality" "resized_${base}.webp"
        done ;;
    clean) for f in *.jpg; do [ -f "$f" ] && jpegoptim -pqt --strip-all "$f"; done ;;
    thumb)
        size="${1:-48x38}"
        for f in *.jpg; do [ -f "$f" ] && convert -sample "$size" "$f" "thumb_${f%.*}.jpg"; done ;;
    favicon)
        if [ -z "$1" ]; then echo "Usage: bimg favicon INPUT [OUTPUT]"; exit 1; fi
        output="${2:-favicon.ico}"
        magick convert "$1" -resize 16x16 -gravity center -crop 16x16+0+0 -flatten -colors 256 -background transparent "$output" ;;
    *) echo "Unknown operation: $operation" ;;
esac

# ==============================================================================
# FILE 5: scripts/bfileops
# ==============================================================================
#!/usr/bin/env bash
# Standalone script for file operations

if [ -z "$1" ]; then
    echo "Usage: bfileops [lowercase|duplicate|swap|random|clean|compress] [args]"
    exit 1
fi

operation="$1"; shift

case "$operation" in
    lowercase) for f in "$@"; do local new; new=$(echo "$f" | tr '[:upper:]' '[:lower:]'); if [ "$f" != "$new" ]; then mv -- "$f" "$new"; fi; done ;;
    duplicate)
        if [ -z "$1" ] || [ -z "$2" ]; then echo "Usage: bfileops duplicate FILE COUNT"; exit 1; fi
        for ((i=1; i<=$2; i++)); do cp "$1" "${i}${1}"; done ;;
    swap)
        if [ -z "$1" ] || [ -z "$2" ]; then echo "Usage: bfileops swap FILE1 FILE2"; exit 1; fi
        local tmp="/tmp/tmp_$$"; mv -- "$1" "$tmp"; mv -- "$2" "$1"; mv -- "$tmp" "$2" ;;
    random) if [ "$1" = "binary" ]; then dd if=/dev/urandom of="$2" bs="$3" count=1; else head -c "$2" </dev/urandom > "$1"; fi ;;
    clean)
        if [ -z "$1" ]; then echo "Usage: bfileops clean FILE"; exit 1; fi
        local tmp="/tmp/tmp_$$"; perl -nlwe 'tr/ //d; print if length' "$1" > "$tmp"; mv "$tmp" "$1" ;;
    compress)
        if [ -z "$1" ] || [ -z "$2" ]; then echo "Usage: bfileops compress INPUT.pdf OUTPUT.pdf"; exit 1; fi
        gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dNOPAUSE -dBATCH -dQUIET -sOutputFile="$2" "$1" ;;
    *) echo "Unknown operation: $operation" ;;
esac

# ==============================================================================
# FILE 6: scripts/bsys
# ==============================================================================
#!/usr/bin/env bash
# Standalone script for system management

if [ -z "$1" ]; then
    echo "Usage: bsys [search|install|upgrade] [args]"
    exit 1
fi

operation="$1"; shift
pkg_manager=""
if command -v pacman &>/dev/null; then pkg_manager="pacman";
elif command -v apt &>/dev/null; then pkg_manager="apt";
elif command -v dnf &>/dev/null; then pkg_manager="dnf";
elif command -v zypper &>/dev/null; then pkg_manager="zypper";
else echo "Unsupported package manager" && exit 1; fi

case "$operation" in
    search)
        case "$pkg_manager" in
            apt) apt search "$@" ;; pacman) pacman -Ss "$@" ;;
            dnf) dnf search "$@" ;; zypper) zypper search "$@" ;;
        esac ;;
    install)
        case "$pkg_manager" in
            apt) sudo apt update && sudo apt install -y "$@" ;;
            pacman) sudo pacman -S --noconfirm "$@" ;;
            dnf) sudo dnf install -y "$@" ;;
            zypper) sudo zypper install -y "$@" ;;
        esac ;;
    upgrade)
        case "$pkg_manager" in
            apt) sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove --purge -y ;;
            pacman) sudo pacman -Syu --noconfirm ;;
            dnf) sudo dnf upgrade --refresh -y && sudo dnf autoremove -y ;;
            zypper) sudo zypper refresh && sudo zypper update -y ;;
        esac ;;
    *) echo "Unknown operation: $operation" ;;
esac

# ==============================================================================
# FILE 7: scripts/butils
# ==============================================================================
#!/usr/bin/env bash
# Standalone script for utilities

if [ -z "$1" ]; then
    echo "Usage: butils [epoch|words|pony|guid|random|desktop|pid] [args]"
    exit 1
fi

operation="$1"; shift

case "$operation" in
    epoch) date --date="@$1" ;;
    words) fortune -l -n 145 | tr '[:lower:]' '[:upper:]' | tr ' ' '\n' | sed 's/[^A-Z]//g' | grep -E '.{5}' | sort -u | shuf ;;
    pony) if command -v ponysay &>/dev/null; then fortune | ponysay; elif command -v cowsay &>/dev/null; then fortune | cowsay; else fortune; fi ;;
    guid) local count="${1:-1}"; for ((i=1; i<=count; i++)); do uuidgen -r | tr '[:lower:]' '[:upper:]'; done ;;
    random) case "$1" in 3) echo $((100 + RANDOM % 900)) ;; 5) echo $((10000 + RANDOM % 90000)) ;; *) echo $RANDOM ;; esac ;;
    desktop) echo "Desktop: $XDG_CURRENT_DESKTOP / Session: $GDMSESSION" ;;
    pid) top -p "$(pgrep -d , "$1")" ;;
    *) echo "Unknown operation: $operation" ;;
esac

# ==============================================================================
# FILE 8: scripts/bfinder
# ==============================================================================
#!/usr/bin/env bash
# Standalone script for search functions

if [ -z "$1" ]; then
    echo "Usage: bfinder [name|exec|content] [args]"
    exit 1
fi

operation="$1"; shift

case "$operation" in
    name) find . -type f -iname "*$1*" -ls ;;
    exec) find . -type f -iname "*$1*" -exec "$@" {} \; ;;
    content)
        case_flag=""; pattern=""; ext="*"
        if [ "$1" = "-i" ]; then case_flag="-i"; shift; fi
        pattern="$1"; [ -n "$2" ] && ext="$2"
        find . -type f -name "$ext" -print0 | xargs -0 grep --color=always -sn "$case_flag" "$pattern" 2>/dev/null | more ;;
    *) echo "Unknown operation: $operation" ;;
esac

# ==============================================================================
# FILE 9: scripts/barchive
# ==============================================================================
#!/usr/bin/env bash
# Standalone script for archive functions

if [ -z "$1" ]; then
    echo "Usage: barchive [extract|encrypt|decrypt] [args]"
    exit 1
fi

operation="$1"; shift

extract_one() {
    case "$1" in
        *.tar.bz2) tar xjf "$1" ;; *.tar.gz) tar xzf "$1" ;; *.bz2) bunzip2 "$1" ;;
        *.rar) unrar x "$1" ;; *.gz) gunzip "$1" ;; *.tar) tar xf "$1" ;;
        *.tbz2) tar xjf "$1" ;; *.tgz) tar xzf "$1" ;; *.zip) unzip "$1" ;;
        *.Z) uncompress "$1" ;; *.7z) 7z x "$1" ;; *.xz) unxz "$1" ;;
        *) echo "Cannot extract $1"; return 1 ;;
    esac
}

case "$operation" in
    extract) extract_one "$1" ;;
    encrypt)
        if [ -z "$1" ] || [ -z "$2" ]; then echo "Usage: barchive encrypt INPUT OUTPUT"; exit 1; fi
        openssl des3 -salt -in "$1" -out "$2" ;;
    decrypt)
        if [ -z "$1" ] || [ -z "$2" ]; then echo "Usage: barchive decrypt INPUT OUTPUT"; exit 1; fi
        openssl des3 -d -in "$1" -out "$2" ;;
    *) echo "Unknown operation: $operation" ;;
esac
