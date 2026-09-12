#!/usr/bin/env bash
set -euo pipefail

# ------------------------
# Logging
# ------------------------
log_info() { printf "[INFO] %s\n" "$*" >&2; }
log_warn() { printf "[WARN] %s\n" "$*" >&2; }
log_error(){ printf "[ERR ] %s\n" "$*" >&2; }

# ------------------------
# Args / globals
# ------------------------
DRY_RUN=0
LIST_MODULES=0
HELP_MODULE=""
SELECTED_MODULES=()
SHELL_CHOICE=""

# Plan buckets
PKGS=()          # system pkgs
AUR_PKGS=()      # AUR pkgs
CARGO_ITEMS=()   # "binary:crate" entries
ACTIONS=()       # human-readable actions
WRITES=()        # "verb:path"

# Flags that indicate execution-time steps
NEED_REPOS=0

RAW_BASE="https://raw.githubusercontent.com/jspractice-1480122229/didactic-waddle/trunk"

# ------------------------
# Utilities
# ------------------------
add_pkg()        { PKGS+=("$1"); }
add_aur_pkg()    { AUR_PKGS+=("$1"); }
add_action()     { ACTIONS+=("$1"); }
add_write()      { WRITES+=("$1:$2"); } # e.g. overwrite:/home/me/.bashrc

# Cargo policy A: install crate only if binary missing
add_cargo_item() { CARGO_ITEMS+=("$1:$2"); } # binary:crate

dedupe_array() {
  local -n arr="$1"
  local -A seen=()
  local out=()
  local x
  for x in "${arr[@]}"; do
    [[ -n "${seen[$x]:-}" ]] && continue
    seen["$x"]=1
    out+=("$x")
  done
  arr=("${out[@]}")
}

detect_pkg_manager() {
  if command -v apt-get &>/dev/null; then echo "apt";
  elif command -v dnf5 &>/dev/null; then echo "dnf5";
  elif command -v dnf &>/dev/null; then echo "dnf";
  elif command -v pacman &>/dev/null; then echo "pacman";
  elif command -v zypper &>/dev/null; then echo "zypper";
  else log_error "Unsupported package manager." && exit 1; fi
}

# apt/pacman/etc. say nothing about init system — e.g. antiX runs apt without
# systemd. Modules that assume `systemctl --user` (ssh_agent) need this.
detect_init_system() {
  if [[ -d /run/systemd/system ]]; then echo "systemd"; else echo "other"; fi
}

# ------------------------
# Your functions (kept, only lightly adjusted)
# ------------------------
setup_additional_repos() {
  local pkg_manager="$1"

  case "$pkg_manager" in
    "apt")
      log_info "Setting up additional APT repositories for VSCodium and MS Edge..."
      if ! curl -s --connect-timeout 5 https://packages.microsoft.com >/dev/null; then
        log_error "Cannot reach package repositories. Check internet connection."
        return 1
      fi

      sudo apt-get update || { log_error "Failed to update package lists"; return 1; }
      sudo apt-get install -y curl gpg apt-transport-https || { log_error "Failed to install repo dependencies"; return 1; }

      if ! curl -fsSL https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
        | sudo gpg --dearmor -o /usr/share/keyrings/vscodium-archive-keyring.gpg; then
        log_error "Failed to add VSCodium repository key"
        return 1
      fi
      echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' \
        | sudo tee /etc/apt/sources.list.d/vscodium.list >/dev/null

      if ! curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
        | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-edge-keyring.gpg; then
        log_error "Failed to add Microsoft Edge repository key"
        return 1
      fi
      echo 'deb [ arch=amd64 signed-by=/usr/share/keyrings/microsoft-edge-keyring.gpg ] https://packages.microsoft.com/repos/edge stable main' \
        | sudo tee /etc/apt/sources.list.d/microsoft-edge.list >/dev/null

      sudo apt-get update
      ;;
    "dnf5"|"dnf")
      log_info "Setting up additional DNF repositories for VSCodium and MS Edge..."
      sudo rpm --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg
      printf "[gitlab.com_paulcarroty_vscodium_repo]\nname=download.vscodium.com\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg\n" \
        | sudo tee /etc/yum.repos.d/vscodium.repo >/dev/null

      sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
      printf "[microsoft-edge]\nname=Microsoft Edge\nbaseurl=https://packages.microsoft.com/yumrepos/edge/\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc\n" \
        | sudo tee /etc/yum.repos.d/microsoft-edge.repo >/dev/null
      ;;
    *)
      log_warn "No additional repos configured for pkg_manager=$pkg_manager (fine)."
      ;;
  esac
}

detect_latest_jdk() {
  local pkg_manager="$1"
  case "$pkg_manager" in
    "apt")
      apt-cache search "^openjdk-[0-9]+-jdk$" 2>/dev/null \
        | grep -oE 'openjdk-[0-9]+-jdk' | sort -V | tail -1 || echo "openjdk-17-jdk"
      ;;
    "dnf5")
      dnf5 list available 2>/dev/null \
        | grep -oE 'java-[0-9]+-openjdk-devel' | sort -V | tail -1 || echo "java-17-openjdk-devel"
      ;;
    "dnf")
      dnf list available 2>/dev/null \
        | grep -oE 'java-[0-9]+-openjdk-devel' | sort -V | tail -1 || echo "java-17-openjdk-devel"
      ;;
    "pacman")
      pacman -Ss 2>/dev/null \
        | grep -oE 'jdk[0-9]+-openjdk' | sort -V | tail -1 || echo "jdk17-openjdk"
      ;;
    "zypper")
      zypper search 2>/dev/null \
        | grep -oE 'java-[0-9]+-openjdk-devel' | sort -V | tail -1 || echo "java-17-openjdk-devel"
      ;;
    *)
      echo "openjdk-17-jdk"
      ;;
  esac
}

