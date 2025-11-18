#!/bin/bash
# ==============================================================================
# FILE: install_ponysay.sh
#
# This script attempts to install ponysay. It first tries the system package
# manager (apt) and falls back to building from source with pyenv if the
# package is not found. It includes pre-checks for build dependencies.
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

# Detect the package manager (currently focused on apt, dnf, pacman, zypper)
detect_distro() {
  local pkg_manager=""
  if command -v apt &>/dev/null; then pkg_manager="apt";
  elif command -v dnf &>/dev/null; then pkg_manager="dnf";
  elif command -v pacman &>/dev/null; then pkg_manager="pacman";
  elif command -v zypper &>/dev/null; then pkg_manager="zypper";
  else echo "unknown" && return 1; fi
  echo "$pkg_manager"
}

# Installs required build tools (like 'texinfo' for 'makeinfo')
install_build_deps() {
  local pkg_manager="$1"
  local required_packages="texinfo"

  log_info "Checking for and installing required build dependencies: ${required_packages}..."

  case "$pkg_manager" in
    "apt")
      if ! command -v makeinfo &>/dev/null; then
        # Use 'sudo' to install the required system dependency
        sudo apt update && sudo apt install -y $required_packages
        if [ $? -ne 0 ]; then
          log_error "Failed to install build dependencies via apt. Manual installation required."
          return 1
        fi
      else
        log_info "Required dependencies are already installed."
      fi
      ;;
    *)
      log_warn "Automatic build dependency checking is not implemented for $pkg_manager."
      log_warn "Proceeding without check, which may lead to errors."
      ;;
  esac
  return 0
}

# Fallback mechanism to install ponysay by building from source using pyenv.
install_from_source() {
  log_warn "Falling back to building from source with pyenv..."
  if ! command -v pyenv &>/dev/null; then
    log_error "pyenv not found. Please run the main bootstrap script first."
    exit 1
  fi

  # 1. Install build dependencies before proceeding (e.g., texinfo for makeinfo)
  if ! install_build_deps "$(detect_distro)"; then
    log_error "Cannot proceed without required build tools."
    exit 1
  fi

  # 2. Create necessary system cache directory with root permissions
  # This prevents PermissionError: [Errno 13] Permission denied: '/var/cache/ponysay'
  log_info "Creating required system cache directory /var/cache/ponysay..."
  sudo mkdir -p /var/cache/ponysay
  if [ $? -ne 0 ]; then
    log_error "Failed to create cache directory. Check sudo access or permissions."
    exit 1
  fi

  temp_dir=$(mktemp -d)
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

    log_info "Upgrading pip and downgrading setuptools for compatibility..."
    ~/.pyenv/versions/3.11.9/bin/pip install --upgrade pip
    # Downgrade setuptools to <59 to avoid modern build incompatibility errors
    ~/.pyenv/versions/3.11.9/bin/pip install "setuptools<59"

    log_info "Installing ponysay directly with setup.py (bypassing pip)..."
    # 3. Direct setup.py invocation with required flags:
    # --prefix="$PYENV_ROOT/versions/3.11.9": Forces installation into user's pyenv path (avoids /usr/bin PermissionError)
    # --freedom=partial: Bypasses mandatory prompt for asset licensing
    if ~/.pyenv/versions/3.11.9/bin/python3 setup.py install --freedom=partial --prefix="$PYENV_ROOT/versions/3.11.9"; then
      log_info "Successfully installed ponysay via setup.py"
      pyenv rehash # Update pyenv shims for the new binary
    else
      log_warn "Failed to install ponysay via setup.py"
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
