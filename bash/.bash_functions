# Functions
#-------------------------------------------------------------
# File & string-related functions:
#-------------------------------------------------------------

#######################
#                     #
# sound stuff section #
#                     #
#######################

#rip from youtube
function ripytsong() {
    youtube-dl --write-all-thumbnails --prefer-ffmpeg -x --audio-format mp3 --audio-quality 5 "$1"
}

#download best quality yt clip
dlbestytclip() {
    youtube-dl -F --no-check-certificate "$1" | grep \)$ | gawk -F\  '{print $1}' >0.tmp
    best=$(<0.tmp)
    ##\rm 0.tmp
    youtube-dl -f --no-check-certificate "$best" "$1"
}

#make MP3 files louder with Lame
function louder() {
    lame --scale 2 "$1" tmp.tmp
    swap tmp.tmp "$1"
    rm -fv tmp.tmp
}

##################
#                #
# MS SQL section #
#                #
##################

#restart MS SQL
function yesmssql() {
    systemctl list-units | grep --color mssql
    sudo systemctl restart mssql-server.service
    systemctl list-units | grep --color mssql
    echo "MS SQL (mssql-server) should read 'active'."
}

#stop MS SQL
function nomssql() {
    systemctl list-units | grep --color mssql
    sudo systemctl stop mssql-server.service
    echo "MS SQL (mssql-server) should be stopped and this next line is the prompt."
    systemctl list-units | grep --color mssql
}

#flac to 256k mp3
function flacto256kmp3() {
    OUTPUT_DIR=256kmp3
    if [ ! -d $OUTPUT_DIR ]; then
        mkdir $OUTPUT_DIR
    fi
    if [ ! -f $OUTPUT_DIR/"$i" ]; then
        for i in *; do
            echo "$i"
            #        echo "${i%.flac}.mp3"
            #    do ffmpeg -i "$i" -q:a 4 -id3v2_version 3 -write_id3v1 1 -n $OUTPUT_DIR/"${i%.flac}.mp3"
        done
    fi
}

#convert *nix epoch time to regular
function epoch() {
    date --date=@"$1"
}

# shrinky PDFy
teenypdf() {
    gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dNOPAUSE -dBATCH -dQUIET -sOutputFile="$2" "$1"
}

# knocking other users off the system, for work
function bumpothers() {
    sudo pkill -KILL -u steby
    sudo pkill -KILL -u jeny
    sudo pkill -KILL -u pia
}

#****************************************#
#         MajorSpoilersShrinkMP3         #
#****************************************#
function MajorSpoilersShrinkMP3() {
    OUTPUT_DIR=compressed
    if [ ! -d $OUTPUT_DIR ]; then
        mkdir $OUTPUT_DIR
    fi
    if [ ! -f $OUTPUT_DIR/"$i" ]; then
        for i in *.mp3; do
            ffmpeg -i "$i" -metadata genre="Podcast" -metadata encoded_by="ffmpeg version 3.3.4-2" -metadata copyright="2006-2018 Major Spoilers Entertainment, LLC." -ac 1 -ab 40k -ar 22050 -id3v2_version 3 -write_id3v1 1 -vsync 2 -n $OUTPUT_DIR/"$i"
        done
    fi
}

#aacto128kmp3
function aacto128kmp3() {
    OUTPUT_DIR=aacto128kmp3
    if [ ! -d $OUTPUT_DIR ]; then
        mkdir $OUTPUT_DIR
    fi
    if [ ! -f $OUTPUT_DIR/"$i" ]; then
        for i in *.aac; do
            ffmpeg -i "$i" -c:a libmp3lame -ac 2 -q:a 1 -id3v2_version 3 -write_id3v1 1 -vsync 2 -n $OUTPUT_DIR/"${i%.aac}.mp3"
        done
    fi
}