# ------------------------
# AUR helper (paru only)
# ------------------------
install_aur_helper() {
  if command -v paru &>/dev/null; then return 0; fi
  log_info "Installing AUR helper (paru)..."
  sudo pacman -S --needed --noconfirm base-devel git
  local temp_dir; temp_dir="$(mktemp -d)"
  trap 'rm -rf "$temp_dir"' EXIT
  ( cd "$temp_dir" && git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si --noconfirm )
}

# ------------------------
# Module registry (docs)
# ------------------------
module_desc() {
  case "$1" in
    base_core)              echo "Base essentials (curl/wget/git/build basics, fish, etc.)" ;;
    media_cli)              echo "Media CLI utilities (yt-dlp/ffmpeg/mediainfo/etc.)" ;;
    media_lounge_players)   echo "Media lounge players (VLC/Quod Libet, etc.)" ;;
    media_lounge_streaming) echo "Media lounge streaming apps (FreeTube via AUR on Arch for now)" ;;
    containers_podman)      echo "Podman + compose" ;;
    dev_python_uv)          echo "Python via uv (no system Python mutation)" ;;
    dev_python_pyenv)       echo "pyenv + build deps (gated; heavier)" ;;
    dev_jdk)                echo "Install latest OpenJDK package detected for your distro" ;;
    dev_go)                 echo "Go toolchain" ;;
    editor_codium)          echo "VSCodium (repo on apt/dnf; AUR on Arch)" ;;
    browser_edge)           echo "Microsoft Edge (repo on apt/dnf; AUR on Arch)" ;;
    scripts_bin)            echo "Download your ~/.local/bin helper scripts" ;;
    dotfiles_bashrc)        echo "Backup and download the repo's full bash/ config (bashrc, aliases, functions, personal overlays)" ;;
    dotfiles_fish)          echo "Generate fish config.fish + aliases + download fish functions" ;;
    ssh_agent)              echo "Download SSH config + persistent ssh-agent (systemd units, or a portable fallback on non-systemd inits); guards against xfce4-session's and GNOME/gcr4's competing agents" ;;
    vim_ycm)                echo "Download cross-distro-vim-ycm.sh to ~/binnie/ + install_vim/ycm fish functions" ;;
    rust)                   echo "Install rustup toolchain (cargo available)" ;;
    rust_tools)             echo "Modern CLI tools via pkgs else cargo (skips cargo if binary exists)" ;;
    *)                      echo "Unknown module" ;;
  esac
}

print_modules() {
  local mods=(
    base_core media_cli media_lounge_players media_lounge_streaming
    containers_podman dev_python_uv dev_python_pyenv dev_jdk dev_go
    editor_codium browser_edge scripts_bin dotfiles_bashrc dotfiles_fish
    ssh_agent vim_ycm rust rust_tools
  )
  printf "Available modules:\n"
  local m
  for m in "${mods[@]}"; do
    printf "  %-26s %s\n" "$m" "$(module_desc "$m")"
  done
}

print_module_help() {
  local m="$1"
  printf "%s\n  %s\n\n" "$m" "$(module_desc "$m")"
  case "$m" in
    media_lounge_streaming)
      printf "Notes:\n"
      printf "  - Uses AUR on Arch for 'freetube-bin'.\n"
      printf "  - On non-Arch, currently no-op unless you add native package names.\n"
      ;;
    dotfiles_bashrc)
      printf "Notes:\n"
      printf "  - Backs up any existing ~/.bashrc, ~/.bash_profile, ~/.bash_aliases,\n"
      printf "    ~/.bash_functions, ~/.bash_aliases_personal, ~/.bash_functions_personal,\n"
      printf "    and ~/.bash_personal, then downloads the repo's versions of each.\n"
      printf "  - The repo's bash config mirrors the fish config's dispatcher-function\n"
      printf "    pattern (media/img/fileops/sys/utils/finder/archive) for feature parity.\n"
      printf "  - This is intentionally opt-in.\n"
      ;;
    dotfiles_fish)
      printf "Notes:\n"
      printf "  - Writes ~/.config/fish/config.fish and conf.d/aliases.fish.\n"
      printf "  - Sets SSH_AUTH_SOCK to systemd socket path.\n"
      printf "  - Downloads install_vim.fish and install_ycm.fish into functions/.\n"
      ;;
    ssh_agent)
      printf "Notes:\n"
      printf "  - Downloads ssh/config from repo to ~/.ssh/config (backs up existing).\n"
      printf "  - If xfce4-session is present, disables its built-in ssh-agent\n"
      printf "    auto-launch (xfconf /startup/ssh-agent/enabled) so it stops racing\n"
      printf "    our agent for SSH_AUTH_SOCK on every login.\n"
      printf "  - On systemd hosts: disables gcr-ssh-agent.socket/.service if present\n"
      printf "    (GNOME 46+'s built-in ssh-agent, moved out of gnome-keyring into\n"
      printf "    gcr4; also pulled in by some Cinnamon/MATE setups) since it claims\n"
      printf "    SSH_AUTH_SOCK the same way ours does. KDE's ssh-agent (gpg-agent's\n"
      printf "    enable-ssh-support) is opt-in, not on by default, so it's left alone.\n"
      printf "    Then downloads systemd/user/ssh-agent.service and enables + starts\n"
      printf "    it via systemctl --user. Keys load lazily: ssh/config's\n"
      printf "    AddKeysToAgent yes adds a key (prompting for its passphrase) the\n"
      printf "    first time it's actually used, rather than an eager ssh-add at\n"
      printf "    boot — a systemd service can't prompt for a passphrase without an\n"
      printf "    askpass helper and a display, so eager loading isn't reliable here.\n"
      printf "  - On non-systemd hosts (e.g. antiX/sysvinit, runit): downloads\n"
      printf "    ssh/agent-init.sh to ~/.ssh/ and wires it into ~/.bash_profile\n"
      printf "    (and ~/.config/fish/config.fish via ssh_agent_ensure.fish, if fish\n"
      printf "    dotfiles are deployed). It reuses any already-reachable agent\n"
      printf "    (e.g. one a desktop session already started) or starts one and\n"
      printf "    caches its env for reuse across shells.\n"
      ;;
    vim_ycm)
      printf "Notes:\n"
      printf "  - Downloads cross-distro-vim-ycm.sh to ~/binnie/.\n"
      printf "  - Downloads install_vim.fish and install_ycm.fish to fish functions dir.\n"
      printf "  - Run 'install_vim' then 'install_ycm' in fish to compile Vim+YCM.\n"
      ;;
    rust_tools)
      printf "Notes:\n"
      printf "  - Policy A: if tool binary exists, cargo install is skipped.\n"
      printf "  - Some tools install different binary names (rg/btm/dust).\n"
      ;;
  esac
}

