#!/usr/bin/env bash
# FILE: ~/.bash_aliases
# Modern bash aliases matching fish configuration

#=============================================================
# CORE UNIX IMPROVEMENTS
#=============================================================

# Verbose and safe operations
alias rm='rm -iv'  # Interactive + verbose for safety
alias cp='cp -iv'
alias mv='mv -iv'
alias mkdir='mkdir -pv'  # Create parent dirs + verbose
alias rmdir='rmdir -v'

# Human-readable output
alias du='du -kh'
alias df='df -kTh'
alias free='free -h'

# Better defaults
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias awk='gawk'  # GNU awk if available
alias sed='sed -E'  # Extended regex by default

#=============================================================
# NAVIGATION SHORTCUTS
#=============================================================

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias -- -='cd -'  # Go to previous directory
alias ~='cd ~'  # Go home

# Quick listing after cd (function is better for this)
cs() {
    cd "$@" && ls
}

#=============================================================
# PATH INSPECTION
#=============================================================

alias path='echo -e ${PATH//:/\\n}'
alias libpath='echo -e ${LD_LIBRARY_PATH//:/\\n}'
alias bashpath='echo -e ${BASH_SOURCE[@]}'

#=============================================================
# LS FAMILY - EZA ENHANCED
#=============================================================

# Check if eza is available
if command -v eza &>/dev/null; then
    # Basic listing
    alias ls='eza -F --header --icons --git --group-directories-first'
    alias l='eza --classify --color-scale'
    
    # Long formats
    alias ll='eza -l --header --git --icons --group-directories-first'
    alias la='eza -al --header --git --icons --group-directories-first'
    alias lh='eza -Al'  # Hidden files
    alias l.='eza -a | grep "^\."'  # Only dotfiles
    
    # Sorting variations
    alias lt='eza --long --sort=modified --reverse'  # By time, newest last
    alias ltr='eza --long --sort=modified'  # By time, newest first
    alias lk='eza --long --sort=size --reverse'  # By size, largest last
    alias lkr='eza --long --sort=size'  # By size, largest first
    alias lx='eza --long --sort=extension --ignore-glob="*~"'  # By extension
    alias lc='eza --long --sort=changed --reverse'  # By change time
    alias lu='eza --long --sort=accessed --reverse'  # By access time
    
    # Special views
    alias ldir='eza -lD'  # Directories only
    alias lfile='eza -lf'  # Files only
    alias ltree='eza --tree --level=2'  # Tree view
    alias lr='eza --long --recurse --git'  # Recursive
    alias lm='eza --long --all --git --color=always | less -R'  # Paged
    
    # One-line and vertical formats
    alias dir='eza --oneline'
    alias vdir='eza --long'
else
    # Fallback to standard ls
    echo "⚠️  eza not found! Install with: cargo install eza" >&2
    echo "   Using standard ls as fallback" >&2
    
    alias ls='ls -F --color=auto --group-directories-first'
    alias ll='ls -alF --color=auto'
    alias la='ls -A --color=auto'
    alias l='ls -CF --color=auto'
    alias lh='ls -Al --color=auto'
    alias l.='ls -d .* --color=auto'
    
    # Sorting with standard ls
    alias lt='ls -ltr --color=auto'  # By time
    alias lk='ls -lSr --color=auto'  # By size
    alias lx='ls -lXB --color=auto'  # By extension
    
    alias dir='ls --color=auto --format=single-column'
    alias vdir='ls --color=auto --format=long'
fi

#=============================================================
# PROCESS MANAGEMENT
#=============================================================

alias h='history'
alias j='jobs -l'
alias psall='ps -ejH'
alias pstree='pstree -p'
alias top='htop 2>/dev/null || top'  # Prefer htop if available

#=============================================================
# FILE OPERATIONS
#=============================================================

alias rd='rm -frv'  # Careful with this one!
alias cpdir='cp -frv'
alias chmod='chmod -c'
alias chown='chown -c'

