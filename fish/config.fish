source /usr/share/cachyos-fish-config/cachyos-config.fish
#source /home/rex/.config/fish/functions/functions.fish

# Set Fish default shell options
set -g fish_greeting

# Set environment variables
set -x EDITOR vim
set -x VISUAL gvim

# Set paths
set -x GOPATH $HOME/go
set -x PATH $PATH $HOME/binnie /usr/local/go/bin $GOPATH/bin $HOME/.cargo/bin $HOME/.local/bin

# Starship prompt
starship init fish | source

# FNM (Fast Node Manager)
fnm env --use-on-cd | source

# Enable FZF keybindings
fzf_key_bindings

# Enable Zoxide
zoxide init fish | source

# ADD'L ENVIRONMENT VARIABLES
set -Ux HF_TOKEN "hf_SECRET-KEY-HERE"
set -Ux CEREBRAS_API_KEY "csk-SECRET-KEY-HERE"
set -Ux GHCR_TOKEN "ghp_SECRET-KEY-HERE"
set -Ux DISCOGS_TOKEN "SECRET-KEY-HERE"
set -x PATH $HOME/.pyenv/bin $PATH
pyenv init - | source
