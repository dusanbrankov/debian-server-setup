# allow running aliases with sudo
alias sudo='sudo '
alias s='sudo systemctl'

# default options
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias mv='mv -i'
alias ls='ls -h --color=auto --group-directories-first'

alias brc='$EDITOR $HOME/.bashrc'
alias src='source $HOME/.bashrc'

# files
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'
alias l1='ls -1'
alias ll='ls -l'
alias la='ls -lA'

# bookmarks
alias gtwww='cd /var/www && ls -lh'
alias gta2='cd /etc/apache2'

# shorts
alias a='${EDITOR:-vi} $HOME/.bash_aliases'
alias c='clear'
alias e='exit'
alias hg='history | grep'
alias h='history'
alias i='sudo apt-get install -y'
alias j='jobs'
alias ui='sudo apt-get update && sudo apt-get install -y'
alias uu='sudo apt-get update && sudo apt-get upgrade -y'
alias ud='sudo apt-get update && sudo apt-get dist-upgrade -y'

# git
alias ga='git add'
alias gc='git commit'
alias gcm='git commit -m'
alias gd='git diff'
alias gh="git help"
alias gl='git log --stat --relative-date'
alias gpl='git pull'
alias gplr='git pull --rebase'
alias gpsf='git push --force'
alias gps='git push'
alias gr="git restore"
alias grs="git restore --staged"
alias gst='git status'
alias gs='git status --short'
alias gswc='git switch --create'
alias gsw='git switch'