# Modern replacements if available
command -v trash &>/dev/null && alias rm='trash'  # Safer rm
command -v rsync &>/dev/null && alias cpdir='rsync -av --progress'

#=============================================================
# TEXT PROCESSING & VIEWING
#=============================================================

alias vi='vim'
alias nano='nano -w'  # No word wrap
alias cls='clear'
alias less='less -R'  # Handle colors

# Diff with color
if command -v colordiff &>/dev/null; then
    alias diff='colordiff -s'
elif command -v diff &>/dev/null; then
    alias diff='diff --color=auto'
fi

# JSON pretty printing
alias purtyjson='python3 -m json.tool 2>/dev/null || python -m json.tool'
alias json='jq . 2>/dev/null || purtyjson'  # Use jq if available

#=============================================================
# DATE & TIME
#=============================================================

alias now='date +"%Y-%m-%d %H:%M:%S"'
alias nowutc='date -u +"%Y-%m-%d %H:%M:%S UTC"'
alias today='date +"%Y-%m-%d"'
alias dia='date +%s'  # Unix timestamp
alias tstamp='date +%Y-%m-%dT%T%:z'  # ISO 8601
alias week='date +%V'  # Week number

#=============================================================
# FUN STUFF
#=============================================================

# Bash-compatible random
alias randumb='echo $RANDOM'
alias rand100='echo $((RANDOM % 100 + 1))'
alias coinflip='echo $([ $((RANDOM % 2)) -eq 0 ] && echo "heads" || echo "tails")'
alias dice='echo $((RANDOM % 6 + 1))'

# Fortune and cowsay
if command -v fortune &>/dev/null; then
    alias fortune='fortune -a -s -n 125'
    alias fortuna='\fortune'  # Original fortune without filters
    
    if command -v cowsay &>/dev/null; then
        # Improved moo - check if cowsay directory exists
        if [ -d /usr/share/cowsay/cows ]; then
            alias moo='fortune -c | cowthink -f $(find /usr/share/cowsay/cows -type f -name "*.cow" | shuf -n 1)'
        else
            alias moo='fortune | cowsay'
        fi
    else
        alias moo='fortune'  # Just fortune if no cowsay
    fi
else
    alias fortune='echo "Fortune not installed"'
    alias moo='echo "🐄 Moo! (Install fortune and cowsay for the full experience)"'
fi

# Ponies function (with fallback)
ponies() {
    if command -v ponysay &>/dev/null; then
        fortune | ponysay
    elif command -v ponythink &>/dev/null; then
        fortune | ponythink -b unicode
    elif command -v cowsay &>/dev/null && command -v fortune &>/dev/null; then
        fortune | cowsay
    elif command -v fortune &>/dev/null; then
        echo "🦄 PONIES!!! 🦄"
        fortune
    else
        echo "🦄 PONIES!!! 🦄"
        echo "Install fortune and cowsay/ponysay for the full experience!"
    fi
}

#=============================================================
# DEVELOPMENT TOOLS
#=============================================================

# Git shortcuts
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
alias gcl='git clone'

# Python
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv'
alias activate='source ./venv/bin/activate'

# Rust/Cargo shortcuts
if command -v cargo &>/dev/null; then
    alias cb='cargo build'
    alias cr='cargo run'
    alias ct='cargo test'
    alias cc='cargo check'
    alias cup='cargo update'
    alias cin='cargo install'
fi

#=============================================================
# SYSTEM MONITORING
#=============================================================

alias ports='netstat -tulanp 2>/dev/null || ss -tulanp'
alias listening='netstat -an | grep LISTEN'
alias meminfo='free -h'
alias cpuinfo='lscpu'
alias diskinfo='df -h'
alias mountinfo='mount | column -t'

#=============================================================
# QUICK EDITS
#=============================================================

