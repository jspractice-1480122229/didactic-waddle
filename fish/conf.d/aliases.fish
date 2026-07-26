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
alias lt 'eza --long --sort=modified --reverse'           # Sort by date, most recent last (short for ltime)
alias lh 'eza -Al'                                        # Show hidden files
alias ldir 'eza -l --group-directories-first'             # Directories first
alias l. 'eza -a | grep -e "^\."'                         # Show only dotfiles

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
