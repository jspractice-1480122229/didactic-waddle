#!/usr/bin/env bash
# FILE: ~/.bash_functions
# Bash functions with feature parity to Fish configuration

#=============================================================
# NAVIGATION & FILE HELPERS
#=============================================================

# cd and ls combined
cs() {
    cd "$@" && ls
}

# Make directory and enter it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract any archive format
extract() {
    if [ -z "$1" ]; then
        echo "Usage: extract <archive_file>"
        return 1
    fi
    
    if [ ! -f "$1" ]; then
        echo "Error: $1 is not a valid file"
        return 1
    fi
    
    case "$1" in
        *.tar.bz2)   tar xjf "$1"    ;;
        *.tar.gz)    tar xzf "$1"    ;;
        *.bz2)       bunzip2 "$1"    ;;
        *.rar)       unrar x "$1"    ;;
        *.gz)        gunzip "$1"     ;;
        *.tar)       tar xf "$1"     ;;
        *.tbz2)      tar xjf "$1"    ;;
        *.tgz)       tar xzf "$1"    ;;
        *.zip)       unzip "$1"      ;;
        *.Z)         uncompress "$1" ;;
        *.7z)        7z x "$1"       ;;
        *.xz)        unxz "$1"       ;;
        *)           echo "Cannot extract $1" && return 1 ;;
    esac
}

# Quick backup with timestamp
backup() {
    if [ -z "$1" ]; then
        echo "Usage: backup <file_or_directory>"
        return 1
    fi
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local target="$1"
    
    if [ -e "$target" ]; then
        cp -r "$target" "${target}.backup_${timestamp}"
        echo "✅ Backed up to ${target}.backup_${timestamp}"
    else
        echo "❌ $target does not exist"
        return 1
    fi
}

#=============================================================
# MEDIA PROCESSING FUNCTIONS
#=============================================================

media() {
    local operation="$1"
    shift
    
    case "$operation" in
        rip)
            # Download best audio from YouTube with metadata
            yt-dlp -f bestaudio --extract-audio --prefer-ffmpeg \
                --audio-format m4a --embed-thumbnail --add-metadata \
                --parse-metadata "comment:%(webpage_url)s" \
                -o '%(title)s.%(ext)s' "$@"
            ;;
        audio)
            # Download best audio only
            yt-dlp -f bestaudio "$@"
            ;;
        video)
            # Download best quality video
            yt-dlp -f best "$@"
            ;;
        louder)
            # Increase MP3 volume
            if [ -z "$1" ]; then
                echo "Usage: media louder FILE.mp3"
                return 1
            fi
            lame --scale 2 "$1" "/tmp/tmp_$$.mp3"
            mv "/tmp/tmp_$$.mp3" "$1"
            ;;
        compress)
            # Compress MP3s for podcasts
            local output_dir="${2:-compressed}"
            mkdir -p "$output_dir"
            for f in *.mp3; do
                [ -f "$f" ] || continue
                ffmpeg -n -i "$f" -metadata genre="Podcast" -ac 1 -ab 40k \
                    -ar 22050 -id3v2_version 3 -write_id3v1 1 -vsync 2 \
                    "$output_dir/$f"
            done
            ;;
        convert)
            # Audio format conversion
            local format="${1:-mp3}"
            local output_dir="${format}_version"
            mkdir -p "$output_dir"
            
            # Use shell globbing properly in Bash
            shopt -s nullglob  # Don't iterate if no matches
            for f in *.wav *.ogg *.flac; do
                [ -f "$f" ] || continue
                local base="${f%.*}"
                case "$format" in
                    mp3)  ffmpeg -i "$f" -vn -ar 44100 -ac 2 -b:a 192k "$output_dir/${base}.mp3" ;;
                    m4a)  ffmpeg -i "$f" -c:a aac -b:a 192k "$output_dir/${base}.m4a" ;;
                    *)    echo "Unsupported format: $format" && return 1 ;;
                esac
            done
            shopt -u nullglob  # Reset to default
            ;;
        play)
            # Play random audio files
            local dir="${1:-.}"
            while IFS= read -r f; do
                ffplay -autoexit -nodisp "$f" >/dev/null 2>&1
            done < <(find "$dir" -type f \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.wav" \) | shuf)
            ;;
        *)
            echo "Usage: media [rip|audio|video|louder|compress|convert|play] [args]"
            ;;
    esac
}

