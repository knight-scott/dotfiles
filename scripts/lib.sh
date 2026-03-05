#!/bin/bash
# lib.sh - Shared utility functions used by setup.sh and install.sh
# Provides standardized color output, directory checks,
# file backup, and centralized error handling.

# ===== Color Codes for Terminal Output =====
CYAN='\033[0;36m'    # Informational messages
GREEN='\033[0;32m'   # Success messages
YELLOW='\033[1;33m'  # Warnings (e.g., backup notices)
RED='\033[0;31m'     # Errors
DARKGREY='\033[1;30m'   # Bright black, appears as dark grey on most terminals
BLUE='\033[1;34m'       # Bright/bold blue
NC='\033[0m'         # No Color (reset)

# Prevent direct execution — this file is meant to be sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    color_echo "$RED" "lib.sh is a library and should not be run directly." >&2
    exit 1
fi

# color_echo: Print colored messages to terminal.
# Arguments:
#   $1 - ANSI color code
#   $2 - message to print
color_echo() {
    local color=$1
    local msg=$2
    echo -e "${color}${msg}${NC}"
}

# error_handler: Global trap handler for errors anywhere in scripts.
# Prints the line number and the error code in red for easier debugging.
error_handler() {
    local last_line=$1
    local last_err=$2
    color_echo "$RED" "Error on line $last_line: exit status $last_err"
    exit "$last_err"
}

# checkdir: Ensures a directory exists.
# Creates the directory if it does not exist, or exits with error.
# Usage: checkdir "/path/to/directory"
checkdir() {
    local dir=$1
    if [ ! -d "$dir" ]; then
        color_echo "$CYAN" "Creating directory: $dir"
        mkdir -p "$dir" || { color_echo "$RED" "Failed to create $dir"; exit 1; }
    fi
}

# backup_if_exists: Back up an existing file or directory before overwriting.
# Adds a timestamp suffix to the backup name to avoid overwriting old backups.
# Usage: backup_if_exists "/path/to/file-or-dir"
backup_if_exists() {
    local target=$1
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        local backup="${target}.backup-$(date +%Y%m%d%H%M%S)"
        color_echo "$YELLOW" "Backing up existing $target to $backup"
        mv "$target" "$backup"
    fi
}

# check_stow: Ensures GNU Stow is installed on the system
check_stow() {
    if ! command -v stow &> /dev/null; then
        color_echo "$RED" "GNU Stow is not installed!"
        color_echo "$CYAN" "Install it with:"
        #color_echo "$CYAN" "  macOS: brew install stow"
        #color_echo "$CYAN" "  Ubuntu/Debian: sudo apt install stow"
        color_echo "$CYAN" "  Arch: sudo pacman -S stow"
        #color_echo "$CYAN" "  RHEL/CentOS: sudo yum install stow"
        exit 1
    fi
}

# check_meld: Ensure meld is installed on the system to perform merge of dotfiles
check_meld() {
    if ! command -v meld &> /dev/null; then
        color_echo "$RED" "Meld is not installed!"
        color_echo "$CYAN" "Install it with:"
        #color_echo "$CYAN" "  macOS: brew install meld"
        #color_echo "$CYAN" "  Ubuntu/Debian: sudo apt install meld"
        color_echo "$CYAN" "  Arch: sudo pacman -S meld"
        #color_echo "$CYAN" "  RHEL/CentOS: sudo yum install meld"
        return 1
    fi
}