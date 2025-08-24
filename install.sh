#!/bin/bash
# install.sh - Installs and links.Dotfiles and configures Obsidian vault.
# Symlinks dotfiles safely, backing up existing configs.
# Sets up community plugins and special handling for Obsidian LiveSync plugin.

set -euo pipefail
source "$(dirname "$0")/lib.sh"  # Import shared functions

# Trap errors and call the centralized error handler
trap 'error_handler ${LINENO} $?' ERR

# === Configuration ===
DOTFILES_DIR="$HOME/.dotfiles"
VAULT_DIR="$HOME/Documents/Obsidian Vault/.obsidian"

# List of dotfiles to symlink, format "source|destination"
# Add more files here as your dotfiles grow.
DOTFILES_TO_LINK=(
    "$DOTFILES_DIR/bash/bashrc|$HOME/.bashrc"
    "$DOTFILES_DIR/config/alacritty.yml|$HOME/.config/alacritty/alacritty.yml"
    "$DOTFILES_DIR/config/nvim/init.vim|$HOME/.config/nvim/init.vim"
)

# link_file: Symlinks a source file to destination safely.
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

# install_dotfiles: Iterates over DOTFILES_TO_LINK and symlinks each pair.
# Splits string with '|' delimiter for source and destination paths.
install_dotfiles() {
    color_echo "$CYAN" "Linking general dotfiles..."
    local IFS='|'
    for entry in "${DOTFILES_TO_LINK[@]}"; do
        read -r src dest <<< "$entry"
        link_file "$src" "$dest"
    done
    color_echo "$GREEN" "General dotfiles installed!"
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
        cp "$DOTFILES_DIR/obsidian/default-livesync-data.json" "$live_dir/data.json"
        color_echo "$CYAN" "Applied default LiveSync config"
    else
        color_echo "$YELLOW" "LiveSync config already exists, skipping"
    fi

    color_echo "$GREEN" "Obsidian setup complete!"
}

# === Main Execution ===
install_dotfiles
install_obsidian
