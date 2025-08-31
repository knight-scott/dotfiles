#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# colors
# source lib.sh for colors
if [ -f ~/.dotfiles/lib.sh ]; then
  source <(grep '^[A-Z]*=' ~/.dotfiles/lib.sh)
fi

# source files
[ -r /usr/share/bash-completion/completions ] &&
  . /usr/share/bash-completion/completions/*

# exports
export PATH="${HOME}/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:"
export PATH="${PATH}/usr/local/sbin:/opt/bin:/usr/bin/core_perl:/usr/games/bin:"

if [[ $EUID -eq 0 ]]; then
  export PS1="\[$BLUE\][ \[$CYAN\]\H \[$DARKGREY\]\w\[$DARKGREY\] \[$BLUE\]]\\[$DARKGREY\]# \[$NC\]"
else
  export PS1="\[$BLUE\][ \[$CYAN\]\H \[$DARKGREY\]\w\[$DARKGREY\] \[$BLUE\]]\\[$CYAN\]\$ \[$NC\]"
fi

export LD_PRELOAD=""
export EDITOR="vim"

# enable color support of ls
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# Alias definitions, if ~/.bash_aliases does not exist. 

if [ -f ~/.bash_aliases ]; then
   . ~/.bash_aliases
fi

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
shopt -s globstar