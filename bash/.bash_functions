# Functions
#-------------------------------------------------------------
# File & string-related functions:
#-------------------------------------------------------------

#PONIES!!!
function ponies() {
    fortune | awk '{print toupper($0)}' | ponythink -b unicode
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
        echo -e "Processing video '\e[32m$FILE\e[0m'";
        ffmpeg -n -i "${FILE}" -metadata encoded_by="Processed by Zeranoe FFmpeg builds for Windows, ffmpeg-v.N-82759-g1f5630a" -f mp3 -acodec libmp3lame -ab 192k -ar 44100 -id3v2_version 3 -write_id3v1 1 -vsync 2 $OUTPUT_DIR/"${FILE%.webm}.mp3"
    done
}
#Convert .aiff to 192k bitrate .mp3 files
function aiff2mp3()
{
OUTPUT_DIR=mp3version
if [ ! -d $OUTPUT_DIR ]; then
    mkdir $OUTPUT_DIR
fi
for i in *.aiff
    do ffmpeg -n -i "$i" -metadata encoded_by="Processed by Zeranoe FFmpeg builds for Windows, ffmpeg-v.N-82759-g1f5630a" -f mp3 -acodec libmp3lame -ab 192k -ar 44100 -id3v2_version 3 -write_id3v1 1 -vsync 2 $OUTPUT_DIR/"${i%.aiff}.mp3"
    done
}
#apt-get remove shortcut
function nuke()
{
    sudo apt-get --yes purge "$1";
    sudo apt-get --yes autoremove;
    sudo apt-get clean;
}

#apt-get install shortcut
function gimme()
{
    sudo apt-get update;
    sudo apt-get --yes install "$1";
    sudo apt-get --yes autoremove;
    sudo apt-get clean;
}

#Make random, dummy files
function dummyfile()
{
    dd if=/dev/zero of="$1" bs="$2" count=1
    randumb | cat >> "$1"           
}

#GUID maker
function guidmaker()
{
    a="$1"
    while [ "$a" -gt 0 ]
        do
            uuidgen -r | awk '{print toupper($0)}'
            let "a-=1"
        done
}
#"history" search
function hs()
{ history | grep "$1" ; }

#5 digit random integer
function 5digit()
{
    FLOOR=10000
    fivedigit=0
    while [ "$fivedigit" -le $FLOOR ]
        do
            fivedigit=$RANDOM
        done
    echo "$fivedigit"
    echo
}

#Make all MP3 files in current folder shrink
function shrinkMP3()
{
OUTPUT_DIR=compressed
if [ ! -d $OUTPUT_DIR ]; then
    mkdir $OUTPUT_DIR
fi
for i in *.mp3
    do ffmpeg -n -i "$i" -metadata genre="Podcast" -metadata encoded_by="Processed by Zeranoe FFmpeg builds for Windows, ffmpeg-v.N-79107-g30d1213" -ac 1 -ab 40k -ar 22050 -id3v2_version 3 -write_id3v1 1 -vsync 2 "$OUTPUT_DIR"/"$i"
    done
}

# Make 898 max width still
function maxwidth898()
{
for file in *.jpg
    do
    # next line checks the mime-type of the file
    IMAGE_TYPE=$(file --mime-type -b "$file" | awk -F'/' '{print $1}')
    if [ x"$IMAGE_TYPE" = "ximage" ]; then
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
#{
#for i in *.axf
#    do
#        mv "$i" "${i//_/-}"
#    done
#}

# clears jpg metadata
function jpgclearmeta()
{
for i in *.jpg
    do
    jpegoptim -pqt --strip-all "$i"
done
}

# Make 48x38 tiny jpg thumbnails
function jpgtiny()
{
for file in *.jpg
    do
    # next line checks the mime-type of the file
    IMAGE_TYPE=$(file --mime-type -b "$file" | awk -F'/' '{print $1}')
    if [ x"$IMAGE_TYPE" = "ximage" ]; then
        #IMAGE_SIZE=`file -b "$file" | sed 's/ //g' | sed 's/,/ /g' | awk '{print $2}'`
        WIDTH=$(identify -format "%w" "$file")
        HEIGHT=$(identify -format "%h" "$file")
        # If the image width is greater than 48 or the height is greater than 38 a thumb is created
        if [ "$WIDTH" -ge  49 ] || [ "$HEIGHT" -ge 39 ]; then
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
for i in TN_*.jpg
    do
    jpegoptim -pqt --strip-all "$i"
done
}

# Make 150x100 jpg "thumbnails"
function jpegthumbs()
{
for file in *.jpg
    do
    # next line checks the mime-type of the file
    IMAGE_TYPE=$(file --mime-type -b "$file" | awk -F'/' '{print $1}')
    if [ x"$IMAGE_TYPE" = "ximage" ]; then
       # IMAGE_SIZE=`file -b "$file" | sed 's/ //g' | sed 's/,/ /g' | awk '{print $2}'`
        WIDTH=$(identify -format "%w" "$file")
        HEIGHT=$(identify -format "%h" "$file")
        # If the image width is greater than 150 or the height is greater than 150 a thumb is created
        if [ "$WIDTH" -ge  151 ] || [ "$HEIGHT" -ge 101 ]; then
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
for i in TN_*.jpg
    do
    jpegoptim -pqt --strip-all "$i"
done
}

# Make n-dupes of a file
function dupe()
{ 
	OPTIND=1
    local case=""
    local usage="dupe: Make n-dupes of a file.
	Usage: dupe [\"filename\"] \"# of copies\"
	Example:   dupe file.txt 3
will make 1file.txt, 2file.txt and 3file.txt "
    while getopts :it opt
    do
        case "$opt" in
        i) case="-i " ;;
        *) echo "$usage"; return;;
        esac
    done
    shift "$(( "$OPTIND" - 1 ))"
    if [ "$#" -lt 1 ]; then
        echo "$usage"
        return;
    fi
	for f in $(seq "$2"); do cp "$1" "$f""$1"; done }

