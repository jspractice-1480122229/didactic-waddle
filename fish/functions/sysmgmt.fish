function sysmgmt -d "Comprehensive system management"
    if test (count $argv) -lt 1
        echo "Usage: sysmgmt OPERATION [args...]"
        echo "Operations:"
        echo "  search PACKAGE     - Search for packages"
        echo "  install PACKAGE... - Install packages"
        echo "  reinstall PACKAGE... - Reinstall packages"
        echo "  remove PACKAGE...  - Remove packages completely"
        echo "  upgrade           - Full system upgrade"
        echo "  info PACKAGE      - Show package info"
        echo "  desktop           - Show desktop environment info"
        echo "  pid PROCESS       - Show process info in top"
        echo "Example: sysmgmt install vim git"
        return 1
    end

    # Detect package manager once and cache it
    set -l pkg_manager
    if command -v pacman >/dev/null 2>&1
        set pkg_manager "pacman"
    else if command -v apt >/dev/null 2>&1
        set pkg_manager "apt"
    else if command -v dnf5 >/dev/null 2>&1
        set pkg_manager "dnf5"
    else if command -v dnf >/dev/null 2>&1
        set pkg_manager "dnf"
    else if command -v zypper >/dev/null 2>&1
        set pkg_manager "zypper"
    else
        echo "Error: No supported package manager found"
        return 1
    end

    # Per-manager command fragments for search/install/reinstall/remove/info.
    # Build once here instead of re-switching inside every operation below.
    set -l pm_sync
    set -l pm_search
    set -l pm_install
    set -l pm_reinstall
    set -l pm_remove
    set -l pm_autoremove
    set -l pm_clean
    set -l pm_info

    switch $pkg_manager
        case apt
            set pm_sync       sudo apt update
            set pm_search     apt search
            set pm_install    sudo apt install -y
            set pm_reinstall  sudo apt reinstall -y
            set pm_remove     sudo apt purge -y --auto-remove
            set pm_autoremove sudo apt autoremove --purge -y
            set pm_clean      sudo apt clean
            set pm_info       apt show
        case pacman
            set pm_search     pacman -Ss
            set pm_install    sudo pacman -S --noconfirm
            set pm_reinstall  sudo pacman -S --noconfirm
            set pm_remove     sudo pacman -Rns --noconfirm
            set pm_clean      sudo pacman -Scc --noconfirm
            set pm_info       pacman -Si
        case dnf dnf5
            set pm_search     $pkg_manager search
            set pm_install    sudo $pkg_manager install -y
            set pm_reinstall  sudo $pkg_manager reinstall -y
            set pm_remove     sudo $pkg_manager remove -y
            set pm_autoremove sudo $pkg_manager autoremove -y
            set pm_clean      sudo $pkg_manager clean all
            set pm_info       $pkg_manager info
        case zypper
            set pm_search     zypper search
            set pm_install    sudo zypper install -y
            set pm_reinstall  sudo zypper install -y --force
            set pm_remove     sudo zypper remove -y
            set pm_clean      sudo zypper clean --all
            set pm_info       zypper info
    end

    set -l operation $argv[1]

    switch $operation
        case search tellme
            if test (count $argv) -lt 2
                echo "Error: search requires a package name"
                return 1
            end
            
            if test -z "$argv[2]"
                echo "Error: search requires a non-empty package name"
                return 1
            end
            
            echo "Searching for '$argv[2]' using $pkg_manager..."
            $pm_search $argv[2]

        case install gimme
            if test (count $argv) -lt 2
                echo "Error: install requires at least one package name"
                return 1
            end
            
            echo "Installing packages with $pkg_manager: $argv[2..-1]"
            if test -n "$pm_sync"
                $pm_sync
            end
            $pm_install $argv[2..-1] && $pm_clean

        case reinstall tryagain
            if test (count $argv) -lt 2
                echo "Error: reinstall requires at least one package name"
                return 1
            end
            
            echo "Reinstalling packages with $pkg_manager: $argv[2..-1]"
            if test -n "$pm_sync"
                $pm_sync
            end
            $pm_reinstall $argv[2..-1] && $pm_clean

        case remove nuke
            if test (count $argv) -lt 2
                echo "Error: remove requires at least one package name"
                return 1
            end
            
            echo "Removing packages with $pkg_manager: $argv[2..-1]"
            if $pm_remove $argv[2..-1]
                if test -n "$pm_autoremove"
                    $pm_autoremove
                end
                $pm_clean
            end

        case upgrade iago
            echo "Performing full system upgrade with $pkg_manager..."
            switch $pkg_manager
                case apt
                    echo "=> Updating repos..."
                    sudo apt update
                    echo "==> Performing full upgrade..."
                    sudo apt full-upgrade -y
                    echo "===> Removing unnecessary packages..."
                    sudo apt autoremove --purge -y
                    echo "====> Cleaning up..."
                    sudo apt clean
                case pacman
                    set -l aur_helper
                    if command -v paru >/dev/null 2>&1
                        set aur_helper "paru"
                    else if command -v yay >/dev/null 2>&1
                        set aur_helper "yay"
                    else
                        echo "=> No AUR helper found; installing paru..."
                        sudo pacman -S --needed --noconfirm base-devel git
                        set -l build_dir (mktemp -d)
                        if git clone --quiet https://aur.archlinux.org/paru.git $build_dir
                            pushd $build_dir
                            makepkg -si --noconfirm
                            popd
                        end
                        rm -rf $build_dir
                        if command -v paru >/dev/null 2>&1
                            set aur_helper "paru"
                        else
                            echo "=> paru install failed; falling back to pacman"
                        end
                    end

                    if test -n "$aur_helper"
                        echo "=> Upgrading with $aur_helper (covers repo + AUR)..."
                        $aur_helper -Syu --noconfirm
                        echo "==> Trimming $aur_helper + pacman cache..."
                        $aur_helper -Sc --noconfirm
                    else
                        echo "=> Upgrading with pacman..."
                        sudo pacman -Syu --noconfirm
                    end

                    echo "=> Removing orphans..."
                    set -l orphans (pacman -Qtdq 2>/dev/null)
                    if test -n "$orphans"
                        sudo pacman -Rns --noconfirm $orphans
                    end

                    if test -z "$aur_helper"
                        echo "=> Cleaning package cache..."
                        sudo pacman -Sc --noconfirm
                    end
                case dnf dnf5
                    echo "=> Performing upgrade..."
                    sudo $pkg_manager upgrade --refresh -y
                    echo "==> Removing unnecessary packages..."
                    sudo $pkg_manager autoremove -y
                    echo "===> Cleaning up..."
                    sudo $pkg_manager clean all
                case zypper
                    echo "=> Performing upgrade..."
                    sudo zypper update -y
                    echo "==> Removing unnecessary packages..."
                    sudo zypper remove -u
                    echo "===> Cleaning up..."
                    sudo zypper clean --all
            end

        case info
            if test (count $argv) -lt 2
                echo "Error: info requires a package name"
                return 1
            end
            
            $pm_info $argv[2]

        case desktop wutdt
            echo "Desktop Environment Info:"
            echo "Desktop: $XDG_CURRENT_DESKTOP"
            echo "Session: $GDMSESSION"
            echo "Display Server: $XDG_SESSION_TYPE"
            
        case pid gettoppid
            if test (count $argv) -lt 2
                echo "Error: pid requires a process name"
                return 1
            end

            set -l pids (pgrep -d , $argv[2])
            if test -z "$pids"
                echo "Error: no running process matching '$argv[2]'"
                return 1
            end
            top -p $pids

        case '*'
            echo "Error: Unknown operation '$operation'"
            echo "Valid operations: search, install, reinstall, remove, upgrade, info, desktop, pid"
            return 1
    end
end