#=============================================================
# IMAGE PROCESSING FUNCTIONS
#=============================================================

img() {
    local operation="$1"
    shift
    
    case "$operation" in
        resize)
            # Resize images to max width
            local width="${1:-800}"
            local quality="${2:-60}"
            
            # Use shell globbing properly in Bash
            shopt -s nullglob  # Don't iterate if no matches
            for f in *.jpg *.jpeg *.png *.gif *.bmp; do
                [ -f "$f" ] || continue
                local base="${f%.*}"
                local ext="${f##*.}"
                
                magick "$f" -resize "${width}x>" -quality "$quality" "/tmp/tmp_$.$ext"
                cwebp -q "$quality" -m 6 -mt "/tmp/tmp_$.$ext" -o "resized_${base}.webp"
                rm "/tmp/tmp_$.$ext"
            done
            shopt -u nullglob  # Reset to default
            ;;
        clean)
            # Clean JPEG metadata
            for f in *.jpg; do
                [ -f "$f" ] || continue
                jpegoptim -pqt --strip-all "$f"
            done
            ;;
        thumb)
            # Create thumbnails
            local size="${1:-48x38}"
            
            for f in *.jpg; do
                [ -f "$f" ] || continue
                local base="${f%.*}"
                convert -sample "$size" "$f" "thumb_${base}.jpg"
                jpegoptim -pqt --strip-all "thumb_${base}.jpg"
            done
            ;;
        favicon)
            # Create favicon
            if [ -z "$1" ]; then
                echo "Usage: img favicon INPUT [OUTPUT]"
                return 1
            fi
            local output="${2:-favicon.ico}"
            magick convert "$1" -resize 16x16 -gravity center -crop 16x16+0+0 \
                -flatten -colors 256 -background transparent "$output"
            ;;
        *)
            echo "Usage: img [resize|clean|thumb|favicon] [args]"
            ;;
    esac
}

#=============================================================
# FILE OPERATIONS
#=============================================================

fileops() {
    local operation="$1"
    shift
    
    case "$operation" in
        lowercase)
            # Convert filenames to lowercase
            for f in "$@"; do
                local new=$(echo "$f" | tr '[:upper:]' '[:lower:]')
                if [ "$f" != "$new" ]; then
                    mv -- "$f" "$new"
                fi
            done
            ;;
        duplicate)
            # Duplicate files
            if [ -z "$1" ] || [ -z "$2" ]; then
                echo "Usage: fileops duplicate FILE COUNT"
                return 1
            fi
            local count="$2"
            for ((i=1; i<=count; i++)); do
                cp "$1" "${i}${1}"
            done
            ;;
        swap)
            # Swap two files
            if [ -z "$1" ] || [ -z "$2" ]; then
                echo "Usage: fileops swap FILE1 FILE2"
                return 1
            fi
            local tmp="/tmp/tmp_$$"
            mv -- "$1" "$tmp"
            mv -- "$2" "$1"
            mv -- "$tmp" "$2"
            ;;
        random)
            # Create random data files
            if [ "$1" = "binary" ]; then
                dd if=/dev/urandom of="$2" bs="$3" count=1
            else
                head -c "$2" </dev/urandom > "$1"
            fi
            ;;
        clean)
            # Remove blanks
            if [ -z "$1" ]; then
                echo "Usage: fileops clean FILE"
                return 1
            fi
            local tmp="/tmp/tmp_$$"
            perl -nlwe 'tr/ //d; print if length' "$1" > "$tmp"
            mv "$tmp" "$1"
            ;;
        compress)
            # Compress PDF
            if [ -z "$1" ] || [ -z "$2" ]; then
                echo "Usage: fileops compress INPUT.pdf OUTPUT.pdf"
                return 1
            fi
            gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dNOPAUSE \
               -dBATCH -dQUIET -sOutputFile="$2" "$1"
            ;;
        *)
            echo "Usage: fileops [lowercase|duplicate|swap|random|clean|compress] [args]"
            ;;
    esac
}