function mp42webm() {
    FILE="$1"
    ffmpeg -i "${FILE}" -f webm -c:v libvpx -b:v 1M -acodec libvorbis -y "${FILE%.mp4}.webm"
}

#Converty .mkv to mp3
function mkv2mp3() {
    find . -type f -name "*.mkv" -exec bash -c 'FILE="$1"; ffmpeg -i "${FILE}" -vn -c:a libmp3lame -y "${FILE%.mkv}.mp3";' _ '{}' \;
}

#random word list
function wordlist() {
    fortune -l -n 145 | gawk '{print toupper($0)}' | sed -r 's|\ |\n|g' | sed 's|\W||g' | sed -e '/.\{5\}/!d' | sort -u | shuf
}

#PONIES!!!
function ponies() {
    #    fortuna | awk '{print toupper($0)}' | ponythink -b unicode
    fortuna | ponythink -b unicode
}

#Convert .webm to 192k bitrate .mp3 files
function webm2mp3() {
    OUTPUT_DIR=mp3version
    if [ ! -d $OUTPUT_DIR ]; then
        mkdir $OUTPUT_DIR
    fi
    for FILE in *.webm; do
        #            filename=$(basename "$FILE")
        #            extension="${filename##*.}"
        #            filename="${filename%.*}"
        echo -e "Processing video '\e[32m$FILE\e[0m'"
        ffmpeg -n -i "${FILE}" -metadata encoded_by="Processed by Zeranoe FFmpeg builds for Windows, ffmpeg-v.N-82759-g1f5630a" -f mp3 -acodec libmp3lame -ab 192k -ar 44100 -id3v2_version 3 -write_id3v1 1 -vsync 2 $OUTPUT_DIR/"${FILE%.webm}.mp3"
    done
}
#Convert .aiff to 192k bitrate .mp3 files
function aiff2mp3() {
    OUTPUT_DIR=mp3version
    if [ ! -d $OUTPUT_DIR ]; then
        mkdir $OUTPUT_DIR
    fi
    for i in *.aiff; do
        ffmpeg -n -i "$i" -metadata encoded_by="Processed by Zeranoe FFmpeg builds for Windows, ffmpeg-v.N-82759-g1f5630a" -f mp3 -acodec libmp3lame -ab 192k -ar 44100 -id3v2_version 3 -write_id3v1 1 -vsync 2 $OUTPUT_DIR/"${i%.aiff}.mp3"
    done
}

#Make random, dummy files
function dummyfile() {
    dd if=/dev/zero of="$1" bs="$2" count=1
    randumb | cat >>"$1"
}

#history search
function hs() { history | grep "$1"; }

#GUID maker
function guidmaker() {
    a="$1"
    while [ "$a" -gt 0 ]; do
        uuidgen -r | awk '{print toupper($0)}'
        (("a-=1"))
    done
}

#5 digit random integer
function 5digit() {
    FLOOR=10000
    fivedigit=0
    while [ "$fivedigit" -le $FLOOR ]; do
        fivedigit=$RANDOM
    done
    echo "$fivedigit"
    echo
}

#Make all MP3 files in current folder shrink
function shrinkMP3() {
    OUTPUT_DIR=compressed
    if [ ! -d $OUTPUT_DIR ]; then
        mkdir $OUTPUT_DIR
    fi
    for i in *.mp3; do
        ffmpeg -n -i "$i" -metadata genre="Podcast" -metadata encoded_by="Processed by Zeranoe FFmpeg builds for Windows, ffmpeg-v.N-79107-g30d1213" -ac 1 -ab 40k -ar 22050 -id3v2_version 3 -write_id3v1 1 -vsync 2 "$OUTPUT_DIR"/"$i"
    done
}

