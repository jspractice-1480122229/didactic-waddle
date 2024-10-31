# The copy in your home directory (~/.bash_aliases) is yours, please
# feel free to customise it to create a shell environment to your
# liking.  If you feel a change would be benificial to all, please
# feel free to send a patch to the cygwin mailing list.

# User dependent .bash_aliases file
# Aliases
#
# Some example alias instructions
# If these are enabled they will be used instead of any instructions
# they may mask.  For example, alias rm='rm -i' will mask the rm
# application.  To override the alias instruction use a \ before, ie
# \rm will call the real rm not the alias.
#
# Verbose output...
alias rm='rm -v'
alias cp='cp -v'
alias mv='mv -v'
#
# Default to human readable figures
# alias df='df -h'
# alias du='du -h'
alias du='du -kh'       # Makes a more readable output.
alias df='df -kTh'

#
# Misc :)
# alias less='less -r'                          # raw control characters
alias whence='type -a'                        # where, of a sort
alias which='type -a'
alias grep='grep --color'                     # show differences in color
alias awk='gawk'
# -> Prevents accidentally clobbering files.
alias mkdir='mkdir -p'
alias h='history'
alias j='jobs -l'
alias ..='cd ..'
alias path='echo -e ${PATH//:/\\n}'
alias libpath='echo -e ${LD_LIBRARY_PATH//:/\\n}'
alias rd='rm -frv'
#-------------------------------------------------------------
# The 'ls' family (this assumes you use a recent GNU ls)
#-------------------------------------------------------------
alias ll="ls -l --group-directories-first"
alias la='ls -Al'          # show hidden files
alias lx='ls -lXB'         # sort by extension
alias lk='ls -lSr'         # sort by size, biggest last
alias lc='ls -ltcr'        # sort by and show change time, most recent last
alias lu='ls -ltur'        # sort by and show access time, most recent last
alias lt='ls -ltr'         # sort by date, most recent last
alias lm='ls -al |more'    # pipe through 'more'
alias lr='ls -lR'          # recursive ls
alias l='ls -CF'     

alias dir='ls --color=auto --format=vertical'
alias vdir='ls --color=auto --format=long'
# alias egrep='egrep --color=auto'              # show differences in color
# alias fgrep='fgrep --color=auto'              # show differences in color
#
# Some shortcuts for different directory listings
# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    if test -r ~/.dircolors
    then
        eval "$(dircolors -b ~/.dircolors)"
    else
        eval "$(dircolors -b)"
    fi
    alias ls='ls -aghlAFGH --color=tty --group-directories-first'                 # classify files in color
fi

#-------------
# Other stuff
#-------------
alias diff='colordiff -s'
alias cls='clear'
alias psall='ps -ejH'
alias cpdir='cp -frv'
alias cd='cd_func'
alias chmod='chmod -c'
alias vi='vim'
alias fortuna='\fortune'
alias fortune='fortune -a -s -n 125'
alias randumb='echo $RANDOM'
alias purtyjson='python -m json.tool'
alias moo='fortune -c | cowthink -f $(find /usr/share/cowsay/cows -type f | shuf -n 1)'
# alias tidy='tidy -im --ncr yes --numeric-entities yes -w 120'
alias dia='date +%s'
alias tstamp='date +%Y-%m-%dT%T%:z'