#=============================================================
# SYSTEM MANAGEMENT FUNCTIONS
#=============================================================

sys() {
    local operation="$1"
    shift
    
    # Detect package manager
    local pkg_manager
    if command -v pacman &>/dev/null; then
        pkg_manager="pacman"
    elif command -v apt &>/dev/null; then
        pkg_manager="apt"
    elif command -v dnf5 &>/dev/null; then
        pkg_manager="dnf5"
    elif command -v dnf &>/dev/null; then
        pkg_manager="dnf"
    elif command -v zypper &>/dev/null; then
        pkg_manager="zypper"
    else
        pkg_manager="unknown"
    fi
    
    case "$operation" in
        search)
            # Search for packages
            case "$pkg_manager" in
                apt)      apt search "$1" ;;
                pacman)   pacman -Ss "$1" ;;
                dnf*)     $pkg_manager search "$1" ;;
                zypper)   zypper search "$1" ;;
                *)        echo "Unsupported package manager" ;;
            esac
            ;;
        install)
            # Install packages
            case "$pkg_manager" in
                apt)      sudo apt update && sudo apt install -y "$@" && sudo apt clean ;;
                pacman)   sudo pacman -S --noconfirm "$@" && sudo pacman -Scc --noconfirm ;;
                dnf*)     sudo $pkg_manager install -y "$@" && sudo $pkg_manager clean all ;;
                zypper)   sudo zypper install -y "$@" && sudo zypper clean --all ;;
                *)        echo "Unsupported package manager" ;;
            esac
            ;;
        upgrade)
            # System upgrade
            case "$pkg_manager" in
                apt)
                    sudo apt update
                    sudo apt full-upgrade -y
                    sudo apt autoremove --purge -y
                    sudo apt clean
                    ;;
                pacman)
                    sudo pacman -Syu --noconfirm
                    orphans=$(pacman -Qtdq 2>/dev/null)
                    [ -n "$orphans" ] && sudo pacman -Rns --noconfirm $orphans
                    sudo pacman -Scc --noconfirm
                    ;;
                dnf*)
                    sudo $pkg_manager upgrade --refresh -y
                    sudo $pkg_manager autoremove -y
                    sudo $pkg_manager clean all
                    ;;
                zypper)
                    sudo zypper refresh
                    sudo zypper update -y
                    sudo zypper remove -u
                    sudo zypper clean --all
                    ;;
                *)
                    echo "Unsupported package manager"
                    ;;
            esac
            ;;
        *)
            echo "Usage: sys [search|install|upgrade] [args]"
            ;;
    esac
}

#=============================================================
# UTILITY FUNCTIONS
#=============================================================

utils() {
    local operation="$1"
    shift
    
    case "$operation" in
        epoch)
            # Convert epoch to readable date
            date --date="@$1"
            ;;
        words)
            # Generate word list
            fortune -l -n 145 | tr '[:lower:]' '[:upper:]' | \
                tr ' ' '\n' | sed 's/[^A-Z]//g' | grep -E '.{5}' | sort -u | shuf
            ;;
        pony)
            # Pony say
            if command -v ponysay &>/dev/null; then
                fortune | ponysay
            elif command -v cowsay &>/dev/null; then
                fortune | cowsay
            else
                fortune
            fi
            ;;
        guid)
            # Generate GUIDs
            local count="${1:-1}"
            for ((i=1; i<=count; i++)); do
                uuidgen -r | tr '[:lower:]' '[:upper:]'
            done
            ;;
        random)
            # Random numbers
            case "$1" in
                3)  echo $((100 + RANDOM % 900)) ;;
                5)  echo $((10000 + RANDOM % 90000)) ;;
                *)  echo $RANDOM ;;
            esac
            ;;
        desktop)
            # Show desktop info
            echo "Desktop: $XDG_CURRENT_DESKTOP"
            echo "Session: $GDMSESSION"
            ;;
        pid)
            # Show process info
            top -p $(pgrep -d , "$1")
            ;;
        *)
            echo "Usage: utils [epoch|words|pony|guid|random|desktop|pid] [args]"
            ;;
    esac
}

