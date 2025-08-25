#!/bin/bash
# secure-config-setup.sh - Safely migrate config files to stow packages

set -euo pipefail
source "$(dirname "$0")/lib.sh"  # Import shared functions

DOTFILES_DIR="$HOME/.dotfiles"
CONFIG_DIR="$HOME/.config"

# SAFE applications - these are generally safe to track
SAFE_CONFIGS=(
    "nvim"
    "alacritty" 
    "kitty"
    "wezterm"
    "i3"
    "sway" 
    "hyprland"
    "waybar"
    "polybar"
    "rofi"
    "wofi"
    "dunst"
    "mako"
    "fish"
    "starship"
    "tmux"
    "zellij" 
    "htop"
    "btop"
    "ranger"
    "fzf"
    "mpv"
    "fontconfig"  # Usually safe if you want custom fonts
)

# DANGEROUS applications - NEVER track these
DANGEROUS_CONFIGS=(
    "chromium"
    "google-chrome" 
    "firefox"
    "BraveSoftware"
    "Code - OSS"
    "VSCode"
    "code-oss"
    "discord"
    "slack"
    "docker"
    "Dropbox"
    "nextcloud"
    "syncthing"
    "pulse"
    "pipewire"
)

# Function to migrate home directory dotfiles to stow packages
migrate_home_dotfiles() {
    color_echo "$CYAN" "Checking home directory dotfiles..."
    
    for entry in "${HOME_DOTFILES[@]}"; do
        local IFS=':'
        read -r dotfile package <<< "$entry"
        
        local source_file="$HOME/$dotfile"
        local package_dir="$DOTFILES_DIR/$package"
        local dest_file="$package_dir/$dotfile"
        
        if [ ! -f "$source_file" ]; then
            color_echo "$YELLOW" "$dotfile not found in home directory, skipping..."
            continue
        fi
        
        color_echo "$GREEN" "Migrating $dotfile to $package package..."
        
        # Create package directory
        checkdir "$package_dir"
        
        # Copy the dotfile
        cp "$source_file" "$dest_file"
        
        # Check for sensitive content
        local sensitive_content
        sensitive_content=$(grep -i -E "(token|key|password|secret)" "$dest_file" 2>/dev/null | head -3 || true)
        
        if [ -n "$sensitive_content" ]; then
            color_echo "$YELLOW" "POTENTIAL SENSITIVE CONTENT found in $dotfile:"
            echo "$sensitive_content"
            color_echo "$YELLOW" "Review this file before committing to git!"
        fi
        
        color_echo "$CYAN" "Added $dotfile to $package package"
    done
}
check_and_migrate_config() {
    local app_name=$1
    local source_dir="$CONFIG_DIR/$app_name"
    local dest_package="$DOTFILES_DIR/$app_name"
    local dest_config="$dest_package/.config/$app_name"
    
    if [ ! -d "$source_dir" ]; then
        color_echo "$YELLOW" "$app_name config not found in ~/.config, skipping..."
        return
    fi
    
    # Check if it's in the dangerous list
    for dangerous in "${DANGEROUS_CONFIGS[@]}"; do
        if [ "$app_name" = "$dangerous" ]; then
            color_echo "$RED" "DANGER: $app_name is in dangerous list, NOT migrating!"
            return
        fi
    done
    
    color_echo "$GREEN" "Migrating $app_name config..."
    
    # Create the stow package directory structure
    checkdir "$dest_config"
    
    # Copy (don't move yet, safety first) the config
    cp -r "$source_dir"/* "$dest_config/"
    
    # Check for potential sensitive files in the copied directory
    local sensitive_files
    sensitive_files=$(find "$dest_config" -name "*token*" -o -name "*key*" -o -name "*secret*" -o -name "*password*" -o -name "*.pem" -o -name "*.p12" 2>/dev/null | head -5)
    
    if [ -n "$sensitive_files" ]; then
        color_echo "$YELLOW" "POTENTIAL SENSITIVE FILES found in $app_name:"
        echo "$sensitive_files"
        color_echo "$YELLOW" "Review these files before committing to git!"
    fi
    
    # Check size
    local size
    size=$(du -sh "$dest_config" | cut -f1)
    color_echo "$CYAN" "Package $app_name size: $size"
    
    if [[ "$size" =~ ^[0-9]+[MG] ]]; then
        color_echo "$YELLOW" "Large package detected! Review contents before tracking."
    fi
}

# Function to scan for unknown home directory dotfiles
scan_home_dotfiles() {
    color_echo "$CYAN" "Scanning for unknown dotfiles in home directory..."
    
    # Look for common dotfile patterns
    for dotfile in "$HOME"/.*; do
        if [ -f "$dotfile" ]; then
            local filename
            filename=$(basename "$dotfile")
            
            # Skip special files
            case "$filename" in
                "." | ".." | ".bash_history" | ".lesshst" | ".sudo_as_admin_successful" | ".cache" | ".local")
                    continue
                    ;;
            esac
            
            # Check if it's already in our HOME_DOTFILES list
            local is_known=false
            for entry in "${HOME_DOTFILES[@]}"; do
                local IFS=':'
                read -r known_dotfile package <<< "$entry"
                if [ "$filename" = "$known_dotfile" ]; then
                    is_known=true
                    break
                fi
            done
            
            if [ "$is_known" = false ]; then
                local size
                size=$(du -sh "$dotfile" | cut -f1)
                color_echo "$YELLOW" "Unknown dotfile: $filename (size: $size)"
                color_echo "$CYAN" "  Review manually: head '$dotfile'"
            fi
        fi
    done
}
scan_unknown_configs() {
    color_echo "$CYAN" "Scanning for unknown config directories..."
    
    for dir in "$CONFIG_DIR"/*/; do
        if [ -d "$dir" ]; then
            local app_name
            app_name=$(basename "$dir")
            
            # Skip if already in safe list
            local is_known=false
            for safe in "${SAFE_CONFIGS[@]}"; do
                if [ "$app_name" = "$safe" ]; then
                    is_known=true
                    break
                fi
            done
            
            # Skip if in dangerous list  
            for dangerous in "${DANGEROUS_CONFIGS[@]}"; do
                if [ "$app_name" = "$dangerous" ]; then
                    is_known=true
                    color_echo "$RED" "Found dangerous config: $app_name (NOT migrating)"
                    break
                fi
            done
            
            if [ "$is_known" = false ]; then
                local size
                size=$(du -sh "$dir" | cut -f1)
                color_echo "$YELLOW" "Unknown config: $app_name (size: $size)"
                color_echo "$CYAN" "  Review manually: ls -la '$dir'"
            fi
        fi
    done
}