# ------------------------
# Planner printing
# ------------------------
print_plan() {
  dedupe_array PKGS
  dedupe_array AUR_PKGS
  dedupe_array CARGO_ITEMS
  dedupe_array ACTIONS
  dedupe_array WRITES

  echo "== PLAN =="
  echo "Modules: ${SELECTED_MODULES[*]:-(none)}"
  echo

  echo "-- Actions --"
  if ((${#ACTIONS[@]})); then printf '  - %s\n' "${ACTIONS[@]}"; else echo "  (none)"; fi
  echo

  echo "-- File writes --"
  if ((${#WRITES[@]})); then printf '  - %s\n' "${WRITES[@]}"; else echo "  (none)"; fi
  echo

  echo "-- System packages --"
  if ((${#PKGS[@]})); then printf '  - %s\n' "${PKGS[@]}"; else echo "  (none)"; fi
  echo

  echo "-- AUR packages --"
  if ((${#AUR_PKGS[@]})); then printf '  - %s\n' "${AUR_PKGS[@]}"; else echo "  (none)"; fi
  echo

  echo "-- Cargo (binary:crate) --"
  if ((${#CARGO_ITEMS[@]})); then printf '  - %s\n' "${CARGO_ITEMS[@]}"; else echo "  (none)"; fi
  echo
}

# ------------------------
# Argument parsing
# ------------------------
add_selected_modules() {
  local part
  IFS=',' read -ra _mod_parts <<< "$1"
  for part in "${_mod_parts[@]}"; do
    [[ -n "$part" ]] && SELECTED_MODULES+=("$part")
  done
}

parse_args() {
  while (($#)); do
    case "$1" in
      --dry-run) DRY_RUN=1 ;;
      --list-modules) LIST_MODULES=1 ;;
      --help-module) shift; HELP_MODULE="${1:-}";;
      --help-module=*) HELP_MODULE="${1#*=}" ;;
      --mod)
        if [[ -z "${2:-}" || "${2:-}" == --* ]]; then
          LIST_MODULES=1
        else
          shift
          add_selected_modules "$1"
        fi
        ;;
      --mod=*) add_selected_modules "${1#*=}" ;;
      --shell)
        if [[ -z "${2:-}" || "${2:-}" == --* ]]; then
          log_error "--shell requires an argument: bash, fish, or both"
          exit 2
        fi
        shift
        SHELL_CHOICE="$1"
        ;;
      --shell=*) SHELL_CHOICE="${1#*=}" ;;
      --help|-h)
        cat <<'EOF'
Usage:
  ./bootstrap.sh [--dry-run] [--list-modules] [--help-module <name>] [--mod <name>[,<name>...] ...] [--shell bash|fish|both]

--mod accepts a comma-separated list and/or may be repeated; both forms combine.

Examples:
  ./bootstrap.sh --list-modules
  ./bootstrap.sh --help-module ssh_agent
  ./bootstrap.sh --dry-run --mod base_core --mod media_cli
  ./bootstrap.sh --mod base_core --mod ssh_agent --mod vim_ycm --mod dotfiles_fish
  ./bootstrap.sh --mod base_core,ssh_agent,vim_ycm,dotfiles_fish
  ./bootstrap.sh --shell both --mod base_core
  ./bootstrap.sh --shell bash
EOF
        exit 0
        ;;
      *)
        log_error "Unknown arg: $1"
        exit 2
        ;;
    esac
    shift
  done
}

# ------------------------
# Module planners (build plan only)
# ------------------------
plan_base_core() {
  add_action "Install base core packages"
  add_pkg "wget"; add_pkg "curl"; add_pkg "git"; add_pkg "cmake"; add_pkg "tree"
  add_pkg "net-tools"; add_pkg "perl"; add_pkg "gawk"; add_pkg "sed"; add_pkg "openssl"
  add_pkg "tar"; add_pkg "unzip"; add_pkg "make"; add_pkg "gcc"
  add_pkg "fish"
}

plan_media_cli() {
  add_action "Install media CLI tools (consumption + inspection)"
  :
}

plan_media_lounge_players() {
  add_action "Install media lounge players"
  :
}

plan_media_lounge_streaming() {
  add_action "Install media lounge streaming apps"
  :
}

plan_containers_podman() {
  add_action "Install Podman stack"
  :
}

plan_dev_python_uv() {
  add_action "Install uv (python env manager)"
  :
}

plan_dev_python_pyenv() {
  add_action "Install pyenv + build deps (gated)"
  :
}

plan_dev_jdk() {
  add_action "Install latest OpenJDK detected"
  :
}

plan_dev_go() {
  add_action "Install Go toolchain"
  :
}

plan_editor_codium() {
  add_action "Install VSCodium"
  :
}

plan_browser_edge() {
  add_action "Install Microsoft Edge"
  :
}

plan_scripts_bin() {
  add_action "Download helper scripts into ~/.local/bin"
  add_write "mkdir" "$HOME/.local/bin"
}

plan_dotfiles_bashrc() {
  add_action "Backup and download the repo's bash/ config (bashrc, profile, aliases, functions, personal overlays)"
  add_write "backup_download" "$HOME/.bashrc"
  add_write "backup_download" "$HOME/.bash_profile"
  add_write "backup_download" "$HOME/.bash_aliases"
  add_write "backup_download" "$HOME/.bash_functions"
  add_write "backup_download" "$HOME/.bash_aliases_personal"
  add_write "backup_download" "$HOME/.bash_functions_personal"
  add_write "backup_download" "$HOME/.bash_personal"
}

plan_dotfiles_fish() {
  add_action "Generate fish config.fish, aliases, and download fish functions"
  add_write "write" "$HOME/.config/fish/config.fish"
  add_write "write" "$HOME/.config/fish/conf.d/aliases.fish"
  add_write "write" "$HOME/.config/fish/functions/install_vim.fish"
  add_write "write" "$HOME/.config/fish/functions/install_ycm.fish"
}

plan_ssh_agent() {
  add_action "Download SSH config; set up a persistent ssh-agent appropriate to this init system"
  add_write "backup_download" "$HOME/.ssh/config"

  if command -v xfconf-query &>/dev/null; then
    add_action "Detected XFCE tooling: will disable its built-in ssh-agent auto-launch (xfce4-session), which otherwise races our own agent for SSH_AUTH_SOCK"
  fi

  if [[ "$(detect_init_system)" == "systemd" ]]; then
    if command -v systemctl &>/dev/null && systemctl --user list-unit-files gcr-ssh-agent.socket &>/dev/null; then
      add_action "Detected gcr-ssh-agent.socket (GNOME/gcr4's built-in ssh-agent): will disable it, which otherwise races our own agent for SSH_AUTH_SOCK"
    fi
    add_write "write" "$HOME/.config/systemd/user/ssh-agent.service"
  else
    add_action "NOTE: no systemd user session detected — using the portable ssh-agent fallback (cached agent env reused across shells) instead of systemd units"
    add_write "write" "$HOME/.ssh/agent-init.sh"
  fi
}

plan_vim_ycm() {
  add_action "Download cross-distro-vim-ycm.sh to ~/binnie/"
  add_action "Download install_vim.fish and install_ycm.fish"
  add_write "mkdir" "$HOME/binnie"
  add_write "write" "$HOME/binnie/cross-distro-vim-ycm.sh"
}

plan_rust() {
  add_action "Install rustup (enables cargo)"
  :
}

plan_rust_tools() {
  add_action "Install modern CLI tools (pkgs else cargo; binary-exists skips cargo)"
  add_cargo_item "eza"      "eza"
  add_cargo_item "bat"      "bat"
  add_cargo_item "rg"       "ripgrep"
  add_cargo_item "fd"       "fd-find"
  add_cargo_item "sd"       "sd"
  add_cargo_item "dust"     "du-dust"
  add_cargo_item "procs"    "procs"
  add_cargo_item "btm"      "bottom"
  add_cargo_item "zoxide"   "zoxide"
  add_cargo_item "starship" "starship"
}

# ------------------------
# Build plan (module selection + per-manager package mapping)
# ------------------------
build_plan() {
  local pkg_manager="$1"

  # Translate --shell into module selections
  case "$SHELL_CHOICE" in
    "") : ;;
    bash)  SELECTED_MODULES+=("dotfiles_bashrc") ;;
    fish)  SELECTED_MODULES+=("dotfiles_fish") ;;
    both)  SELECTED_MODULES+=("dotfiles_bashrc" "dotfiles_fish") ;;
    *)
      log_error "Invalid --shell value: $SHELL_CHOICE (expected bash, fish, or both)"
      exit 2
      ;;
  esac

  dedupe_array SELECTED_MODULES

  # Default module if none selected
  if ((${#SELECTED_MODULES[@]} == 0)); then
    SELECTED_MODULES=("base_core")
  fi

  # First pass: register actions/writes and module intents
  local m
  for m in "${SELECTED_MODULES[@]}"; do
    case "$m" in
      base_core)              plan_base_core ;;
      media_cli)              plan_media_cli ;;
      media_lounge_players)   plan_media_lounge_players ;;
      media_lounge_streaming) plan_media_lounge_streaming ;;
      containers_podman)      plan_containers_podman ;;
      dev_python_uv)          plan_dev_python_uv ;;
      dev_python_pyenv)       plan_dev_python_pyenv ;;
      dev_jdk)                plan_dev_jdk ;;
      dev_go)                 plan_dev_go ;;
      editor_codium)          plan_editor_codium ;;
      browser_edge)           plan_browser_edge ;;
      scripts_bin)            plan_scripts_bin ;;
      dotfiles_bashrc)        plan_dotfiles_bashrc ;;
      dotfiles_fish)          plan_dotfiles_fish ;;
      ssh_agent)              plan_ssh_agent ;;
      vim_ycm)                plan_vim_ycm ;;
      rust)                   plan_rust ;;
      rust_tools)             plan_rust_tools ;;
      *)
        log_error "Unknown module: $m"
        exit 3
        ;;
    esac
  done

  # Second pass: per-manager package mapping based on enabled modules

  # Base build tool meta-pkgs (manager-specific)
  case "$pkg_manager" in
    apt)        add_pkg "build-essential" ;;
    dnf5|dnf)   : ;; # gcc/make already included
    pacman)     : ;;
    zypper)     : ;;
  esac

  # Media CLI mapping
  if [[ " ${SELECTED_MODULES[*]} " == *" media_cli "* ]]; then
    case "$pkg_manager" in
      apt)
        add_pkg "yt-dlp"; add_pkg "ffmpeg"; add_pkg "lame"; add_pkg "ghostscript"
        add_pkg "webp"; add_pkg "imagemagick"; add_pkg "jpegoptim"; add_pkg "cowsay"
        add_pkg "libimage-exiftool-perl"; add_pkg "mediainfo"
        ;;
      dnf5|dnf)
        add_pkg "yt-dlp"; add_pkg "ffmpeg"; add_pkg "lame"; add_pkg "ghostscript"
        add_pkg "libwebp-tools"; add_pkg "ImageMagick"; add_pkg "jpegoptim"; add_pkg "cowsay"
        add_pkg "perl-Image-ExifTool"; add_pkg "mediainfo"
        ;;
      pacman)
        add_pkg "yt-dlp"; add_pkg "ffmpeg"; add_pkg "lame"; add_pkg "ghostscript"
        add_pkg "libwebp"; add_pkg "imagemagick"; add_pkg "jpegoptim"; add_pkg "cowsay"
        add_pkg "perl-image-exiftool"; add_pkg "mediainfo"
        ;;
      zypper)
        add_pkg "yt-dlp"; add_pkg "ffmpeg"; add_pkg "lame"; add_pkg "ghostscript"
        add_pkg "libwebp-tools"; add_pkg "ImageMagick"; add_pkg "jpegoptim"; add_pkg "cowsay"
        add_pkg "exiftool"; add_pkg "mediainfo"
        ;;
    esac
  fi

  # Media lounge players mapping
  if [[ " ${SELECTED_MODULES[*]} " == *" media_lounge_players "* ]]; then
    case "$pkg_manager" in
      apt|dnf5|dnf|pacman|zypper) add_pkg "vlc"; add_pkg "quodlibet" ;;
    esac
  fi

  # Media lounge streaming mapping (AUR on Arch for now)
  if [[ " ${SELECTED_MODULES[*]} " == *" media_lounge_streaming "* ]]; then
    case "$pkg_manager" in
      pacman) add_aur_pkg "freetube-bin" ;;
      *)      add_action "NOTE: media_lounge_streaming currently only installs FreeTube on Arch via AUR" ;;
    esac
  fi

  # Containers
  if [[ " ${SELECTED_MODULES[*]} " == *" containers_podman "* ]]; then
    case "$pkg_manager" in
      apt|dnf5|dnf|pacman|zypper) add_pkg "podman"; add_pkg "podman-compose" ;;
    esac
  fi

  # Python (uv vs pyenv)
  if [[ " ${SELECTED_MODULES[*]} " == *" dev_python_uv "* ]]; then
    case "$pkg_manager" in
      pacman) add_pkg "uv" ;;
      *) add_action "NOTE: uv not mapped for $pkg_manager; add install method if desired" ;;
    esac
  fi

  if [[ " ${SELECTED_MODULES[*]} " == *" dev_python_pyenv "* ]]; then
    case "$pkg_manager" in
      apt)
        add_pkg "pyenv"
        add_pkg "libssl-dev"; add_pkg "libncurses-dev"; add_pkg "libsqlite3-dev"; add_pkg "libreadline-dev"
        add_pkg "tk-dev"; add_pkg "libgdbm-dev"; add_pkg "libdb-dev"; add_pkg "libbz2-dev"; add_pkg "libexpat1-dev"
        add_pkg "liblzma-dev"; add_pkg "zlib1g-dev"; add_pkg "libffi-dev"
        ;;
      dnf5|dnf)
        add_pkg "pyenv"
        add_pkg "openssl-devel"; add_pkg "ncurses-devel"; add_pkg "sqlite-devel"; add_pkg "readline-devel"
        add_pkg "tk-devel"; add_pkg "gdbm-devel"; add_pkg "libdb-devel"; add_pkg "bzip2-devel"; add_pkg "expat-devel"
        add_pkg "xz-devel"; add_pkg "zlib-devel"; add_pkg "libffi-devel"
        ;;
      pacman)
        add_pkg "pyenv"
        add_pkg "openssl"; add_pkg "ncurses"; add_pkg "sqlite"; add_pkg "readline"; add_pkg "tk"; add_pkg "gdbm"
        add_pkg "db"; add_pkg "bzip2"; add_pkg "expat"; add_pkg "xz"; add_pkg "zlib"; add_pkg "libffi"
        ;;
      zypper)
        add_pkg "pyenv"
        add_pkg "openssl-devel"; add_pkg "ncurses-devel"; add_pkg "sqlite3-devel"; add_pkg "readline-devel"
        add_pkg "tk-devel"; add_pkg "gdbm-devel"; add_pkg "libbz2-devel"; add_pkg "libexpat-devel"
        add_pkg "liblzma-devel"; add_pkg "zlib-devel"; add_pkg "libffi-devel"
        ;;
    esac
  fi

  # JDK
  if [[ " ${SELECTED_MODULES[*]} " == *" dev_jdk "* ]]; then
    local jdk_package
    jdk_package="$(detect_latest_jdk "$pkg_manager")"
    add_action "Detected latest JDK package: $jdk_package"
    add_pkg "$jdk_package"
  fi

  # Go
  if [[ " ${SELECTED_MODULES[*]} " == *" dev_go "* ]]; then
    case "$pkg_manager" in
      apt|dnf5|dnf) add_pkg "golang" ;;
      pacman)       add_pkg "go" ;;
      zypper)       add_pkg "go" ;;
    esac
  fi

  # Codium / Edge (repo on apt/dnf; AUR on Arch)
  if [[ " ${SELECTED_MODULES[*]} " == *" editor_codium "* ]]; then
    case "$pkg_manager" in
      apt|dnf5|dnf) NEED_REPOS=1; add_pkg "codium" ;;
      pacman)       add_aur_pkg "vscodium" ;;
      zypper)       add_action "NOTE: VSCodium not mapped for zypper in this script yet" ;;
    esac
  fi

  if [[ " ${SELECTED_MODULES[*]} " == *" browser_edge "* ]]; then
    case "$pkg_manager" in
      apt|dnf5|dnf) NEED_REPOS=1; add_pkg "microsoft-edge-stable" ;;
      pacman)       add_aur_pkg "microsoft-edge-stable-bin" ;;
      zypper)       add_action "NOTE: Edge not mapped for zypper in this script yet" ;;
    esac
  fi

  # Shell / convenience packages
  case "$pkg_manager" in
    apt|dnf5|dnf|pacman|zypper) add_pkg "fzf" ;;
  esac

  # If repos are needed, record action + write intents (dry-run visibility)
  if (( NEED_REPOS )); then
    add_action "Will configure additional repositories for Codium/Edge (apt/dnf)"
    add_write "write" "/etc/apt/sources.list.d/vscodium.list"
    add_write "write" "/etc/apt/sources.list.d/microsoft-edge.list"
    add_write "write" "/etc/yum.repos.d/vscodium.repo"
    add_write "write" "/etc/yum.repos.d/microsoft-edge.repo"
  fi
}

