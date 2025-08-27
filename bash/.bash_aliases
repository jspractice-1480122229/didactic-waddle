#!/usr/bin/env bash
# FILE: ~/.bash_aliases
# Bash aliases with feature parity to Fish configuration

# Verbose and safe operations
alias rm='rm -iv'
alias cp='cp -iv'
alias mv='mv -iv'
alias mkdir='mkdir -pv'

# Human-readable output
alias du='du -kh'
alias df='df -kTh'
alias free='free -h'

# Better defaults
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias awk='gawk'
alias sed='sed -E'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias -- -='cd -'
alias ~='cd ~'

# Path Inspection
alias path='echo -e ${PATH//:/\\n}'

# LS FAMILY - EZA ENHANCED
if command -v eza &>/dev/null; then
    alias ls='eza -F --header --icons --git --group-directories-first'
    alias l='eza --classify --color-scale'
    alias ll='eza -l --header --git --icons --group-directories-first'
    alias la='eza -al --header --git --icons --group-directories-first'
    alias lt='eza --long --sort=modified --reverse'
    alias lk='eza --long --sort=size --reverse'
    alias lx='eza --long --sort=extension'
    alias ltree='eza --tree --level=2'
else
    echo "⚠️  eza not found! Install it for a better ls experience. Using standard ls." >&2
    alias ls='ls -F --color=auto --group-directories-first'
    alias ll='ls -alF --color=auto'
    alias la='ls -A --color=auto'
    alias l='ls -CF --color=auto'
fi

# Process Management
alias h='history'
alias j='jobs -l'
alias top='htop 2>/dev/null || top'
alias ps='procs 2>/dev/null || ps'

# Text Processing & Viewing
alias vi='vim'
alias cls='clear'
alias less='less -R'
if command -v colordiff &>/dev/null; then alias diff='colordiff -s'; fi
alias purtyjson='python3 -m json.tool 2>/dev/null || python -m json.tool'

# Fun Stuff
if command -v fortune &>/dev/null; then
    alias fortune='fortune -a -s -n 125'
    if command -v cowsay &>/dev/null; then
        if [ -d /usr/share/cowsay/cows ]; then
            alias moo='fortune -c | cowthink -f $(find /usr/share/cowsay/cows -type f -name "*.cow" | shuf -n 1)'
        else
            alias moo='fortune | cowsay'
        fi
    else
        alias moo='fortune'
    fi
fi

# Quick Edits
alias bashrc='vim ~/.bashrc'
alias bashaliases='vim ~/.bash_aliases'
alias bashfunctions='vim ~/.bash_functions'

# LOAD PERSONAL ALIASES
if [ -f ~/.bash_personal ]; then source ~/.bash_personal; fi
