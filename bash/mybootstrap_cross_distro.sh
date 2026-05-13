#!/usr/bin/env bash
# This script has been superseded by bootstrap.sh at the root of the didactic-waddle repo.

NEW_SCRIPT="https://raw.githubusercontent.com/jspractice-1480122229/didactic-waddle/trunk/bootstrap.sh"

printf "\n!! mybootstrap_cross_distro.sh has been superseded.\n\n"
printf "   The new modular bootstrap script is bootstrap.sh.\n"
printf "   It supports the same distros plus --dry-run, --mod <name>, and more.\n\n"
printf "   Run it directly:\n"
printf "     curl -fsSL %s | bash\n\n" "$NEW_SCRIPT"
printf "   Or with options (e.g. list available modules):\n"
printf "     bash <(curl -fsSL %s) --mod\n\n" "$NEW_SCRIPT"

read -rp "Run bootstrap.sh now? [y/N] " answer
case "$answer" in
  [yY]|[yY][eE][sS])
    exec bash <(curl -fsSL "$NEW_SCRIPT") "$@"
    ;;
  *)
    printf "Exiting. Run the new script manually when ready.\n"
    exit 0
    ;;
esac
