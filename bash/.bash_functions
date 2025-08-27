#!/usr/bin/env bash
# FILE: ~/.bash_functions
# Bash functions with feature parity to Fish configuration

# Helper to make shell globbing safer in functions
safer_glob() {
    trap 'shopt -u nullglob' RETURN
    shopt -s nullglob
}

#=============================================================
# NAVIGATION & FILE HELPERS
#=============================================================
cs() { cd "$@" && ls; }
mkcd() { mkdir -p "$1" && cd "$1"; }
extract() {
    if [ -z "$1" ]; then echo "Usage: extract <archive_file>"; return 1; fi
    if [ ! -f "$1" ]; then echo "Error: $1 is not a valid file"; return 1; fi
    case "$1" in
        *.tar.bz2) tar xjf "$1" ;; *.tar.gz) tar xzf "$1" ;; *.bz2) bunzip2 "$1" ;;
        *.rar) unrar x "$1" ;; *.gz) gunzip "$1" ;; *.tar) tar xf "$1" ;;
        *.tbz2) tar xjf "$1" ;; *.tgz) tar xzf "$1" ;; *.zip) unzip "$1" ;;
        *.Z) uncompress "$1" ;; *.7z) 7z x "$1" ;; *.xz) unxz "$1" ;;
        *) echo "Cannot extract $1"; return 1 ;;
    esac
}
backup() {
    if [ -z "$1" ]; then echo "Usage: backup <file_or_directory>"; return 1; fi
    local timestamp; timestamp=$(date +%Y%m%d_%H%M%S)
    if [ -e "$1" ]; then
        cp -r "$1" "${1}.backup_${timestamp}"
        echo "✅ Backed up to ${1}.backup_${timestamp}"
    else echo "❌ $1 does not exist"; return 1; fi
}

#=============================================================
# MEDIA PROCESSING FUNCTIONS
#=============================================================
media() {
    local operation="$1"; shift
    case "$operation" in
        rip) yt-dlp -f bestaudio --extract-audio --prefer-ffmpeg --audio-format m4a --embed-thumbnail --add-metadata --parse-metadata "comment:%(webpage_url)s" -o '%(title)s.%(ext)s' "$@" ;;
        audio) yt-dlp -f bestaudio "$@" ;;
        video) yt-dlp -f best "$@" ;;
        louder)
            if [ -z "$1" ]; then echo "Usage: media louder FILE.mp3"; return 1; fi
            lame --scale 2 "$1" "/tmp/tmp_$$.mp3" && mv "/tmp/tmp_$$.mp3" "$1" ;;
        compress)
            local output_dir="${2:-compressed}"; mkdir -p "$output_dir"
            for f in *.mp3; do [ -f "$f" ] && ffmpeg -n -i "$f" -metadata genre="Podcast" -ac 1 -ab 40k -ar 22050 -id3v2_version 3 -write_id3v1 1 -vsync 2 "$output_dir/$f"; done ;;
        convert)
            local format="${1:-mp3}"; local output_dir="${format}_version"; mkdir -p "$output_dir"
            safer_glob
            for f in *.wav *.ogg *.flac; do
                local base="${f%.*}"
                case "$format" in
                    mp3) ffmpeg -i "$f" -vn -ar 44100 -ac 2 -b:a 192k "$output_dir/${base}.mp3" ;;
                    m4a) ffmpeg -i "$f" -c:a aac -b:a 192k "$output_dir/${base}.m4a" ;;
                    *) echo "Unsupported format: $format"; return 1 ;;
                esac
            done ;;
        play)
            local dir="${1:-.}"; while IFS= read -r f; do ffplay -autoexit -nodisp "$f" >/dev/null 2>&1; done < <(find "$dir" -type f \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.wav" \) | shuf) ;;
        *) echo "Usage: media [rip|audio|video|louder|compress|convert|play] [args]" ;;
    esac
}