# Main execution
main() {
    color_echo "$CYAN" "Setting up secure dotfiles with stow..."
    echo
    
    # First scan for unknown/potentially dangerous configs
    scan_unknown_configs
    echo
    
    # Scan for unknown home dotfiles
    scan_home_dotfiles
    echo
    
    # Migrate home directory dotfiles
    migrate_home_dotfiles
    echo
    
    # Migrate safe configs
    color_echo "$CYAN" "Migrating safe configurations..."
    for app in "${SAFE_CONFIGS[@]}"; do
        check_and_migrate_config "$app"
    done
    
    echo
    color_echo "$GREEN" "Migration complete!"
    echo
    color_echo "$CYAN" "Next steps:"
    color_echo "$CYAN" "1. Review all migrated packages for sensitive data"
    color_echo "$CYAN" "2. Update install.sh STOW_PACKAGES array with desired packages"  
    color_echo "$CYAN" "3. Test with: stow -n package-name (dry run)"
    color_echo "$CYAN" "4. Add to git: git add package-name/"
    color_echo "$CYAN" "5. Commit: git commit -m 'Add package-name config'"
}

# Safety check
if [ "$PWD" != "$DOTFILES_DIR" ]; then
    color_echo "$RED" "Please run this script from your dotfiles directory: $DOTFILES_DIR"
    exit 1
fi

main "$@"