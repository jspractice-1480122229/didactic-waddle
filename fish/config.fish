source /usr/share/cachyos-fish-config/cachyos-config.fish

# Set Fish default shell options
set -g fish_greeting

# Set environment variables
set -x EDITOR vim
set -x VISUAL gvim
set -x GOPATH $HOME/go
set -x PYENV_ROOT "$HOME/.pyenv"

# Consolidated PATH using fish_add_path (deduplicates automatically)
fish_add_path -p "$PYENV_ROOT/bin"
fish_add_path -p "$HOME/.yarn/bin"
fish_add_path -p "$HOME/binnie"
fish_add_path -p /usr/local/go/bin
fish_add_path -p "$GOPATH/bin"
fish_add_path -p "$HOME/.cargo/bin"
fish_add_path -p "$HOME/.local/bin"
fish_add_path -p "$HOME/binnie/google-cloud-sdk/bin"

# Starship prompt
starship init fish | source

# FNM (Fast Node Manager)
fnm env --use-on-cd | source

# Enable FZF keybindings
fzf_key_bindings

# Enable Zoxide
zoxide init fish | source

# Pyenv initialization
status is-interactive; and pyenv init --path | source
status is-interactive; and pyenv init - | source
status is-interactive; and pyenv virtualenv-init - | source

# Google Cloud SDK
if test -f "$HOME/binnie/google-cloud-sdk/path.fish.inc"
    source "$HOME/binnie/google-cloud-sdk/path.fish.inc"
end

# Auto-start Ollama if not running
function ensure_ollama
    if not pgrep -x ollama > /dev/null
        ollama serve > /dev/null 2>&1 &
        disown
        echo "🤖 Ollama started in background"
    end
end

# Auto-start Ollama when opening VSCodium
alias codium='ensure_ollama; /usr/bin/codium'

# Quick check of true Btrfs health
alias bstat="sudo btrfs filesystem usage /"

# One-liner to see the biggest folders excluding your Ollama models
alias spacehogs="sudo du -h --max-depth=2 / --exclude=/var/lib/ollama | sort -h"

# Load API tokens from separate file (DO NOT COMMIT THIS FILE)
if test -f ~/.config/fish/secrets.fish
    source ~/.config/fish/secrets.fish
end

function bt-reset
    echo "Stopping the noise and waking the K850..."
    sudo systemctl restart bluetooth
    sleep 1
    echo "connect DC:FF:6B:DB:90:C1" | bluetoothctl
end

fish_add_path ~/bin

alias autorandr='/usr/bin/python3 /usr/bin/autorandr'

# Open Edge as Personal
alias edge-pers="microsoft-edge-stable --profile-directory='Default'"

# Open Edge as Contract (The directory name might be 'Profile 1' or 'Profile 2')
alias edge-work="microsoft-edge-stable --profile-directory='Profile 1'"

# opencode
fish_add_path /home/rex/.opencode/bin