# ------------------------
# Execution
# ------------------------
execute_plan() {
  local pkg_manager="$1"

  dedupe_array PKGS
  dedupe_array AUR_PKGS
  dedupe_array CARGO_ITEMS
  dedupe_array ACTIONS
  dedupe_array WRITES

  # Repos first (only if needed and supported)
  if (( NEED_REPOS )); then
    case "$pkg_manager" in
      apt|dnf5|dnf) setup_additional_repos "$pkg_manager" ;;
      *) : ;;
    esac
  fi

  # System packages
  if ((${#PKGS[@]})); then
    log_info "Installing system packages (${#PKGS[@]})..."
    case "$pkg_manager" in
      apt)    sudo apt-get update && sudo apt-get install -y "${PKGS[@]}" ;;
      dnf5)   sudo dnf5 install -y "${PKGS[@]}" ;;
      dnf)    sudo dnf  install -y "${PKGS[@]}" ;;
      pacman) sudo pacman -S --needed --noconfirm "${PKGS[@]}" ;;
      zypper) sudo zypper install -y "${PKGS[@]}" ;;
    esac
  fi

  # AUR packages
  if [[ "$pkg_manager" == "pacman" && ${#AUR_PKGS[@]} -gt 0 ]]; then
    install_aur_helper
    log_info "Installing AUR packages (${#AUR_PKGS[@]})..."
    paru -S --needed --noconfirm "${AUR_PKGS[@]}"
  fi

  # scripts_bin
  if [[ " ${SELECTED_MODULES[*]} " == *" scripts_bin "* ]]; then
    log_info "Installing standalone scripts to ~/.local/bin..."
    local bin_dir="${HOME}/.local/bin"
    mkdir -p "$bin_dir"
    local scripts=("install_ponysay.sh" "bmedia" "bimg" "bsys" "bfileops" "butils" "bfinder" "barchive")
    local s
    for s in "${scripts[@]}"; do
      log_info "Downloading ${s}..."
      if wget -q "${RAW_BASE}/bash/scripts/${s}" -O "${bin_dir}/${s}"; then
        chmod +x "${bin_dir}/${s}"
      else
        log_warn "Failed to download ${s}"
      fi
    done
  fi

  # dotfiles_bashrc (opt-in)
  if [[ " ${SELECTED_MODULES[*]} " == *" dotfiles_bashrc "* ]]; then
    log_info "Backing up and downloading bash configuration..."
    local timestamp; timestamp="$(date +%Y%m%d_%H%M%S)"
    local bash_file
    local -A bash_targets=(
      ["${HOME}/.bashrc"]="bash/.bashrc"
      ["${HOME}/.bash_profile"]="bash/.bash_profile"
      ["${HOME}/.bash_aliases"]="bash/.bash_aliases"
      ["${HOME}/.bash_functions"]="bash/.bash_functions"
      ["${HOME}/.bash_aliases_personal"]="bash/.bash_aliases_personal"
      ["${HOME}/.bash_functions_personal"]="bash/.bash_functions_personal"
      ["${HOME}/.bash_personal"]=".bash_personal"
    )
    for bash_file in "${!bash_targets[@]}"; do
      if [[ -f "$bash_file" ]]; then
        log_info "Backing up existing $(basename "$bash_file") to $(basename "$bash_file").backup_${timestamp}"
        cp "$bash_file" "${bash_file}.backup_${timestamp}"
      fi
      if wget -q "${RAW_BASE}/${bash_targets[$bash_file]}" -O "$bash_file"; then
        log_info "Downloaded $(basename "$bash_file")"
      else
        log_warn "Failed to download $(basename "$bash_file")"
      fi
    done
  fi

  # dotfiles_fish
  if [[ " ${SELECTED_MODULES[*]} " == *" dotfiles_fish "* ]]; then
    log_info "Generating fish shell configuration..."
    local fish_dir="${HOME}/.config/fish"
    mkdir -p "$fish_dir/conf.d" "$fish_dir/functions"

    cat > "$fish_dir/config.fish" <<'EOL'
# config.fish: generated by bootstrap.sh
set -gx PATH $HOME/.local/bin $HOME/.cargo/bin $PATH
set -gx SSH_AUTH_SOCK $XDG_RUNTIME_DIR/ssh-agent.socket
if command -v starship >/dev/null; starship init fish | source; end
if command -v pyenv   >/dev/null; pyenv init - | source; end
if command -v fnm     >/dev/null; fnm env --use-on-cd | source; end
if command -v zoxide  >/dev/null; zoxide init fish | source; end
if test -f ~/.config/fish/config.personal.fish; source ~/.config/fish/config.personal.fish; end
EOL

    cat > "$fish_dir/conf.d/aliases.fish" <<'EOL'
# aliases.fish: generated by bootstrap.sh
alias rm 'rm -iv'
alias cp 'cp -iv'
alias mv 'mv -iv'
alias .. 'cd ..'
alias ... 'cd ../..'
if command -v eza >/dev/null
    alias ls 'eza --icons'
    alias ll 'eza -l --icons'
    alias la 'eza -la --icons'
else
    alias ls 'ls -F --color=auto'
    alias ll 'ls -alF --color=auto'
end
EOL

    local fish_fns=("install_vim.fish" "install_ycm.fish")
    local fn
    for fn in "${fish_fns[@]}"; do
      if wget -q "${RAW_BASE}/fish/functions/${fn}" -O "$fish_dir/functions/${fn}"; then
        log_info "Downloaded ${fn}"
      else
        log_warn "Failed to download ${fn}"
      fi
    done
  fi

  # ssh_agent
  if [[ " ${SELECTED_MODULES[*]} " == *" ssh_agent "* ]]; then
    log_info "Setting up SSH config and persistent ssh-agent..."
    mkdir -p "${HOME}/.ssh"
    chmod 700 "${HOME}/.ssh"

    if [[ -f "${HOME}/.ssh/config" ]]; then
      log_info "Backing up existing ~/.ssh/config"
      cp "${HOME}/.ssh/config" "${HOME}/.ssh/config.backup"
    fi
    if wget -q "${RAW_BASE}/ssh/config" -O "${HOME}/.ssh/config"; then
      chmod 600 "${HOME}/.ssh/config"
      log_info "Downloaded ~/.ssh/config"
    else
      log_warn "Failed to download ~/.ssh/config"
    fi

    # Guard: xfce4-session auto-launches its own ssh-agent by default
    # (unless gnome-keyring-daemon is present) and will otherwise fight
    # whatever agent we set up below for SSH_AUTH_SOCK on every login.
    if command -v xfconf-query &>/dev/null && xfconf-query -c xfce4-session -l &>/dev/null; then
      log_info "Disabling xfce4-session's built-in ssh-agent auto-launch..."
      xfconf-query -c xfce4-session -p /startup/ssh-agent/enabled -s false 2>/dev/null \
        || xfconf-query -c xfce4-session -p /startup/ssh-agent/enabled -n -t bool -s false 2>/dev/null \
        || log_warn "Could not set xfce4-session's ssh-agent property"
    fi

    if [[ "$(detect_init_system)" == "systemd" ]]; then
      # Guard: GNOME 46+ moved gnome-keyring's ssh-agent component out into
      # gcr4's gcr-ssh-agent, shipped as a socket-activated systemd user unit
      # that claims SSH_AUTH_SOCK the same way our own agent does — the same
      # race as XFCE's built-in agent above, just via systemd instead of
      # xfconf. Some Cinnamon/MATE setups pull in gcr4 too, so this isn't
      # GNOME-only; KDE's ssh-agent (gpg-agent's enable-ssh-support) is
      # opt-in rather than on by default, so it needs no guard here.
      if command -v systemctl &>/dev/null && systemctl --user list-unit-files gcr-ssh-agent.socket &>/dev/null; then
        log_info "Disabling gcr-ssh-agent (GNOME/gcr4's built-in ssh-agent)..."
        systemctl --user disable --now gcr-ssh-agent.socket gcr-ssh-agent.service 2>/dev/null \
          || log_warn "Could not disable gcr-ssh-agent"
      fi

      mkdir -p "${HOME}/.config/systemd/user"
      if wget -q "${RAW_BASE}/systemd/user/ssh-agent.service" -O "${HOME}/.config/systemd/user/ssh-agent.service"; then
        log_info "Downloaded ssh-agent.service"
      else
        log_warn "Failed to download ssh-agent.service"
      fi

      systemctl --user daemon-reload
      systemctl --user enable --now ssh-agent || log_warn "Could not enable ssh-agent.service"
      log_info "SSH agent service enabled and started (systemd); key loads lazily via ssh/config's AddKeysToAgent"
    else
      log_info "No systemd user session detected — installing portable ssh-agent fallback..."
      if wget -q "${RAW_BASE}/ssh/agent-init.sh" -O "${HOME}/.ssh/agent-init.sh"; then
        chmod +x "${HOME}/.ssh/agent-init.sh"
        log_info "Downloaded ~/.ssh/agent-init.sh"
      else
        log_warn "Failed to download ~/.ssh/agent-init.sh"
      fi

      local marker="# ssh_agent module (bootstrap.sh non-systemd fallback)"

      if [[ -f "${HOME}/.bash_profile" ]] && ! grep -qF "$marker" "${HOME}/.bash_profile"; then
        {
          echo ""
          echo "$marker"
          echo '[ -d /run/systemd/system ] || . "$HOME/.ssh/agent-init.sh"'
        } >> "${HOME}/.bash_profile"
        log_info "Wired ssh-agent fallback into ~/.bash_profile"
      fi

      if [[ -f "${HOME}/.config/fish/config.fish" ]]; then
        mkdir -p "${HOME}/.config/fish/functions"
        if wget -q "${RAW_BASE}/fish/functions/ssh_agent_ensure.fish" -O "${HOME}/.config/fish/functions/ssh_agent_ensure.fish"; then
          log_info "Downloaded ssh_agent_ensure.fish"
        else
          log_warn "Failed to download ssh_agent_ensure.fish"
        fi
        if ! grep -qF "$marker" "${HOME}/.config/fish/config.fish"; then
          {
            echo ""
            echo "$marker"
            echo "if not test -d /run/systemd/system; ssh_agent_ensure; end"
          } >> "${HOME}/.config/fish/config.fish"
          log_info "Wired ssh-agent fallback into ~/.config/fish/config.fish"
        fi
      fi

      log_info "Portable ssh-agent fallback installed (only activates when no systemd user session is present)"
    fi
  fi

  # vim_ycm
  if [[ " ${SELECTED_MODULES[*]} " == *" vim_ycm "* ]]; then
    log_info "Downloading cross-distro-vim-ycm.sh to ~/binnie/..."
    mkdir -p "${HOME}/binnie"
    if wget -q "${RAW_BASE}/bash/cross-distro-vim-ycm.sh" -O "${HOME}/binnie/cross-distro-vim-ycm.sh"; then
      chmod +x "${HOME}/binnie/cross-distro-vim-ycm.sh"
      log_info "Downloaded cross-distro-vim-ycm.sh"
    else
      log_warn "Failed to download cross-distro-vim-ycm.sh"
    fi

    local fish_dir="${HOME}/.config/fish"
    mkdir -p "$fish_dir/functions"
    local fn
    for fn in "install_vim.fish" "install_ycm.fish"; do
      if wget -q "${RAW_BASE}/fish/functions/${fn}" -O "$fish_dir/functions/${fn}"; then
        log_info "Downloaded ${fn}"
      else
        log_warn "Failed to download ${fn}"
      fi
    done
  fi

  # rust / rust_tools
  if [[ " ${SELECTED_MODULES[*]} " == *" rust "* || " ${SELECTED_MODULES[*]} " == *" rust_tools "* ]]; then
    if ! command -v cargo &>/dev/null; then
      log_info "Installing Rust via rustup..."
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
      # shellcheck disable=SC1090
      source "$HOME/.cargo/env"
    fi
  fi

  if [[ " ${SELECTED_MODULES[*]} " == *" rust_tools "* ]]; then
    log_info "Installing/updating modern CLI tools via cargo (only when binary missing)..."
    local item bin crate
    for item in "${CARGO_ITEMS[@]}"; do
      bin="${item%%:*}"
      crate="${item#*:}"
      if command -v "$bin" &>/dev/null; then
        log_info "Skipping cargo install for ${crate} (binary '${bin}' already exists)"
      else
        log_info "cargo install ${crate} (expects binary '${bin}')"
        cargo install --locked "$crate"
      fi
    done
  fi
}

# ------------------------
# Main
# ------------------------
main() {
  parse_args "$@"

  if (( LIST_MODULES )); then
    print_modules
    exit 0
  fi

  if [[ -n "$HELP_MODULE" ]]; then
    print_module_help "$HELP_MODULE"
    exit 0
  fi

  local pkg_manager
  pkg_manager="$(detect_pkg_manager)"
  log_info "Detected package manager: $pkg_manager"

  build_plan "$pkg_manager"
  print_plan
  (( DRY_RUN )) && exit 0

  execute_plan "$pkg_manager"
  log_info "Done."
}

main "$@"
