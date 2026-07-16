# ==========================================
#  SYSADMIN BASH CONFIGURATION
# ==========================================

# --- 1. HISTORICAL LOGGING & AUDIT TRAIL ---
# Crucial for tracking what was run, when, and by whom
export HISTSIZE=50000
export HISTFILESIZE=100000
# Append to history instead of overwriting, and log timestamps (YYYY-MM-DD HH:MM:SS)
shopt -s histappend
export HISTTIMEFORMAT="%F %T "
# Ignore duplicate commands or commands starting with a space
export HISTCONTROL=ignoreboth
# Immediately flush commands to history after execution (helps if a session crashes)
export PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

# --- 2. PROTECTIVE ALIASES (SAFETY NETS) ---
# Prompt before destroying things, and show what is happening
alias rm='rm -iv'
alias cp='cp -iv'
alias mv='mv -iv'
alias ln='ln -iv'
alias chown='chown --preserve-root -v'
alias chmod='chmod --preserve-root -v'
alias chgrp='chgrp --preserve-root -v'

# --- 3. SYSTEM MONITORS & NAVIGATION ---
# Human-readable disk and memory usage
alias df='df -h'
alias du='du -h -d 1'
alias free='free -m'

# Enhanced directory listings (Colorized, human-readable, classified)
alias ls='ls --color=auto -F'
alias ll='ls -alFh'
alias la='ls -A'
alias l='ls -CF'

# Quick navigation shortcuts
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias mkdir='mkdir -pv' # Create nested directories safely

# --- 4. NETWORKING & TROUBLESHOOTING ---
# Quick check for open ports, listening services, and clean routing info
alias ports='netstat -tulanp'
alias myip='curl -s https://ifconfig.me; echo'
alias ping='ping -c 5' # Don't ping indefinitely by default

# --- 5. QUALITY OF LIFE FUNCTIONS ---

# Extract almost any archive format automatically
extract () {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar x $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Create a directory and immediately change into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# --- 6. VISUAL CLARITY (PROMPT) ---
# Highlights [USER@HOSTNAME] in bold red if you are root, or bold green if normal user.
# Includes the current working directory and the time.
if [ $(id -u) -eq 0 ]; then
    export PS1="\[\033[01;31m\][\u@\h]\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] \t \n# "
else
    export PS1="\[\033[01;32m\][\u@\h]\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] \t \n$ "
fi