#=============================================================
# IMAGE PROCESSING FUNCTIONS
#=============================================================
img() {
    local operation="$1"; shift
    case "$operation" in
        resize)
            local width="${1:-800}"; local quality="${2:-60}"
            safer_glob
            for f in *.jpg *.jpeg *.png *.gif *.bmp; do
                local base="${f%.*}"; local ext="${f##*.}"
                magick "$f" -resize "${width}x>" -quality "$quality" "/tmp/tmp_$.$ext"
                cwebp -q "$quality" -m 6 -mt "/tmp/tmp_$.$ext" -o "resized_${base}.webp"
                rm "/tmp/tmp_$.$ext"
            done ;;
        clean) for f in *.jpg; do [ -f "$f" ] && jpegoptim -pqt --strip-all "$f"; done ;;
        thumb)
            local size="${1:-48x38}"
            for f in *.jpg; do
                [ -f "$f" ] || continue; local base="${f%.*}"
                convert -sample "$size" "$f" "thumb_${base}.jpg"
                jpegoptim -pqt --strip-all "thumb_${base}.jpg"
            done ;;
        favicon)
            if [ -z "$1" ]; then echo "Usage: img favicon INPUT [OUTPUT]"; return 1; fi
            local output="${2:-favicon.ico}"
            magick convert "$1" -resize 16x16 -gravity center -crop 16x16+0+0 -flatten -colors 256 -background transparent "$output" ;;
        *) echo "Usage: img [resize|clean|thumb|favicon] [args]" ;;
    esac
}

#=============================================================
# FILE OPERATIONS
#=============================================================
fileops() {
    local operation="$1"; shift
    case "$operation" in
        lowercase) for f in "$@"; do local new; new=$(echo "$f" | tr '[:upper:]' '[:lower:]'); if [ "$f" != "$new" ]; then mv -- "$f" "$new"; fi; done ;;
        duplicate)
            if [ -z "$1" ] || [ -z "$2" ]; then echo "Usage: fileops duplicate FILE COUNT"; return 1; fi
            for ((i=1; i<=$2; i++)); do cp "$1" "${i}${1}"; done ;;
        swap)
            if [ -z "$1" ] || [ -z "$2" ]; then echo "Usage: fileops swap FILE1 FILE2"; return 1; fi
            local tmp="/tmp/tmp_$$"; mv -- "$1" "$tmp"; mv -- "$2" "$1"; mv -- "$tmp" "$2" ;;
        random) if [ "$1" = "binary" ]; then dd if=/dev/urandom of="$2" bs="$3" count=1; else head -c "$2" </dev/urandom > "$1"; fi ;;
        clean)
            if [ -z "$1" ]; then echo "Usage: fileops clean FILE"; return 1; fi
            local tmp="/tmp/tmp_$$"; perl -nlwe 'tr/ //d; print if length' "$1" > "$tmp"; mv "$tmp" "$1" ;;
        compress)
            if [ -z "$1" ] || [ -z "$2" ]; then echo "Usage: fileops compress INPUT.pdf OUTPUT.pdf"; return 1; fi
            gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dNOPAUSE -dBATCH -dQUIET -sOutputFile="$2" "$1" ;;
        *) echo "Usage: fileops [lowercase|duplicate|swap|random|clean|compress] [args]" ;;
    esac
}

#=============================================================
# SYSTEM MANAGEMENT FUNCTIONS
#=============================================================
sys() {
    local operation="$1"; shift
    local pkg_manager; if command -v pacman &>/dev/null; then pkg_manager="pacman"; elif command -v apt &>/dev/null; then pkg_manager="apt"; elif command -v dnf &>/dev/null; then pkg_manager="dnf"; elif command -v zypper &>/dev/null; then pkg_manager="zypper"; else pkg_manager="unknown"; fi
    case "$operation" in
        search) case "$pkg_manager" in apt) apt search "$1" ;; pacman) pacman -Ss "$1" ;; dnf) dnf search "$1" ;; zypper) zypper search "$1" ;; *) echo "Unsupported" ;; esac ;;
        install) case "$pkg_manager" in apt) sudo apt update && sudo apt install -y "$@" ;; pacman) sudo pacman -S --noconfirm "$@" ;; dnf) sudo dnf install -y "$@" ;; zypper) sudo zypper install -y "$@" ;; *) echo "Unsupported" ;; esac ;;
        upgrade) case "$pkg_manager" in apt) sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove --purge -y ;; pacman) sudo pacman -Syu --noconfirm ;; dnf) sudo dnf upgrade --refresh -y && sudo dnf autoremove -y ;; zypper) sudo zypper refresh && sudo zypper update -y ;; *) echo "Unsupported" ;; esac ;;
        *) echo "Usage: sys [search|install|upgrade] [args]" ;;
    esac
}

