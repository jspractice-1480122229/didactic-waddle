# FILE: ~/.config/fish/conf.d/aliases.fish

# Verbose output...
alias rm 'rm -v'
alias cp 'cp -v'
alias mv 'mv -v'

# Default to human readable figures
alias du 'du -kh'       # Makes a more readable output.
alias df 'df -kTh'      # [cite: 7]

# Misc :)
alias whence 'type -a'
alias which 'type -a'
alias grep 'grep --color'
alias awk 'gawk'
alias mkdir 'mkdir -p'  # Prevents accidentally clobbering files. [cite: 8]
alias h 'history'
alias j 'jobs -l'
alias .. 'cd ..'

# Converted from Bash's ${PATH//...} syntax
alias path 'echo -e (string replace -a ":" "\n" $PATH)'
alias libpath 'echo -e (string replace -a ":" "\n" $LD_LIBRARY_PATH)'
alias rd 'rm -frv'

#-------------------------------------------------------------
# The 'eza' family (replaces ls)
#
# Recommended: Install a Nerd Font for icon support: https://www.nerdfonts.com
#-------------------------------------------------------------

# Main replacement for 'ls'
alias ls 'eza -F --header --icons --git --group-directories-first'

# Long format with git status and headers
alias ll 'eza -l --header --git --icons --group-directories-first'
alias vdir 'eza --long'

# Long format, all files
alias la 'eza -al --header --git --icons --group-directories-first'

# Grid view (default)
alias l 'eza --classify --color-scale'
alias dir 'eza --oneline'

# Sorting
alias lx 'eza --long --sort=extension --ignore-glob="*~"' # Sort by extension
alias lk 'eza --long --sort=size --reverse'               # Sort by size, largest last
alias ltime 'eza --long --sort=modified --reverse'           # Sort by date, newest last
alias lc 'eza --long --sort=changed --reverse'            # Sort by change time
alias lu 'eza --long --sort=accessed --reverse'           # Sort by access time

# Other
alias lr 'eza --long --recurse --git'                     # Recursive ls
alias lm 'eza --long --all --git --color=always | more'   # Pipe through 'more'

# Enable color support of ls and also add handy aliases
if status is-interactive; and command -v dircolors >/dev/null
    if test -r ~/.dircolors
        eval (dircolors -c ~/.dircolors)
    else
        eval (dircolors -c)
    end
    # classify files in color
    alias ls 'ls -aghlAFGH --color=tty --group-directories-first'
end

# Alias for eza with default options to list files.
alias l 'eza --classify --color-scale'

# Alias for eza with specific options to provide detailed directory listings.
alias l.="eza -a | grep -e '^.'" # show only dotfiles
alias lh 'eza -Al'  # Show hidden files
alias lc 'eza -ltcr' # Sort by change time, most recent last
alias lk 'eza -lSr'  # Sort by size, biggest last
alias ldir 'eza -l --group-directories-first'
alias lm 'eza -al | more'  # Pipe through more for pagination
alias lr 'eza -lR'      # Recursive listing
alias lt 'eza --long --sort=modified --reverse'  # Sort by date, most recent last
alias lu 'eza -ltur' # Sort by access time, most recent last
alias lx 'eza -lXB'  # Sort by extension

# Alias for eza in vertical format.
alias dir 'eza --color auto --format vertical'

# Alias for eza in long format.
alias vdir 'eza --color auto --format long'

alias ......='cd ../../../../..'
alias .....='cd ../../../..'
alias ....='cd ../../..'
alias ...='cd ../..'
alias ..='cd ..'

#-------------
# Other stuff
#-------------
alias diff 'colordiff -s'
alias cls 'clear'
alias psall 'ps -ejH'
alias cpdir 'cp -frv'
alias chmod 'chmod -c'
alias vi 'vim'
alias fortuna '\fortune'
alias fortune 'fortune -a -s -n 125'
alias randumb 'echo $RANDOM'
alias purtyjson 'python -m json.tool'
alias moo 'fortune -c | cowthink -f (find /usr/share/cowsay/cows -type f | shuf -n 1)' # [cite: 12]
alias dia 'date +%s'
alias tstamp 'date +%Y-%m-%dT%T%:z'
alias aye 'cd $HOME/pickles/dox/ai_rag/ && podman-compose down && podman-compose pull && podman-compose up -d --build'