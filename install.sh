#!/bin/bash
# install.sh - Apply dotfiles and Obsidian configs

set -euo pipefail

# Import shared functions
source "$(dirname "$0")/lib.sh"

# === CONFIG ===
DOTFILES_DIR="$HOME/.dotfiles"
VAULT_DIR="$HOME/Documents/Obsidian Vault/.obsidian"

# List of dotfiles to symlink: "source_path relative_dest"
DOTFILES_TO_LINK=(
    "$DOTFILES_DIR/bash/bashrc ~/.bashrc"
    "$DOTFILES_DIR/config/alacritty.yml ~/.config/alacritty/alacritty.yml"
    "$DOTFILES_DIR/config/nvim/init.vim ~/.config/nvim/init.vim"
)

# === Functions ===

# Symlink file into place
link_file() {
    local src=$1
    local dest=$2

    # Ensure parent directory exists
    checkdir "$(dirname "$dest")"

    if [ -L "$dest" ] || [ -f "$dest" ]; then
        color_echo "$YELLOW" "Skipping existing: $dest"
    else
        ln -s "$src" "$dest"
        color_echo "$GREEN" "Linked $src → $dest"
    fi
}

# Install general dotfiles
install_dotfiles() {
    color_echo "$CYAN" "Linking general dotfiles..."

    for entry in "${DOTFILES_TO_LINK[@]}"; do
        src=$(echo "$entry" | awk '{print $1}')
        dest=$(echo "$entry" | awk '{print $2}')
        link_file "$src" "$dest"
    done

    color_echo "$GREEN" "General dotfiles installed!"
}

# Install Obsidian configs
install_obsidian() {
    color_echo "$CYAN" "Setting up Obsidian configs..."

    checkdir "$VAULT_DIR/plugins"

    # Symlink community plugins list
    link_file "$DOTFILES_DIR/obsidian/community-plugins.json" \
              "$VAULT_DIR/community-plugins.json"

    # Symlink plugins (except LiveSync)
    for plugin in "$DOTFILES_DIR/obsidian/plugins"/*; do
        plugin_name=$(basename "$plugin")
        if [ "$plugin_name" == "obsidian-livesync" ]; then
            color_echo "$YELLOW" "Skipping LiveSync (sensitive)"
            continue
        fi
        link_file "$plugin" "$VAULT_DIR/plugins/$plugin_name"
    done

    # Handle LiveSync bootstrap
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

# === Main ===
install_dotfiles
install_obsidian
