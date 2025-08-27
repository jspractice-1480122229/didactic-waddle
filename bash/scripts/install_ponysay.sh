#!/bin/bash
# ==============================================================================
# FILE: install_ponysay.sh
#
# This is a standalone script for optionally installing ponysay.
# It first tries the system package manager and falls back to building from
# source with pyenv if the package is not found.
# ==============================================================================

set -euo pipefail

# --- Logging functions ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

detect_distro() {
    local pkg_manager=""
    if command -v apt &>/dev/null; then pkg_manager="apt";
    elif command -v dnf &>/dev/null; then pkg_manager="dnf";
    elif command -v pacman &>/dev/null; then pkg_manager="pacman";
    elif command -v zypper &>/dev/null; then pkg_manager="zypper";
    else echo "unknown" && return 1; fi
    echo "$pkg_manager"
}

install_from_source() {
    log_warn "Falling back to building from source with pyenv..."
    if ! command -v pyenv &>/dev/null; then
        log_error "pyenv not found. Please run the main bootstrap script first."
        exit 1
    fi

    local temp_dir; temp_dir=$(mktemp -d)
    trap 'log_info "Cleaning up temp directory..."; rm -rf "$temp_dir"' EXIT
    cd "$temp_dir" || return 1
    
    log_info "Cloning ponysay repository..."
    if git clone --depth 1 https://github.com/erkin/ponysay.git; then
        cd ponysay
        log_info "Ensuring a pyenv Python version is installed..."
        # Make sure pyenv is properly initialized for this script
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init --path)"
        
        pyenv install 3.11.9 --skip-existing
        pyenv global 3.11.9
        
        log_info "Installing ponysay with pip into pyenv..."
        # Use the specific pip from the pyenv version to be certain
        if ~/.pyenv/versions/3.11.9/bin/pip install .; then
            log_info "Successfully installed ponysay via pyenv"
        else
            log_warn "Failed to install ponysay with pip"
            return 1
        fi
    else
        log_warn "Failed to clone ponysay repository"
        return 1
    fi
    cd "$HOME"
}

main() {
    if command -v ponysay &>/dev/null; then
        log_info "Ponysay is already installed."
        exit 0
    fi

    log_info "Attempting to install ponysay from package manager..."
    local pkg_manager
    pkg_manager=$(detect_distro)
    local install_success=false

    # Use a subshell with `set +e` to prevent script exit on failure
    (
        set +e
        case "$pkg_manager" in
            "apt") sudo apt install -y ponysay 2>/dev/null ;;
            "dnf") sudo dnf install -y ponysay 2>/dev/null ;;
            "pacman") sudo pacman -S --noconfirm ponysay 2>/dev/null ;;
            "zypper") sudo zypper install -y ponysay 2>/dev/null ;;
            *) exit 1 ;;
        esac
        # Check the exit code of the install command
        if [ $? -eq 0 ]; then
            install_success=true
        fi
    )

    if [ "$install_success" = true ]; then
        log_info "Successfully installed ponysay from $pkg_manager."
    else
        log_warn "Could not install ponysay from package manager."
        install_from_source
    fi
}

main "$@"