# Make 898 max width still
function maxwidth898() {
    for file in *.jpg; do
        # next line checks the mime-type of the file
        IMAGE_TYPE=$(file --mime-type -b "$file" | awk -F'/' '{print $1}')
        if [ "$IMAGE_TYPE" = "image" ]; then
            #IMAGE_SIZE=`file -b "$file" | sed 's/ //g' | sed 's/,/ /g' | awk '{print $2}'`
            WIDTH=$(identify -format "%w" "$file")
            # If the image width is greater than 898 a still is created
            if [ "$WIDTH" -ge 899 ]; then
                #This line converts the image to 898 max width still
                filename=$(basename "$file")
                extension="${filename##*.}"
                filename="${filename%.*}"
                convert "$file" -resize '898>' -quality 60 "./still_${filename}.${extension}"
                echo " "
                echo Processing "$file"...
                echo "still_${filename}.${extension}" created
            fi
        fi
    done
    # for i in still_*.jpg
    # do
    # jpegoptim --all-progressive -pt --strip-all "$i"
    # done
}

# swap specific chars in filename, leaving the rest unaffected
#function swapchar()
##{
#for i in *.axf
#    do
#        mv "$i" "${i//_/-}"
#    done
#}

# clears jpg metadata
function jpgclearmeta() {
    for i in *.jpg; do
        jpegoptim -pqt --strip-all "$i"
    done
}

# Make 48x38 tiny jpg thumbnails
function jpgtiny() {
    for file in *.jpg; do
        # next line checks the mime-type of the file
        IMAGE_TYPE=$(file --mime-type -b "$file" | awk -F'/' '{print $1}')
        if [ "$IMAGE_TYPE" = "image" ]; then
            #IMAGE_SIZE=`file -b "$file" | sed 's/ //g' | sed 's/,/ /g' | awk '{print $2}'`
            WIDTH=$(identify -format "%w" "$file")
            HEIGHT=$(identify -format "%h" "$file")
            # If the image width is greater than 48 or the height is greater than 38 a thumb is created
            if [ "$WIDTH" -ge 49 ] || [ "$HEIGHT" -ge 39 ]; then
                #This line convert the image in a 48 x 38 thumb
                filename=$(basename "$file")
                extension="${filename##*.}"
                filename="${filename%.*}"
                convert -scale '48x38' "$file" "./TN_${filename}.${extension}"
                echo " "
                echo Processing "$file"...
                echo "TN_${filename}.${extension}" created
            fi
        fi
    done
    for i in TN_*.jpg; do
        jpegoptim -pqt --strip-all "$i"
    done
}

# Make 150x100 jpg "thumbnails"
function jpegthumbs() {
    for file in *.jpg; do
        # next line checks the mime-type of the file
        IMAGE_TYPE=$(file --mime-type -b "$file" | awk -F'/' '{print $1}')
        if [ "$IMAGE_TYPE" = "image" ]; then
            # IMAGE_SIZE=`file -b "$file" | sed 's/ //g' | sed 's/,/ /g' | awk '{print $2}'`
            WIDTH=$(identify -format "%w" "$file")
            HEIGHT=$(identify -format "%h" "$file")
            # If the image width is greater than 150 or the height is greater than 150 a thumb is created
            if [ "$WIDTH" -ge 151 ] || [ "$HEIGHT" -ge 101 ]; then
                #This line convert the image in a 150 x 100 thumb
                filename=$(basename "$file")
                extension="${filename##*.}"
                filename="${filename%.*}"
                convert -sample 150x100 "$file" "./${filename}_thumb.${extension}"
                echo " "
                echo Processing "$file"...
                echo "${filename}_thumb.${extension}" created
            fi
        fi
    done
    for i in TN_*.jpg; do
        jpegoptim -pqt --strip-all "$i"
    done
}

##################
# system toolbox #
##################

#give me this app!!!
gimme() {
    sudo apt update
    sudo apt -y install "$1"
    sudo apt-get clean
}

#reinstall this app!!!
tryagain() {
    sudo apt update
    sudo apt -y reinstall "$1"
    sudo apt-get clean
}

