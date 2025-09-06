#!/bin/bash
# Script to backup XFCE4 settings selectively

set -euo pipefail
source "$(dirname "$0")/lib.sh"  # Import shared functions

# Trap errors and call the centralized error handler
trap 'error_handler ${LINENO} $?' ERR

DOTFILES_CONFIG="$HOME/.dotfiles/config"
mkdir -p "$DOTFILES_CONFIG/xfce4/xfconf/xfce-perchannel-xml"
mkdir -p "$DOTFILES_CONFIG/xfce4/panel"

# Copy essential XFCE4 settings
color_echo "$CYAN" "Copying essential xfce settings"

cp ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml "$DOTFILES_CONFIG/xfce4/xfconf/xfce-perchannel-xml/"
cp ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml "$DOTFILES_CONFIG/xfce4/xfconf/xfce-perchannel-xml/"
cp ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml "$DOTFILES_CONFIG/xfce4/xfconf/xfce-perchannel-xml/"
cp ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml "$DOTFILES_CONFIG/xfce4/xfconf/xfce-perchannel-xml/"
cp -r ~/.config/xfce4/panel/ "$DOTFILES_CONFIG/xfce4/"

color_echo "$GREEN" "Essential XFCE4 settings backed up to dotfiles"

# === TODO ===
# add other DE for versitility