#=============================================================
# UTILITY FUNCTIONS
#=============================================================
utils() {
    local operation="$1"; shift
    case "$operation" in
        epoch) date --date="@$1" ;;
        words) fortune -l -n 145 | tr '[:lower:]' '[:upper:]' | tr ' ' '\n' | sed 's/[^A-Z]//g' | grep -E '.{5}' | sort -u | shuf ;;
        pony) if command -v ponysay &>/dev/null; then fortune | ponysay; elif command -v cowsay &>/dev/null; then fortune | cowsay; else fortune; fi ;;
        guid) local count="${1:-1}"; for ((i=1; i<=count; i++)); do uuidgen -r | tr '[:lower:]' '[:upper:]'; done ;;
        random) case "$1" in 3) echo $((100 + RANDOM % 900)) ;; 5) echo $((10000 + RANDOM % 90000)) ;; *) echo $RANDOM ;; esac ;;
        desktop) echo "Desktop: $XDG_CURRENT_DESKTOP / Session: $GDMSESSION" ;;
        pid) top -p "$(pgrep -d , "$1")" ;;
        *) echo "Usage: utils [epoch|words|pony|guid|random|desktop|pid] [args]" ;;
    esac
}

#=============================================================
# SEARCH FUNCTIONS
#=============================================================
finder() {
    local operation="$1"; shift
    case "$operation" in
        name) find . -type f -iname "*$1*" -ls ;;
        exec) find . -type f -iname "*$1*" -exec "$@" {} \; ;;
        content)
            local case_flag=""; local pattern; local ext="*"
            if [ "$1" = "-i" ]; then case_flag="-i"; shift; fi
            pattern="$1"; [ -n "$2" ] && ext="$2"
            find . -type f -name "$ext" -print0 | xargs -0 grep --color=always -sn $case_flag "$pattern" 2>/dev/null | more ;;
        *) echo "Usage: finder [name|exec|content] [args]" ;;
    esac
}

#=============================================================
# ARCHIVE FUNCTIONS
#=============================================================
archive() {
    local operation="$1"; shift
    case "$operation" in
        extract) extract "$1" ;;
        encrypt)
            if [ -z "$1" ] || [ -z "$2" ]; then echo "Usage: archive encrypt INPUT OUTPUT"; return 1; fi
            openssl des3 -salt -in "$1" -out "$2" ;;
        decrypt)
            if [ -z "$1" ] || [ -z "$2" ]; then echo "Usage: archive decrypt INPUT OUTPUT"; return 1; fi
            openssl des3 -d -in "$1" -out "$2" ;;
        *) echo "Usage: archive [extract|encrypt|decrypt] [args]" ;;
    esac
}

#=============================================================
# VIM/YCM INSTALLATION FUNCTIONS (System Compilation Test)
#=============================================================
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

#=============================================================
# BACKWARD COMPATIBILITY ALIASES
#=============================================================
ripytsong() { media rip "$@"; }
pullytaudio() { media audio "$@"; }
bestytclip() { media video "$@"; }
louder() { media louder "$@"; }
wav2mp3() { media convert mp3; }
ogg2mp3() { media convert mp3; }
shrinkMP3() { media compress "$@"; }
toonzes() { media play "$@"; }
maxwidthvar() { img resize "$@"; }
jpgclearmeta() { img clean; }
jpgtiny() { img thumb; }
jpegthumbs() { img thumb 150x100; }
favico() { img favicon "$@"; }
lowercase() { fileops lowercase "$@"; }
dupe() { fileops duplicate "$@"; }
swap() { fileops swap "$@"; }
dummyfile() { fileops random "$1" "$2"; }
plugdummy() { fileops random "$2" "$1"; }
noblanks() { fileops clean "$@"; }
smushpdf() { fileops compress "$@"; }
tellme() { sys search "$@"; }
gimme() { sys install "$@"; }
iago() { sys upgrade; }
epoch() { utils epoch "$@"; }
wordlist() { utils words; }
ponies() { utils pony; }
guidmaker() { utils guid "$@"; }
3digit() { utils random 3; }
5digit() { utils random 5; }
wutdt() { utils desktop; }
gettoppid() { utils pid "$@"; }
ff() { finder name "$@"; }
fe() { finder exec "$@"; }
fstr() { finder content "$@"; }
pfimpf() { archive extract "$@"; }
scramble() { archive encrypt "$@"; }
descramble() { archive decrypt "$@"; }
wz() { echo "install_warzone2100 is defined but should be run manually if needed."; }

#=============================================================
# HELP FUNCTION
#=============================================================
function-help() {
    echo "🐚 Bash Functions Help"
    echo "====================="; echo ""
    echo "Main Functions: media, img, fileops, sys, utils, finder, archive"
    echo "System Tests: install_vim, install_ycm"
    echo "Quick Functions: cs, mkcd, extract, backup"
    echo "Type 'declare -F' to see all defined functions"
}

#=============================================================
# LOAD PERSONAL FUNCTIONS
#=============================================================
if [ -f ~/.bash_personal ]; then source ~/.bash_personal; fi
