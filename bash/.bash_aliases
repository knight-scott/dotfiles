alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
# list BlackArch packages
alias blacklist='pacman -Sg | grep blackarch | sed 's/^blackarch-//' | sort'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