#=============================================================
# SEARCH FUNCTIONS
#=============================================================

finder() {
    local operation="$1"
    shift
    
    case "$operation" in
        name)
            # Find by name
            find . -type f -iname "*$1*" -ls
            ;;
        exec)
            # Find and execute
            local pattern="$1"
            shift
            find . -type f -iname "*$pattern*" -exec "$@" {} \;
            ;;
        content)
            # Find by content
            local case_flag=""
            local pattern
            local ext="*"
            
            if [ "$1" = "-i" ]; then
                case_flag="-i"
                shift
            fi
            
            pattern="$1"
            [ -n "$2" ] && ext="$2"
            
            find . -type f -name "$ext" -print0 | \
                xargs -0 grep --color=always -sn $case_flag "$pattern" 2>/dev/null | more
            ;;
        *)
            echo "Usage: finder [name|exec|content] [args]"
            ;;
    esac
}

#=============================================================
# ARCHIVE FUNCTIONS
#=============================================================

archive() {
    local operation="$1"
    shift
    
    case "$operation" in
        extract)
            # Extract archives
            extract "$1"  # Use the extract function defined above
            ;;
        encrypt)
            # Encrypt file
            if [ -z "$1" ] || [ -z "$2" ]; then
                echo "Usage: archive encrypt INPUT OUTPUT"
                return 1
            fi
            openssl des3 -salt -in "$1" -out "$2"
            ;;
        decrypt)
            # Decrypt file
            if [ -z "$1" ] || [ -z "$2" ]; then
                echo "Usage: archive decrypt INPUT OUTPUT"
                return 1
            fi
            openssl des3 -d -in "$1" -out "$2"
            ;;
        *)
            echo "Usage: archive [extract|encrypt|decrypt] [args]"
            ;;
    esac
}

#=============================================================
# VIM INSTALLATION FUNCTIONS (System Compilation Test)
#=============================================================

install_vim() {
    echo "Installing/updating Vim from source..."
    
    # Install dependencies
    sudo apt update && \
    sudo apt install -y \
        libncurses5-dev libgtk2.0-dev libatk1.0-dev \
        libcairo2-dev libx11-dev libxpm-dev libxt-dev \
        python3-dev ruby-dev lua5.3 liblua5.3-dev \
        libperl-dev git build-essential cmake clang \
        libclang-dev
    
    # Clean existing installations
    sudo apt purge -y vim vim-runtime gvim vim-tiny vim-common vim-gui-common vim-nox
    sudo apt autoremove -y
    
    # Set up source directory
    local vim_src="$HOME/src/vim"
    [ ! -d "$vim_src" ] && git clone https://github.com/vim/vim.git "$vim_src"
    
    # Update repository
    cd "$vim_src" || return 1
    git pull --rebase
    git submodule update --init --recursive
    
    # Clean build
    make clean distclean
    
    # Configure with optimal settings
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
    
    # Build and install
    make && sudo make install
    
    # Set as default editor
    sudo update-alternatives --install /usr/bin/editor editor /usr/local/bin/vim 1
    sudo update-alternatives --set editor /usr/local/bin/vim
    sudo update-alternatives --install /usr/bin/vi vi /usr/local/bin/vim 1
    sudo update-alternatives --set vi /usr/local/bin/vim
    
    echo "Vim installation completed."
}

install_ycm() {
    echo "Setting up YouCompleteMe..."
    
    # Install dependencies
    sudo apt install -y \
        mono-complete openjdk-17-jdk \
        shellcheck golang nodejs npm
    
    # Update npm
    npm install -g npm@latest
    
    # Install/update YCM
    local ycm_dir="$HOME/.vim/bundle/YouCompleteMe"
    if [ ! -d "$ycm_dir" ]; then
        vim +PluginInstall +qall
    else
        vim +PluginUpdate +qall
    fi
    
    # Build YCM
    cd "$ycm_dir" || return 1
    python3 install.py --all
    
    echo "YouCompleteMe setup completed."
}