alias bashrc='vim ~/.bashrc'
alias bashalias='vim ~/.bash_aliases'
alias bashfunc='vim ~/.bash_functions'
alias vimrc='vim ~/.vimrc'
alias gitconfig='vim ~/.gitconfig'
alias fishconfig='vim ~/.config/fish/config.fish'

#=============================================================
# ARCH/PACMAN SPECIFIC
#=============================================================

if command -v pacman &>/dev/null; then
    alias pacup='sudo pacman -Syu'
    alias pacin='sudo pacman -S'
    alias pacrem='sudo pacman -Rns'
    alias pacsearch='pacman -Ss'
    alias pacinfo='pacman -Si'
    alias pacfiles='pacman -Ql'
    alias pacorphans='pacman -Qtdq'
    alias pacclean='sudo pacman -Scc'
fi

#=============================================================
# MODERN CLI TOOLS (if installed)
#=============================================================

# Modern replacements for standard tools
command -v bat &>/dev/null && alias cat='bat'
command -v rg &>/dev/null && alias grep='rg'
command -v fd &>/dev/null && alias find='fd'
command -v dust &>/dev/null && alias du='dust'
command -v duf &>/dev/null && alias df='duf'
command -v btm &>/dev/null && alias top='btm'
command -v procs &>/dev/null && alias ps='procs'
command -v sd &>/dev/null && alias sed='sd'

#=============================================================
# UTILITY FUNCTIONS
#=============================================================

# Extract any archive
extract() {
    if [ -z "$1" ]; then
        echo "Usage: extract <archive_file>"
        return 1
    fi
    
    if [ ! -f "$1" ]; then
        echo "Error: '$1' is not a valid file"
        return 1
    fi
    
    case "$1" in
        *.tar.bz2)  tar xjf "$1"    ;;
        *.tar.gz)   tar xzf "$1"    ;;
        *.bz2)      bunzip2 "$1"    ;;
        *.rar)      unrar x "$1"    ;;
        *.gz)       gunzip "$1"     ;;
        *.tar)      tar xf "$1"     ;;
        *.tbz2)     tar xjf "$1"    ;;
        *.tgz)      tar xzf "$1"    ;;
        *.zip)      unzip "$1"      ;;
        *.Z)        uncompress "$1" ;;
        *.7z)       7z x "$1"       ;;
        *.xz)       unxz "$1"       ;;
        *)          echo "Cannot extract '$1'" ; return 1 ;;
    esac
}

# Make directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Backup with timestamp
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

# Show all aliases help
alias-help() {
    echo "🐚 Bash Aliases Help"
    echo "==================="
    echo ""
    echo "Navigation:"
    echo "  .., ..., ....  - Go up directories"
    echo "  cs PATH        - cd and ls combined"
    echo ""
    echo "Listing (eza/ls):"
    echo "  ls, l, ll, la  - Various listing formats"
    echo "  lt, lk, lx     - Sort by time, size, extension"
    echo "  ltree          - Tree view (eza only)"
    echo "  ldir, lfile    - Directories or files only (eza only)"
    echo ""
    echo "Fun Stuff:"
    echo "  moo            - Random cowsay fortune"
    echo "  ponies         - Ponysay or fallback"
    echo "  randumb        - Random number (0-32767)"
    echo "  rand100        - Random 1-100"
    echo "  coinflip       - Heads or tails"
    echo "  dice           - Roll a die (1-6)"
    echo ""
    echo "Development:"
    echo "  g, gs, ga, gc  - Git shortcuts"
    echo "  py, pip, venv  - Python shortcuts"
    echo "  cb, cr, ct     - Cargo shortcuts (if Rust installed)"
    echo ""
    echo "Type 'alias' to see all defined aliases"
    echo "Type 'type <alias>' to see what an alias does"
}

#=============================================================
# LOAD PERSONAL ALIASES
#=============================================================

# Load personal/machine-specific aliases if they exist
if [ -f ~/.bash_aliases_personal ]; then
    source ~/.bash_aliases_personal
fi
