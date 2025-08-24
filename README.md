# Dotfiles

Personal configuration files and preferences.  
This repo is intended to be portable across machines (desktop, laptop, servers) and is separate from [`framework-setup`](https://github.com/knight-scott/framework-setup), which handles system-specific provisioning for my Framework 13 laptop.

---

## Structure

```
.dotfiles
├── bash/ # Bash configuration (aliases, environment, etc.)
├── config/ # App configs (e.g., ~/.config/*)
├── obsidian/ # Obsidian plugins & settings
├── lib.sh # Shared shell functions (color helpers, logging, etc.)
├── install.sh # Entry point for symlinking & setup
└── README.md # This file
```

---

## Installation

Clone this repo into `~/.dotfiles`:

```bash
git clone git@github.com:knight-scott/dotfiles.git ~/.dotfiles
```
Run the installer:
```bash
~/.dotfiles/install.sh
```
This will:

- Create symlinks for dotfiles into $HOME
- Set up ~/.config/ overrides
- Copy / link Obsidian plugin configs
- Source lib.sh for helper functions

---

## Integration with Framework Setup

Run system setup script first if setting up new laptop install:
```bash
git clone git@github.com:knight-scott/framework-setup.git ~/framework-setup
cd ~/framework-setup
./setup.sh
```
That script will:

- Install required packages
- Clone this repo into ~/.dotfiles
- Run install.sh to apply dotfiles

## Updating Dotfiles

Make changes locally, then commit & push:
```bash
cd ~/.dotfiles
git add .
git commit -m "Update bash aliases and Obsidian plugins"
git push
```
Pull updates on another machine:
```bash
cd ~/.dotfiles
git pull
./install.sh
```

## Ignored Files

Some machine-specific or runtime files are ignored via .gitignore:

- Obsidian plugin data.json and cache.json
- OS cruft (.DS_Store, Thumbs.db)

## Notes

- Keep system-specific scripts in `framework-setup`, not here
- Use this repo for **protable preferences** only
- `install.sh` is safe to run multiple times (idempotent)

---
*0x4B*