#
# ~/.bashrc
#

# Append "$1" to $PATH when not already in.
append_path () {
    case ":$PATH:" in
        *:"$1":*)
            ;;
        *)
            PATH="${PATH:+$PATH:}$1"
    esac
}

# --- PATH Configuration ---
# Set up the base PATH 
export PATH="/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/opt/bin:/usr/bin/core_perl:/usr/games/bin:${PATH}"

# Append standard directories
append_path "$HOME/bin"
append_path "$HOME/.local/bin"
append_path "/usr/local/bin"  # Ensure this is included

# Created by `pipx` on 2026-01-12 19:29:02
append_path "/home/research/.local/bin"

### EXPORT ### Should be before the change of the shell
export EDITOR="/usr/bin/nvim"  # Using nvim preference over vim
export VISUAL='nano'
export HISTCONTROL=ignoreboth:erasedups:ignorespace
HISTSIZE=100000
HISTFILESIZE=2000000
shopt -s histappend
export PAGER='most'

export TERM=xterm-256color
export SHELL=$(which bash)

# Security/Pentesting exports
export SECLISTS="/usr/share/seclists"
export PAYLOADSALLTHETHINGS="/usr/share/payloadsallthethings"
export FUZZDB="/usr/share/fuzzdb"

export MIMIKATZ="/usr/share/windows/mimikatz/"
export POWERSPLOIT="/usr/share/windows/powersploit/"

export ROCKYOU="$SECLISTS/Passwords/Leaked-Databases/rockyou.txt"
export DIRSMALL="$SECLISTS/Discovery/Web-Content/DirBuster-2007_directory-list-2.3-small.txt"
export DIRMEDIUM="$SECLISTS/Discovery/Web-Content/DirBuster-2007_directory-list-2.3-medium.txt"
export DIRBIG="$SECLISTS/Discovery/Web-Content/DirBuster-2007_directory-list-2.3-big.txt"
export WEBAPI_COMMON="$SECLISTS/Discovery/Web-Content/api/api-endpoints.txt"
export WEBAPI_MAZEN="$SECLISTS/Discovery/Web-Content/common-api-endpoints-mazen160.txt"
export WEBCOMMON="$SECLISTS/Discovery/Web-Content/common.txt"
export WEBPARAM="$SECLISTS/Discovery/Web-Content/burp-parameter-names.txt"

# Additional exports from your config
export LD_PRELOAD=""

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# --- One-time setup ---
if [[ $1 != no-repeat-flag && -z $NO_REPETITION ]]; then
  export NO_REPETITION=1
  fastfetch -l Anarchy | lolcat
fi

# colors
# source lib.sh for colors
if [ -f ~/.dotfiles/lib.sh ]; then
  source <(grep '^[A-Z]*=' ~/.dotfiles/lib.sh)
fi

# Optional: Source Blesh if installed
[[ $1 != no-repeat-flag && -f /usr/share/blesh/ble.sh ]] && source /usr/share/blesh/ble.sh

# --- Bash completion ---
[[ $PS1 && -f /usr/share/bash-completion/bash_completion ]] && . /usr/share/bash-completion/bash_completion

# Source individual completions if needed (your addition, but commented out as it might be redundant)
# [ -r /usr/share/bash-completion/completions ] && . /usr/share/bash-completion/completions/*

# --- Aliases ---
if [ -f ~/.bash_aliases ]; then
  . ~/.bash_aliases
fi

# --- Shell behavior ---
shopt -s autocd
shopt -s cdspell
shopt -s cmdhist
shopt -s dotglob
shopt -s histappend
shopt -s expand_aliases
shopt -s globstar  # Your globstar setting

