#!/usr/bin/env bash
# FILE: ~/.bashrc
# Updated Bash configuration - a more modern, robust version

# =============================================================
# STARTUP & SAFETY CHECKS
# =============================================================

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Use case-insensitive filename globbing
shopt -s nocaseglob nocasematch

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
shopt -s globstar

# When changing directory small typos can be ignored by bash
shopt -s cdspell

# =============================================================
# HISTORY OPTIONS
# =============================================================

# Don't put duplicate lines or lines starting with space in the history.
export HISTCONTROL=$HISTCONTROL${HISTCONTROL+,}ignoreboth

# Ignore some commands from history. The '&' is a special pattern which
# suppresses duplicate entries.
export HISTIGNORE=$'[ \t]*:&:[fb]g:exit:ls:cd'

# Make bash append rather than overwrite the history on disk
shopt -s histappend

# =============================================================
# PATH MANAGEMENT
# =============================================================

# A cleaner way to ensure standard sbin directories are in the PATH.
# This prevents adding them multiple times.
if [[ ":$PATH:" != *":/sbin:"* ]]; then
  export PATH="$PATH:/sbin"
fi
if [[ ":$PATH:" != *":/usr/sbin:"* ]]; then
  export PATH="$PATH:/usr/sbin"
fi

# =============================================================
# PROMPT CONFIGURATION (PS1)
# =============================================================

# A simple, modern PS1 prompt that includes Git branch information.
# To enable this, uncomment the lines below and comment out the default PS1.
#
# parse_git_branch() {
#     git branch --show-current 2>/dev/null | sed 's/^/(%s)/'
# }
# export PS1="\n\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\[\033[0;31m\]\$(parse_git_branch)\[\033[00m\]\n$ "

# If you want to use the legacy prompt, keep this uncommented:
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*);;
esac


# =============================================================
# ALIAS & FUNCTION SOURCING
# =============================================================

# Load custom aliases and functions. The order is important:
# General aliases/functions first, then personal/machine-specific ones.

if [ -f "$HOME/.bash_aliases" ]; then
    source "$HOME/.bash_aliases"
fi

if [ -f "$HOME/.bash_functions" ]; then
    source "$HOME/.bash_functions"
fi

if [ -f "$HOME/.bash_aliases_personal" ]; then
    source "$HOME/.bash_aliases_personal"
fi

if [ -f "$HOME/.bash_functions_personal" ]; then
    source "$HOME/.bash_functions_personal"
fi
