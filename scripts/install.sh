#!/bin/bash
# install.sh - Uses GNU Stow to manage dotfiles and configures Obsidian vault.
# Stow creates symlinks from target directory back to organized package directories.
# Sets up community plugins and special handling for Obsidian LiveSync plugin.

set -euo pipefail
set -x
source "$(dirname "$0")/lib.sh"  # Import shared functions

# Trap errors and call the centralized error handler
trap 'error_handler ${LINENO} $?' ERR

# === Configuration ===
DOTFILES_DIR="$HOME/.dotfiles"
VAULT_DIR="$HOME/Documents/Obsidian Vault/.obsidian"
TMP_DIR="$(mktemp -d -t dotfiles-install-XXXX)"
DIFF_DIR="$TMP_DIR/diffs"

# === Temp Workspace === #
mkdir -p "$DIFF_DIR"

cleanup() {
    rm -rf "$TMP_DIR"
}

trap cleanup EXIT

# === TODO ===
# Make terminal agnostic by checking for terminal type 
# Currently must move .bashrc with mv ~/.bashrc ~/.bashrc.bak
# Add Unix versatility

# backup_conflicts: Backs up any existing files that would conflict with stow
# === TODO ===
# Fix checks. Presence of .bashrc stops install
# Check Fix 1. Checks for conflicts like .bashrc or .bash_aliases
get_conflicts() {
    local package=$1

    stow --no --verbose=1 \
        --target="$HOME" \
        --dir="$DOTFILES_DIR" \
        "$package" 2>&1 |
    awk '/cannot stow/ {
        for (i=1; i<=NF; i++) {
            if ($i == "target") {
                print ENVIRON["HOME"] "/" $(i+1)
            }
        }
    }'
}

# Generate diff files
generate_diff() {
    local src=$1    # dotfiles version
    local dest=$2   # existing system file
    local diff_out=$3

    diff -u "$dest" "$src" > "$diff_out" || true
}

# Interactive Conflict Resolver
resolve_conflict() {
    local src=$1
    local dest=$2
    local rel_path="${dest#$HOME/}"
    local diff_file="$DIFF_DIR/${rel_path//\//_}.diff"
    local merged_tmp="$TMP_DIR/merged_$(basename "$dest")"

    generate_diff "$src" "$dest" "$diff_file"

    while true; do
        color_echo "$YELLOW" "Conflict detected: $dest"
        echo
        color_echo "$CYAN" "[R]eplace [S]kip  [V]iew diff [M]erge [A]bort"
        read -rp "> " choice

        case "$choice" in
            R|r)
                backup_if_exists "$dest"
                rm -f "$dest"
                return 0 # proceed with stow
                ;;
            S|s)
                color_echo "$CYAN" "Skipping $dest"
                return 1 # skip file
                ;;
            V|v)
                ${PAGER:-less} "$diff_file"
                ;;
            M|m)
                if ! check_meld; then
                    continue
                fi
                cp "$dest" "$merged_tmp"
                meld "$merged_tmp" "$src"
                color_echo "$CYAN" "Save merged file and press Enter to continue"
                read -r

                backup_if_exists "$dest"
                cp "$merged_tmp" "$dest"
                return 0
                ;;
            A|a)
                color_echo "$RED" "Aborting install"
                exit 1
                ;;
            *)
                color_echo "$YELLOW" "Invalid choice"
                ;;
        esac
    done
}

# discover_packages(): only stow what already exists
discover_packages() {
    shopt -s nullglob
    for dir in "$DOTFILES_DIR"/*/; do
        pkg="$(basename "$dir")"
        case "$pkg" in
            scripts|docs) continue ;;
        esac
        echo "$pkg"
    done
    shopt -u nullglob
}

# install_stow_package: Installs a single stow package with conflict handling
install_stow_package() {
    local package=$1
    local package_dir="$DOTFILES_DIR/$package"

    [ -d "$package_dir" ] || return

    color_echo "$CYAN" "Installing stow package: $package"

    # 1. Detect conflicts
    mapfile -t conflicts < <(get_conflicts "$package")

    # 2. Resolve each conflict
    for dest in "${conflicts[@]}"; do
        local src="$package_dir/${dest#$HOME/}"

        if ! resolve_conflict "$src" "$dest"; then
            color_echo "$YELLOW" "Skipping $dest due to unresolved conflict"
        fi
    done

    # 3. Safely stow
    #color_echo "$BLUE" "DEBUG: Running stow for $package"
    # change verbose to '1' after debugging
    stow --verbose=1 --target="$HOME" --dir="$DOTFILES_DIR" "$package"
    #color_echo "$BLUE" "DEBUG: stow exit code: $?"

    color_echo "$GREEN" "Installed package: $package"
}

# install_dotfiles: Uses stow to install all configured packages
install_dotfiles() {
    color_echo "$CYAN" "Installing dotfiles with GNU Stow..."
    check_stow
    
    while read -r package; do
        install_stow_package "$package"
    done < <(discover_packages)
    
    color_echo "$GREEN" "All dotfiles installed with Stow!"
}

# link_file: Symlinks a source file to destination safely (kept for Obsidian setup)
# Backs up destination if it exists and is not already a symlink.
# === TODO ===
# Set up user interactions. If already a symlink, ask user to [S]kip or [R]eplace

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
        # debug - Print files to be copied. Comment out when done.
        #color_echo "$YELLOW" "$DOTFILES_DIR/obsidian/plugins/default-livesync/"*
        # Copy default-livesync to obsidian-livesync
        cp -r "$DOTFILES_DIR/obsidian/plugins/default-livesync/"* "$live_dir/"
        color_echo "$CYAN" "Applied default LiveSync config"
    else
        color_echo "$YELLOW" "LiveSync config already exists, skipping"
    fi

    color_echo "$GREEN" "Obsidian setup complete!"
}

install_code_extensions() {
    if ! command -v code >/dev/null 2>&1; then
        color_echo "$CYAN" "[INFO] Installing VS Code extensions..."
        return
    fi

    local ext_file="$HOME/.dotfiles/code/extensions.txt"

    if [[ ! -f "$ext_file" ]]; then
        color_echo "$YELLOW" "[WARN] No VS Code extensions file found"
        return
    fi

    color_echo "$CYAN" "[INFO] Installing VS Code extensions..."

    while read -r ext; do
        [[ -z "$ext" || "$ext" =~ ^# ]] && continue
        color_echo "$CYAN" "[INFO]  → Installing $ext"
        code --install-extension "$ext" --force
    done < "$ext_file"
}

# === Main Execution ===
install_dotfiles
install_obsidian
install_code_extensions

# === TODO ===
# Make script interactive.
# If called by setup.sh script, by-pass checks 
# If run independently, check if a fresh install
# If a fresh install, verify user is Ok with replacing any duplicates found
# If NOT a fresh install, ask user to [S]kip or [R]eplace duplicates