install_warzone2100() {
    cd "$HOME/src" || return 1
    local wz_src="$HOME/src/warzone2100"
    
    # Clone or update repository
    if [ ! -d "$wz_src" ]; then
        git clone --recurse-submodules --depth 1 \
            https://github.com/Warzone2100/warzone2100 "$wz_src"
    fi
    
    # Build and install
    cd "$wz_src" || return 1
    git remote update -p
    git merge --ff-only '@{u}'
    git submodule update --init --recursive
    
    sudo ./get-dependencies_linux.sh ubuntu build-all
    
    mkdir -p build
    cd build || return 1
    cmake \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DCMAKE_INSTALL_PREFIX:PATH=/opt/warzone2100-latest \
        -GNinja ..
    
    sudo cmake --build . --target install
    cd || return
}

#=============================================================
# BACKWARD COMPATIBILITY ALIASES
#=============================================================

# Media function shortcuts
ripytsong() { media rip "$@"; }
pullytaudio() { media audio "$@"; }
bestytclip() { media video "$@"; }
louder() { media louder "$@"; }
wav2mp3() { media convert mp3; }
ogg2mp3() { media convert mp3; }
shrinkMP3() { media compress "$@"; }
toonzes() { media play "$@"; }

# Image function shortcuts
maxwidthvar() { img resize "$@"; }
jpgclearmeta() { img clean; }
jpgtiny() { img thumb; }
jpegthumbs() { img thumb 150x100; }
favico() { img favicon "$@"; }

# File operation shortcuts
lowercase() { fileops lowercase "$@"; }
dupe() { fileops duplicate "$@"; }
swap() { fileops swap "$@"; }
dummyfile() { fileops random "$1" "$2"; }
plugdummy() { fileops random "$2" "$1"; }
noblanks() { fileops clean "$@"; }
smushpdf() { fileops compress "$@"; }

# System shortcuts
tellme() { sys search "$@"; }
gimme() { sys install "$@"; }
iago() { sys upgrade; }

# Utility shortcuts
epoch() { utils epoch "$@"; }
wordlist() { utils words; }
ponies() { utils pony; }
guidmaker() { utils guid "$@"; }
3digit() { utils random 3; }
5digit() { utils random 5; }
wutdt() { utils desktop; }
gettoppid() { utils pid "$@"; }

# Search shortcuts
ff() { finder name "$@"; }
fe() { finder exec "$@"; }
fstr() { finder content "$@"; }

# Archive shortcuts
pfimpf() { archive extract "$@"; }
scramble() { archive encrypt "$@"; }
descramble() { archive decrypt "$@"; }

# Warzone shortcut
wz() { install_warzone2100; }

#=============================================================
# HELP FUNCTION
#=============================================================

function-help() {
    echo "🐚 Bash Functions Help"
    echo "====================="
    echo ""
    echo "Main Functions:"
    echo "  media [operation] - Audio/video processing"
    echo "  img [operation]   - Image processing"
    echo "  fileops [op]      - File operations"
    echo "  sys [operation]   - System management"
    echo "  utils [operation] - Utilities"
    echo "  finder [op]       - Search functions"
    echo "  archive [op]      - Archive operations"
    echo ""
    echo "System Tests:"
    echo "  install_vim       - Compile Vim from source"
    echo "  install_ycm       - Install YouCompleteMe"
    echo "  install_warzone2100 - Install Warzone 2100"
    echo ""
    echo "Quick Functions:"
    echo "  cs PATH          - cd and ls"
    echo "  mkcd PATH        - mkdir and cd"
    echo "  extract FILE     - Extract any archive"
    echo "  backup FILE      - Quick backup with timestamp"
    echo ""
    echo "Legacy Shortcuts:"
    echo "  ripytsong, pullytaudio, bestytclip"
    echo "  jpgclearmeta, jpgtiny, favico"
    echo "  tellme, gimme, iago"
    echo "  ponies, guidmaker, wordlist"
    echo ""
    echo "Type 'declare -F' to see all functions"
}

#=============================================================
# LOAD PERSONAL FUNCTIONS
#=============================================================

# Load personal functions if they exist
if [ -f ~/.bash_functions_personal ]; then
    source ~/.bash_functions_personal
fi
