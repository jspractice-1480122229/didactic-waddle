# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

black='\[\e[0;30m\]'
BLACK='\[\e[1;30m\]'
BGBlack='\[\e[40m\]'
red='\[\e[0;31m\]'
RED='\[\e[1;31m\]'
BGRed='\[\e[41m\]'
green='\[\e[0;32m\]'
GREEN='\[\e[1;32m\]'
BGGreen='\[\e[42m\]'
yellow='\[\e[0;33m\]'
YELLOW='\[\e[1;33m\]'
BGYellow='\[\e[43m\]'
blue='\[\e[0;34m\]'
BLUE='\[\e[1;34m\]'
BGBlue='\[\e[44m\]'
purple='\[\e[0;35m\]'
PURPLE='\[\e[1;35m\]'
BGPurple='\[\e[45m\]'
cyan='\[\e[0;36m\]'
CYAN='\[\e[1;36m\]'
BGCyan='\[\e[46m\]'
white='\[\e[0;37m\]'
WHITE='\[\e[1;37m\]'
BGWhite='\[\e[47m\]'
nc='\[\e[0m\]'
endBG='\[\e[m\]'

if [ "$UID" = 0 ]; then
    PS1="$red\u$nc@$red\H$nc:$CYAN\w$nc\\n$red#$nc "
else
    PS1="$PURPLE\u$nc@$CYAN\H$nc:$GREEN\w$nc\\n$GREEN\$$nc "
fi
# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    #alias grep='grep --color=auto'
    #alias fgrep='fgrep --color=auto'
    #alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.
# shellcheck source=/dev/null
if [ -f "${HOME}/.bash_aliases" ]; then
   . "${HOME}/.bash_aliases"
fi

# Function definitions.
# shellcheck source=/dev/null
if [ -f "${HOME}/.bash_functions" ]; then
  . "${HOME}/.bash_functions"
fi

# Default parameter to send to the "less" command
# -R: show ANSI colors correctly; -i: case insensitive search
LESS="-R -i"

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# Add sbin directories to PATH.  This is useful on systems that have sudo
echo $PATH | grep -Eq "(^|:)/sbin(:|)"     || PATH=$PATH:/sbin
echo $PATH | grep -Eq "(^|:)/usr/sbin(:|)" || PATH=$PATH:/usr/sbin

#bash-git-prompt
#export GIT_PROMPT_ONLY_IN_REPO=1 # Use the default prompt when not in a git repo.
#GIT_PROMPT_FETCH_REMOTE_STATUS=0 # Avoid fetching remote status
#GIT_PROMPT_SHOW_UPSTREAM=0 # Don't display upstream tracking branch
#export GIT_SHOW_UNTRACKED_FILES=no # Don't count untracked files (no, normal, all)
#export GIT_PROMPT_THEME=Chmike
# shellcheck source=/dev/null
#source ~/src/.bash-git-prompt/gitprompt.sh
#export PATH="${HOME}/.cabal/bin:${PATH}"

#export PULSE_SERVER=tcp:192.168.4.103
# Push to Xming graphic server
#export DISPLAY=192.168.4.103:0.0
