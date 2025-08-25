#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Alias definitions, if ~/.bash_aliases does not exist. 

if [ -f ~/.bash_aliases ]; then
   . ~/.bash_aliases
fi

PS1='[\u@\h \W]\$ '