#completely purge this app!!!
nuke() {
    sudo apt -y purge --auto-remove "$1"
    sudo apt -y autoremove --purge
    sudo apt-get clean
}

#upgrade system
iago() {
    echo "=> update repos" && sudo apt update
    echo "==> remove cruft" && sudo apt -y autoremove
    echo "===> get all the stuffs" && sudo apt -y full-upgrade
    echo "====> remove newly created cruft" && sudo apt -y autoremove --purge
    echo "> cleaning out old packages! <" && sudo apt-get clean
}

# Make n-dupes of a file
function dupe() {
    OPTIND=1
    local case=""
    local usage="dupe: Make n-dupes of a file.
    Usage: dupe [\"filename\"] \"# of copies\"
    Example:   dupe file.txt 3
will make 1file.txt, 2file.txt and 3file.txt "
    while getopts :it opt; do
        case "$opt" in
        i) case="-i " ;;
        *)
            echo "$usage"
            return
            ;;
        esac
    done
    shift "$(("$OPTIND" - 1))"
    if [ "$#" -lt 1 ]; then
        echo "$usage"
        return
    fi
    for f in $(seq "$2"); do cp "$1" "$f""$1"; done
}

#DES3 OpenSSL decrypt a file:
function descramble() { openssl des3 -d -in "$1" -out "$2"; }

#DES3 OpenSSL encrypt a file:
function scramble() { openssl des3 -salt -in "$1" -out "$2"; }

# Find a file with a pattern in name:
function ff() { find . -type f -iname '*'"$*"'*' -ls; }

# Find a file with pattern $1 in name and Execute $2 on it:
function fe() { find . -type f -iname '*'"${1:-}"'*' -exec "${2:-file}" {} \;; }

# Find a pattern in a set of files and highlight them:
# (needs a recent version of egrep)
function fstr() {
    OPTIND=1
    local case=""
    local usage="fstr: find string in files.
Usage: fstr [-i] \"pattern\" [\"filename pattern\"] "
    while getopts :it opt; do
        case "$opt" in
        i) case="-i " ;;
        *)
            echo "$usage"
            return
            ;;
        esac
    done
    shift $((OPTIND - 1))
    if [ "$#" -lt 1 ]; then
        echo "$usage"
        return
    fi
    find . -type f -name "${2:-*}" -print0 |
        xargs -0 egrep --color=always -sn "${case} $1" 2>&- | more
}

# Find a pattern in a set of files BUT WITHOUT highlighting them:
# (needs a recent version of egrep)
function ncfstr() {
    OPTIND=1
    local case=""
    local usage="ncfstr: find string in files, colorlessly.
Usage: ncfstr [-i] \"pattern\" [\"filename pattern\"] "
    while getopts :it opt; do
        case "$opt" in
        i) case="-i " ;;
        *)
            echo "$usage"
            return
            ;;
        esac
    done
    shift $((OPTIND - 1))
    if [ "$#" -lt 1 ]; then
        echo "$usage"
        return
    fi
    find . -type f -name "${2:-*}" -print0 |
        xargs -0 egrep --color=never -sn "${case} $1" 2>&- | more
}

#cut last n lines in file, 20 by default
function cuttail() {
    nlines=${2:-20}
    sed -n -e :a -e "1,${nlines}!{P;N;D;};N;ba $1"
}

