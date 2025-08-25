alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# list BlackArch packages
alias blacklist='pacman -Sg | grep blackarch | sed 's/^blackarch-//' | sort'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'

alias ping='ping -c 3'

# Server connection
alias server='ssh -p 1337 knight@192.168.86.34'