#DES3 OpenSSL decrypt a file:
function descramble()
{ openssl des3 -d -in "$1" -out "$2" ; }

#DES3 OpenSSL encrypt a file:
function scramble()
{ openssl des3 -salt -in "$1" -out "$2" ; }

# Find a file with a pattern in name:
function ff()
{ find . -type f -iname '*'$*'*' -ls ; }

# Find a file with pattern $1 in name and Execute $2 on it:
function fe()
{ find . -type f -iname '*'${1:-}'*' -exec ${2:-file} {} \;  ; }

# Find a pattern in a set of files and highlight them:
# (needs a recent version of egrep)
function fstr()
{
    OPTIND=1
    local case=""
    local usage="fstr: find string in files.
Usage: fstr [-i] \"pattern\" [\"filename pattern\"] "
    while getopts :it opt
    do
        case "$opt" in
        i) case="-i " ;;
        *) echo "$usage"; return;;
        esac
    done
    shift $(( $OPTIND - 1 ))
    if [ "$#" -lt 1 ]; then
        echo "$usage"
        return;
    fi
    find . -type f -name "${2:-*}" -print0 | \
    xargs -0 egrep --color=always -sn ${case} "$1" 2>&- | more

}

#cut last n lines in file, 10 by default
function cuttail()
{
    nlines=${2:-10}
    sed -n -e :a -e "1,${nlines}!{P;N;D;};N;ba" $1
}

# move filenames to lowercase
function lowercase()
{
    for file ; do
        filename=${file##*/}
        case "$filename" in
        */*) [ "$dirname" = "${file%/*}" ] ;;
        *) dirname=.;;
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
function swap()
{
    local TMPFILE=tmp.$$

    [ $# -ne 2 ] && echo "swap: 2 arguments needed" && return 1
    [ ! -e "$1" ] && echo "swap: $1 does not exist" && return 1
    [ ! -e "$2" ] && echo "swap: $2 does not exist" && return 1

    mv "$1" $TMPFILE
    mv "$2" "$1"
    mv $TMPFILE "$2"
}

# Handy Extract Program.
function pfimpf()
{
     if [ -f "$1" ] ; then
         case $1 in
             *.tar.bz2)   tar xvjf "$1"     ;;
             *.tar.gz)    tar xvzf "$1"     ;;
             *.bz2)       bunzip2 "$1"      ;;
             *.rar)       unrar x "$1"      ;;
             *.gz)        gunzip "$1"       ;;
             *.tar)       tar xvf "$1"      ;;
             *.tbz2)      tar xvjf "$1"     ;;
             *.tgz)       tar xvzf "$1"     ;;
             *.zip)       unzip "$1"        ;;
             *.Z)         uncompress "$1"   ;;
             *.7z)        7z x "$1"         ;;
             *)           echo "'$1' cannot be extracted via >pfimpf<" ;;
         esac
     else
         echo "'$1' is not a valid file"
     fi
}

# Some example functions:
#
# a) function settitle
 settitle ()
 {
   echo -ne "\e]2;$@\a\e]1;$@\a";
 }

# b) function cd_func
# This function defines a 'cd' replacement function capable of keeping,
# displaying and accessing history of visited directories, up to 10 entries.
# To use it, uncomment it, source this file and try 'cd --'.
# acd_func 1.0.5, 10-nov-2004
# Petar Marinov, http:/geocities.com/h2428, this is public domain
 cd_func ()
 {
   local x2 the_new_dir adir index
   local -i cnt

   if [[ $1 ==  "--" ]]; then
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
     [[ -z $adir ]] && return 1
     the_new_dir=$adir
   fi

   #
   # '~' has to be substituted by ${HOME}
   [[ ${the_new_dir:0:1} == '~' ]] && the_new_dir="${HOME}${the_new_dir:1}"

   #
   # Now change to the new dir and add to the top of the stack
   pushd "${the_new_dir}" > /dev/null
   [[ $? -ne 0 ]] && return 1
   the_new_dir=$(pwd)

   #
   # Trim down everything beyond 11th entry
   popd -n +11 2>/dev/null 1>/dev/null

   #
   # Remove any other occurence of this dir, skipping the top of the stack
   for ((cnt=1; cnt <= 10; cnt++)); do
     x2=$(dirs +${cnt} 2>/dev/null)
     [[ $? -ne 0 ]] && return 0
     [[ ${x2:0:1} == '~' ]] && x2="${HOME}${x2:1}"
     if [[ "${x2}" == "${the_new_dir}" ]]; then
       popd -n +$cnt 2>/dev/null 1>/dev/null
       cnt=cnt-1
     fi
   done

   return 0
 }