# --- ex (extractor helper) ---
ex () {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2)   tar xjf "$1"   ;;
      *.tar.gz)    tar xzf "$1"   ;;
      *.bz2)       bunzip2 "$1"   ;;
      *.rar)       unrar x "$1"   ;;
      *.gz)        gunzip "$1"    ;;
      *.tar)       tar xf "$1"    ;;
      *.tbz2)      tar xjf "$1"   ;;
      *.tgz)       tar xzf "$1"   ;;
      *.zip)       unzip "$1"     ;;
      *.Z)         uncompress "$1";;
      *.7z)        7z x "$1"      ;;
      *.deb)       ar x "$1"      ;;
      *.tar.xz)    tar xf "$1"    ;;
      *.tar.zst)   tar xf "$1"    ;;
      *)           echo "'$1' cannot be extracted via ex()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# --- Git helpers ---
vimod () {
  vim -p $(git status -suall | awk '{print $2}')
}

virev () {
  local commit=${1:-HEAD}
  local rootdir=$(git rev-parse --show-toplevel)
  local sourceFiles=$(git show --name-only --pretty="format:" "$commit" | grep -v '^$')
  local toOpen=""
  for file in $sourceFiles; do
    local fullpath="$rootdir/$file"
    [ -e "$fullpath" ] && toOpen="$toOpen $fullpath"
  done
  if [ -z "$toOpen" ]; then
    echo "No files were modified in $commit"
    return 1
  fi
  vim -p $toOpen
}

gitPrompt() {
  command -v __git_ps1 > /dev/null && __git_ps1 " (%s)"
}

# --- cd up helper ---
cu () {
  local count=$1
  [[ -z "$count" ]] && count=1
  local upath=""
  for i in $(seq 1 $count); do
    upath+="../"
  done
  cd "$upath"
}

# --- Memory cleaning helper ---
buffer_clean(){
  free -h && sudo sh -c 'echo 1 > /proc/sys/vm/drop_caches' && free -h
}

# --- AWS completion (your addition) ---
complete -C "/usr/local/bin/aws_completer" aws

# --- Starship prompt (your addition) ---
# Note: This will override the fish-style dynamic prompt below if enabled
# eval "$(starship init bash)"

# --- Fish-style dynamic prompt (disabled if using starship) ---
# Uncomment the PROMPT_COMMAND below if you prefer the fish-style prompt
# over starship, or comment out the starship line above

set_bash_prompt() {
  local last_status=$?
  local tty_device=$(tty)
  local ip=$(ip -4 addr | grep -v '127.0.0.1' | grep -v 'secondary' \
    | grep -oP '(?<=inet\s)\d+(\.\d+){3}' \
    | sed -z 's/\n/|/g;s/|\$/\n/' \
    | rev | cut -c 2- | rev)

  local user="\u"
  local host="\h"
  local cwd="\w"
  local branch=""
  local hq_prefix=""
  local flame=""
  local robot=""

  if command -v git &>/dev/null; then
    branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  fi

  if [[ "$tty_device" == /dev/tty* ]]; then
    hq_prefix="HQ─"
    flame=""
    robot="[>]"
  else
    hq_prefix="HQ🚀🌐"
    flame="🔥"
    robot="[👾]"
  fi

  if [[ $last_status -eq 0 ]]; then
    user_host="\[\e[1;34m\]($user@$host)\[\e[0m\]"
  else
    user_host="\[\e[1;31m\]($user@$host)\\[\e[0m\]"
  fi

  local line1="\[\e[1;32m\]╭─[$hq_prefix\[\e[1;31m\]$ip\[\e[1;32m\]$flame]─$user_host"
  if [[ -n "$branch" ]]; then
    line1+="\[\e[1;33m\][ $branch]\[\e[0m\]"
  fi

  local line2="\[\e[1;32m\]╰─>$robot\[\e[1;36m\]$cwd \$\[\e[0m\]"

  PS1="${line1}\n${line2} "
}

# Choose your prompt: uncomment ONE of the following:
# Option 1: Fish-style prompt
PROMPT_COMMAND='set_bash_prompt'

# Option 2: Starship prompt (uncomment and comment the line above)
# eval "$(starship init bash)"
