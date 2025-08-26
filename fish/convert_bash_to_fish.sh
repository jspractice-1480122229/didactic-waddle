#!/usr/bin/env bash
#
# FILE: convert_bash_to_fish.sh
#
# A modular script to convert Bash aliases and functions files
# into idiomatic Fish shell files, following the "one function per file"
# convention.
#
# This script is designed to be run after the source files have been
# downloaded or placed in the correct location. It does NOT contain
# the source code itself.
#
# Usage:
#   ./convert_bash_to_fish.sh <path_to_bash_aliases> <path_to_bash_functions>
#
# Example:
#   ./convert_bash_to_fish.sh ~/.bash_aliases ~/.bash_functions

set -euo pipefail

# --- User-facing Messages ---
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_RED='\033[0;31m'
COLOR_NC='\033[0m' # No Color

log_info() {
    echo -e "${COLOR_GREEN}[INFO]${COLOR_NC} $1"
}

log_warn() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_NC} $1"
}

log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_NC} $1" >&2
}

# Check for correct number of arguments
if [ "$#" -ne 2 ]; then
    log_error "Incorrect number of arguments."
    log_error "Usage: $0 <path_to_bash_aliases> <path_to_bash_functions>"
    exit 1
fi

BASH_ALIASES_FILE="$1"
BASH_FUNCTIONS_FILE="$2"

# Verify that input files exist
if [ ! -f "${BASH_ALIASES_FILE}" ]; then
    log_error "Bash aliases file not found: ${BASH_ALIASES_FILE}"
    exit 1
fi

if [ ! -f "${BASH_FUNCTIONS_FILE}" ]; then
    log_error "Bash functions file not found: ${BASH_FUNCTIONS_FILE}"
    exit 1
fi

# --- Main Conversion Logic ---

# Create Fish config directories
log_info "Creating Fish configuration directories..."
FISH_CONFIG_DIR="${HOME}/.config/fish"
FISH_FUNCTIONS_DIR="${FISH_CONFIG_DIR}/functions"
mkdir -p "${FISH_FUNCTIONS_DIR}"
log_info "Fish directories created at ${FISH_CONFIG_DIR}"

# --- Convert Aliases ---
log_info "Converting Bash aliases from ${BASH_ALIASES_FILE}..."

# Convert simple aliases
grep '^\s*alias' "${BASH_ALIASES_FILE}" | \
    sed -E "s/alias ([^=]+)='(.*)'/alias \1 '\2'/g" > "${FISH_CONFIG_DIR}/aliases.fish"

# Convert aliases with `command -v ... && alias ...` checks
# We will extract the final alias part and append it.
grep 'command -v' "${BASH_ALIASES_FILE}" | \
    sed -E "s/command -v [^ ]+ &>\/dev\/null && alias ([^=]+)='(.*)'/alias \1 '\2'/g" >> "${FISH_CONFIG_DIR}/aliases.fish"

log_info "Aliases converted and saved to ${FISH_CONFIG_DIR}/aliases.fish"

# --- Convert Functions ---
log_info "Converting Bash functions from ${BASH_FUNCTIONS_FILE} and separating into individual files..."

# Use awk to split the file by function definition and perform syntax conversion
awk '
    /^[^#].*() {/ {
        # Found a new function. Get its name.
        sub("() {", "", $1)
        name=$1
        if (name == "") { next }
        print "---NEW_FUNC_START---", name > "/dev/stderr"
        
        # Print the function header
        print "# Converted from Bash"
        print "function " name " -d \"(Description converted from Bash)\""
    }
    
    # Process the body of the function
    /^{/ { next } # Skip the opening brace
    /^}/ {
        # Found closing brace. Print "end" and move on.
        print "end"
        print "---NEW_FUNC_END---" > "/dev/stderr"
        next
    }
    
    # Simple syntax replacements within the function body
    # "$@" -> "$argv"
    # $1, $2 -> $argv[1], $argv[2]
    # echo -> echo
    # if [ -z "$1" ] -> if test (count $argv) -eq 0
    # if [ ! -f "$1" ] -> if not test -f "$argv[1]"
    # local var="val" -> set -l var "val"
    {
        gsub("\\$@","\$argv")
        gsub("\\$1","\$argv[1]")
        gsub("\\$2","\$argv[2]")
        gsub("if \\[\s*-z\s*\"\\$argv[1]\"\s*\\]; then", "if test (count $argv) -eq 0; then")
        gsub("if \\[\s*!\s*-f\s*\"\\$argv[1]\"\s*\\]; then", "if not test -f \"$argv[1]\"")
        gsub("local ","set -l ")
        
        # Convert case...esac to switch...end
        if ($0 ~ /^\s*case /) {
            sub("case \"\\$argv[1]\" in", "switch \"$argv[1]\"")
            gsub(";;", "") # Remove case terminators
        } else if ($0 ~ /^\s*esac/) {
            $0 = "end"
        }
        
        print
    }
' "${BASH_FUNCTIONS_FILE}" | \
    awk '
    # This second awk script handles writing to individual files
    /^---NEW_FUNC_START---/ {
        # Start of a new function, set the output file
        name=$2
        output_file="'"${FISH_FUNCTIONS_DIR}"'/" name ".fish"
        next
    }
    
    /^---NEW_FUNC_END---/ {
        # End of a function, close the file
        close(output_file)
        print "[INFO] Converted " name ".fish"
        next
    }
    
    {
        # Write content to the current file
        print > output_file
    }
'

log_info "Conversion complete!"
log_warn "Please review the generated files for accuracy before using them."
log_warn "Remember to reload your shell or start a new Fish session for changes to take effect."
