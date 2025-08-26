#!/bin/bash
# install.sh - Uses GNU Stow to manage dotfiles and configures Obsidian vault.
# Stow creates symlinks from target directory back to organized package directories.
# Sets up community plugins and special handling for Obsidian LiveSync plugin.

set -euo pipefail
source "$(dirname "$0")/lib.sh"  # Import shared functions

# Trap errors and call the centralized error handler
trap 'error_handler ${LINENO} $?' ERR

# === Configuration ===
DOTFILES_DIR="$HOME/.dotfiles"
VAULT_DIR="$HOME/Documents/Obsidian Vault/.obsidian"

# List of stow packages to install
# Each package should have its files organized to mirror the target structure
STOW_PACKAGES=(
    "bash"
    "face"
    "git" 
    "nvim"
    "starship"
    "fzf"
    "bat"
    "htop"
)

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

# backup_conflicts: Backs up any existing files that would conflict with stow
backup_conflicts() {
    local package=$1
    color_echo "$CYAN" "Checking for conflicts in package: $package"
    
    # Use stow --no to simulate and find conflicts
    local conflicts
    conflicts=$(stow --no --verbose=2 --target="$HOME" --dir="$DOTFILES_DIR" "$package" 2>&1 | grep "existing target is" || true)
    
    if [ -n "$conflicts" ]; then
        color_echo "$YELLOW" "Found conflicts, backing up existing files..."
        echo "$conflicts" | while read -r line; do
            if [[ "$line" =~ existing\ target\ is\ (.+)\ but\ is ]]; then
                local conflict_file="${BASH_REMATCH[1]}"
                if [ -e "$conflict_file" ] && [ ! -L "$conflict_file" ]; then
                    backup_if_exists "$conflict_file"
                fi
            fi
        done
    fi
}

# install_stow_package: Installs a single stow package with conflict handling
install_stow_package() {
    local package=$1
    local package_dir="$DOTFILES_DIR/$package"
    
    if [ ! -d "$package_dir" ]; then
        color_echo "$YELLOW" "Package directory $package_dir not found, skipping..."
        return
    fi
    
    color_echo "$CYAN" "Installing stow package: $package"
    
    # Check for and backup any conflicting files
    backup_conflicts "$package"
    
    # Install the package with stow
    stow --verbose=1 --target="$HOME" --dir="$DOTFILES_DIR" "$package"
    
    color_echo "$GREEN" "Installed package: $package"
}

# install_dotfiles: Uses stow to install all configured packages
install_dotfiles() {
    color_echo "$CYAN" "Installing dotfiles with GNU Stow..."
    
    check_stow
    
    for package in "${STOW_PACKAGES[@]}"; do
        install_stow_package "$package"
    done
    
    color_echo "$GREEN" "All dotfiles installed with Stow!"
}

# link_file: Symlinks a source file to destination safely (kept for Obsidian setup)
# Backs up destination if it exists and is not already a symlink.
link_file() {
    local src=$1
    local dest=$2

    # Ensure destination directory exists before linking
    checkdir "$(dirname "$dest")"

    # Remove existing symlink or backup existing file before linking
    if [ -L "$dest" ]; then
        color_echo "$CYAN" "Removing existing symlink: $dest"
        rm "$dest"
    elif [ -e "$dest" ]; then
        backup_if_exists "$dest"
    fi

    ln -s "$src" "$dest"
    color_echo "$GREEN" "Linked $src → $dest"
}

# install_obsidian: Sets up Obsidian vault plugins.
# Symlinks the community plugin list and each plugin directory except LiveSync.
# Applies default LiveSync configuration if none exists.
install_obsidian() {
    color_echo "$CYAN" "Setting up Obsidian configs..."

    checkdir "$VAULT_DIR/plugins"

    # Symlink community plugins list JSON
    link_file "$DOTFILES_DIR/obsidian/community-plugins.json" "$VAULT_DIR/community-plugins.json"

    # Loop and symlink each plugin folder except 'obsidian-livesync'
    for plugin in "$DOTFILES_DIR/obsidian/plugins"/*/; do
        [ -d "$plugin" ] || continue
        plugin_name=$(basename "$plugin")
        if [ "$plugin_name" == "obsidian-livesync" ]; then
            color_echo "$YELLOW" "Skipping LiveSync (sensitive data)"
            continue
        fi
        link_file "$plugin" "$VAULT_DIR/plugins/$plugin_name"
    done

    # Ensure LiveSync plugin folder exists and apply default config if missing
    local live_dir="$VAULT_DIR/plugins/obsidian-livesync"
    checkdir "$live_dir"
    if [ ! -f "$live_dir/data.json" ]; then
        cp -r "$DOTFILES_DIR/obsidian/plugins/default-livesync/*" "$live_dir/"
        color_echo "$CYAN" "Applied default LiveSync config"
    else
        color_echo "$YELLOW" "LiveSync config already exists, skipping"
    fi

    color_echo "$GREEN" "Obsidian setup complete!"
}

# === Main Execution ===
install_dotfiles
install_obsidian