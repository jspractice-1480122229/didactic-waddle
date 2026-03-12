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
            switch $pkg_manager
                case apt
                    apt search $argv[2]
                case pacman
                    pacman -Ss $argv[2]
                case dnf dnf5
                    $pkg_manager search $argv[2]
                case zypper
                    zypper search $argv[2]
            end

        case install gimme
            if test (count $argv) -lt 2
                echo "Error: install requires at least one package name"
                return 1
            end
            
            echo "Installing packages with $pkg_manager: $argv[2..-1]"
            switch $pkg_manager
                case apt
                    sudo apt update && sudo apt install -y $argv[2..-1] && sudo apt clean
                case pacman
                    sudo pacman -S --noconfirm $argv[2..-1] && sudo pacman -Scc --noconfirm
                case dnf dnf5
                    sudo $pkg_manager install -y $argv[2..-1] && sudo $pkg_manager clean all
                case zypper
                    sudo zypper install -y $argv[2..-1] && sudo zypper clean --all
            end

        case reinstall tryagain
            if test (count $argv) -lt 2
                echo "Error: reinstall requires at least one package name"
                return 1
            end
            
            echo "Reinstalling packages with $pkg_manager: $argv[2..-1]"
            switch $pkg_manager
                case apt
                    sudo apt update && sudo apt reinstall -y $argv[2..-1] && sudo apt clean
                case pacman
                    sudo pacman -S --noconfirm $argv[2..-1] && sudo pacman -Scc --noconfirm
                case dnf dnf5
                    sudo $pkg_manager reinstall -y $argv[2..-1] && sudo $pkg_manager clean all
                case zypper
                    sudo zypper install -y --force $argv[2..-1] && sudo zypper clean --all
            end

        case remove nuke
            if test (count $argv) -lt 2
                echo "Error: remove requires at least one package name"
                return 1
            end
            
            echo "Removing packages with $pkg_manager: $argv[2..-1]"
            switch $pkg_manager
                case apt
                    sudo apt purge -y --auto-remove $argv[2..-1] && sudo apt autoremove --purge -y && sudo apt clean
                case pacman
                    sudo pacman -Rns --noconfirm $argv[2..-1] && sudo pacman -Scc --noconfirm
                case dnf dnf5
                    sudo $pkg_manager remove -y $argv[2..-1] && sudo $pkg_manager autoremove -y && sudo $pkg_manager clean all
                case zypper
                    sudo zypper remove -y $argv[2..-1] && sudo zypper clean --all
            end

        case upgrade iago
            echo "Performing full system upgrade with $pkg_manager..."
            switch $pkg_manager
                case apt
                    echo "=> Updating repos..."
                    sudo apt update
                    echo "==> Removing unnecessary packages..."
                    sudo apt autoremove -y
                    echo "===> Performing full upgrade..."
                    sudo apt full-upgrade -y
                    echo "====> Cleaning up..."
                    sudo apt autoremove --purge -y && sudo apt clean
                case pacman
                    echo "=> Updating repos..."
                    sudo pacman -Syy
                    echo "==> Removing orphans..."
                    set -l orphans (pacman -Qtdq 2>/dev/null)
                    if test -n "$orphans"
                        sudo pacman -Rns --noconfirm $orphans
                    end
                    echo "===> Performing upgrade..."
                    sudo pacman -Syu --noconfirm
                    echo "====> Cleaning up..."
                    sudo pacman -Scc --noconfirm
                case dnf dnf5
                    echo "=> Checking updates..."
                    sudo $pkg_manager check-update
                    echo "==> Removing unnecessary packages..."
                    sudo $pkg_manager autoremove -y
                    echo "===> Performing upgrade..."
                    sudo $pkg_manager upgrade --refresh -y
                    echo "====> Cleaning up..."
                    sudo $pkg_manager clean all
                case zypper
                    echo "=> Refreshing repos..."
                    sudo zypper refresh
                    echo "==> Removing unnecessary packages..."
                    sudo zypper remove -u
                    echo "===> Performing upgrade..."
                    sudo zypper update -y
                    echo "====> Cleaning up..."
                    sudo zypper clean --all
            end

        case info
            if test (count $argv) -lt 2
                echo "Error: info requires a package name"
                return 1
            end
            
            switch $pkg_manager
                case apt
                    apt show $argv[2]
                case pacman
                    pacman -Si $argv[2]
                case dnf dnf5
                    $pkg_manager info $argv[2]
                case zypper
                    zypper info $argv[2]
            end

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
            top -p (pgrep -d , $argv[2])

        case '*'
            echo "Error: Unknown operation '$operation'"
            echo "Valid operations: search, install, reinstall, remove, upgrade, info, desktop, pid"
            return 1
    end
end