# move filenames to lowercase
function lowercase() {
    for file; do
        filename=${file##*/}
        case "$filename" in
        */*) [ "$dirname" = "${file%/*}" ] ;;
        *) dirname=. ;;
        esac
        nf=$(echo "$filename" | tr "[:upper:]" "[:lower:]")
        newname="${dirname}/${nf}"
        if [ "$nf" != "$filename" ]; then
            mv "$file" "$newname"
            echo "lowercase: $file --> $newname"
        else
            echo "lowercase: $file not changed."
        fi
    done
}

# Swap 2 filenames around, if they exist (from Uzi's bashrc).
function swap() {
    local TMPFILE=tmp.$$

    [ $# -ne 2 ] && echo "swap: 2 arguments needed" && return 1
    [ ! -e "$1" ] && echo "swap: $1 does not exist" && return 1
    [ ! -e "$2" ] && echo "swap: $2 does not exist" && return 1

    mv "$1" $TMPFILE
    mv "$2" "$1"
    mv $TMPFILE "$2"
}

# Handy Extract Program.
function pfimpf() {
    if [ -f "$1" ]; then
        case $1 in
        *.tar.bz2) tar xvjf "$1" ;;
        *.tar.gz) tar xvzf "$1" ;;
        *.bz2) bunzip2 "$1" ;;
        *.rar) unrar x "$1" ;;
        *.gz) gunzip "$1" ;;
        *.tar) tar xvf "$1" ;;
        *.tbz2) tar xvjf "$1" ;;
        *.tgz) tar xvzf "$1" ;;
        *.zip) unzip "$1" ;;
        *.Z) uncompress "$1" ;;
        *.7z) 7z x "$1" ;;
        *) echo "'$1' cannot be extracted via >pfimpf<" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Some example functions:
#
# a) function settitle
function settitle() {
    echo -ne "\e]2;$@\a\e]1;$@\a"
}

# b) function cd_func
# This function defines a 'cd' replacement function capable of keeping,
# displaying and accessing history of visited directories, up to 10 entries.
# To use it, uncomment it, source this file and try 'cd --'.
# acd_func 1.0.6, 18-may-2013
# Petar Marinov, http://geocities.com/h2428, this is public domain
# Edited by Chris Olin, http://chrisolin.com, this is still public domian

cd_func() {
    local x2 the_new_dir adir index
    local -i cnt

    if [[ $1 == "--" ]]; then
        dirs -v
        return 0
    fi

    the_new_dir=$1
    [[ -z $1 ]] && the_new_dir=$HOME

    if [[ ${the_new_dir:0:1} == '-' ]]; then
        #
        # Extract dir N from dirs
        index=${the_new_dir:1}
        [[ -z $index ]] && index=1
        adir=$(dirs +$index)
        if [[ -z "$adir" ]]; then
            if [[ "$SHELL" == "/bin/zsh" ]]; then
                cd ~${index} || exit
                return 0
            else
                echo "ADIR is null. Terminating." && return 1
            fi
        fi
        the_new_dir=$adir
    fi

    #
    # '~' has to be substituted by ${HOME}
    [[ ${the_new_dir:0:1} == '~' ]] && the_new_dir="${HOME}${the_new_dir:1}"

    #
    # Now change to the new dir and add to the top of the stack
    pushd "${the_new_dir}" >/dev/null || exit
    [[ $? -ne 0 ]] && return 1
    the_new_dir=$(pwd)

    # Trim down everything beyond 11th entry
    popd -n +11 2>/dev/null 1>/dev/null

    #
    # Remove any other occurence of this dir, skipping the top of the stack
    for ((cnt = 1; cnt <= 10; cnt++)); do
        x2=$(dirs +"${cnt}" 2>/dev/null)
        [[ $? -ne 0 ]] && return 0
        [[ ${x2:0:1} == '~' ]] && x2="${HOME}${x2:1}"
        if [[ "${x2}" == "${the_new_dir}" ]]; then
            popd -n +"$cnt" 2>/dev/null 1>/dev/null
            cnt=$((cnt - 1))
        fi
    done

    return 0
}

#pull down and rebuild/install Warzone2100
function wz() {
    cd_func "${HOME}"/src
    WZ_SOURCE="${HOME}"/src/warzone2100
    if [[ -d "$WZ_SOURCE" ]]; then
        cd_func "$WZ_SOURCE"
        git remote update -p
        git merge --ff-only @\{u\}
        git submodule update --init --recursive
    else
        git clone --recurse-submodules --depth 1 https://github.com/Warzone2100/warzone2100 "${HOME}"/src/warzone2100
    fi
    cd_func "$WZ_SOURCE"
    sudo ./get-dependencies_linux.sh ubuntu build-all
    mkdir -p build
    cd_func build || return
    cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX:PATH=/opt/warzone2100-latest -GNinja ..
    sudo cmake --build . --target install
    #    sudo ln -s /opt/warzone2100-latest/bin/warzone2100 /usr/local/bin/;
    cd_func || exit
}

#what desktop am I running?
function wutdt() {
    printf 'Desktop: %s\nSession: %s\n' "$XDG_CURRENT_DESKTOP" "$GDMSESSION"
}

#Get PID to kill, from top
function gettoppid() {
    top -p "$(pgrep -d , "$1")"
}

#Get/Update vim
function freshenvim() {
    sudo apt -y install libncurses5-dev libgtk2.0-dev libatk1.0-dev libcairo2-dev libx11-dev libxpm-dev libxt-dev python-dev python3-dev ruby-dev lua5.1 liblua5.1-0-dev libperl-dev git
    sudo apt -y purge vim vim-runtime gvim vim-tiny vim-common vim-gui-common vim-nox
    sudo apt -y autoremove
    VIM_SOURCE="${HOME}"/src/vim
    if [[ -d "$VIM_SOURCE" ]]; then
        cd_func "$VIM_SOURCE"
        git remote update -p
        git merge --ff-only @\{u\}
        git submodule update --init --recursive
    else
        git clone https://github.com/vim/vim.git "${HOME}"/src/vim
    fi
    cd_func "$VIM_SOURCE"
    make clean distclean
    ./configure --with-features=huge \
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

    cd ~/src/vim/src || return
    make VIMRUNTIMEDIR=/usr/local/share/vim/vim82
    sudo make install

    sudo update-alternatives --install /usr/bin/editor editor /usr/local/bin/vim 1
    sudo update-alternatives --set editor /usr/local/bin/vim
    sudo update-alternatives --install /usr/bin/vi vi /usr/local/bin/vim 1
    sudo update-alternatives --set vi /usr/local/bin/vim
    cd || exit
}

#pre-reqs for YouCompleteMe
function prep4YCM() {
    sudo apt -y install build-essential cmake mono-complete nodejs default-jdk npm shellcheck
    YCM_SOURCE="${HOME}"/.vim/bundle/YouCompleteMe
    if [[ -d "$YCM_SOURCE" ]]; then
        vim +PluginUpdate +qall
        cd "$YCM_SOURCE" || return
        python3 install.py --js-completer --ts-completer --cs-completer --clangd-completer --java-completer --rust-completer
    else
        vim +PluginInstall +qall
        cd "$YCM_SOURCE" || return
        python3 install.py --js-completer --ts-completer --cs-completer --clangd-completer --java-completer --rust-completer
    fi
}

#Make a 16x16px ico file
function favico() {
    convert -resize x16 -gravity center -crop 16x16+0+0 "%1" -flatten -colors 256 -background transparent favicon.ico
}

# smallify vids
# ffmpeg -i input.avi -c:v libx264 -crf 18 -preset veryslow -c:a copy out.mp4

#Use ffplay (from ffmpeg) to play random MP3s from a directory
function toonzes() {
    find . -type f -name "*.mp3" | shuf | while read -r f; do ffplay -autoexit -- "$f"; done
}

#!/bin/bash
function wav2mp3() {
    for x in *.wav; do ffmpeg -i "$x" -vn -ar 44100 -ac 2 -b:a 192k "$(basename "$x" .wav).mp3"; done
}
#!/bin/bash
function ogg2mp3() {
    for x in *.ogg; do ffmpeg -i "$x" "$(basename "$x" .ogg).mp3"; done
}
