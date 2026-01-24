alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# list BlackArch packages
alias blacklist='pacman -Sg | grep blackarch | sed 's/^blackarch-//' | sort'

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias vi="vim"

alias dir='dir --color=auto'
alias vdir='vdir --color=auto'

alias ping='ping -c 3'

alias alias-list="cat ~/.dotfiles/bash/.bash_aliases"

# security/privacy aliases
alias wget="wget -U 'noleak'"
alias curl="curl --user-agent 'noleak'"
alias shred="shred -zf"

# Network interface management
alias wifiup='sudo ip link set wlan0 up'
alias wifidown='sudo ip link set wlan0 down'
alias ethup='sudo ip link set eth0 up'
alias ethdown='sudo ip link set eth0 down'
alias vpn='protonvpn connect'

# Quick network info
alias myip='curl -s ifconfig.me'
alias localip='ip route get 1 | awk "{print \$7}" | head -n1'
alias netstat='netstat -tuln'
alias ports='ss -tuln'
alias connections='ss -tupln'

# WiFi scanning and info
alias wifiscan='sudo iw dev wlan0 scan | grep -E "SSID|signal"'
alias wifiinfo='iwconfig'

# ADB shortcuts
alias adbdevices='adb devices -l'
alias adbshell='adb shell'
alias adblog='adb logcat'
alias adbinstall='adb install -r'
alias adbuninstall='adb uninstall'
alias adbpush='adb push'
alias adbpull='adb pull'
alias adbroot='adb root && adb shell'

# Frida shortcuts
alias fridalist='frida-ps -U'
alias fridaapps='frida-ps -Ua'
alias fridaspawn='frida -U -f'

# APK analysis
alias apkinfo='aapt dump badging'
alias apkperms='aapt dump permissions'

# Quick scans and recon
alias nmap-quick='nmap -T4 -F'
alias nmap-tcp='nmap -sS -O -v'
alias nmap-udp='nmap -sU -v'
alias portscan='nmap -Pn --top-ports 1000'

# Hash checking
alias md5='md5sum'
alias sha1='sha1sum'
alias sha256='sha256sum'

# Process monitoring
alias psg='ps aux | grep'
alias topcpu='ps aux --sort=-%cpu | head'
alias topmem='ps aux --sort=-%mem | head'

# Quick file operations for analysis
alias hexdump='hexdump -C'
alias strings-all='strings -a'
alias file-type='file -b'
