alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# list BlackArch packages
alias blacklist='pacman -Sg | grep blackarch | sed 's/^blackarch-//' | sort'

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias dir='dir --color=auto'
alias vdir='vdir --color=auto'

alias ping='ping -c 3'