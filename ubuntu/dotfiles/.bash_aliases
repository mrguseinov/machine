# Python and pip.
alias python='python3'
alias pytohn='python3'
alias pip='pip3'

# Print all files and folders in the current directory
# with their permissions, owners, and modification dates.
alias lsl='ls -la'

# Print all files and folders in the current directory
# with their sizes, sorted by size in ascending order.
alias lss='du -bahd1 | sort -rh'

# Print the file count per directory at the current directory level.
alias lsc='find . -type f | cut -d/ -f2 | uniq -c | sort -nr'

# Print disk usage with total.
alias lsd='df -h --total'

# Find the previously used command in the terminal history.
# Usage 1: hg <command>
# Usage 2: hg '<regex>'
alias hg='history | grep -i'

# Git.
alias gs='git status -u'
alias gf='git fetch -p'
alias gl='git log --oneline'
alias gb='git branch -va'
alias gc='git commit -m'
alias gp='git push'

# Jupyter Lab.
alias jl='jupyter lab'

# Virtualenv.
alias va='source .venv/bin/activate'
alias vb='virtualenv .venv && source .venv/bin/activate && pip install black'
alias vr='virtualenv .venv && source .venv/bin/activate && pip install -r requirements.txt'

# Find files and directories.
# https://stackoverflow.com/a/59519116
alias ff='sudo find / -ignore_readdir_race -type f,s -iname'
alias fd='sudo find / -ignore_readdir_race -type d -iname'

# Create and extract archives.
alias tc='tar cvzf'
alias tx='tar xvzf'

# Systemctl.
alias start='sudo systemctl start'
alias stop='sudo systemctl stop'
alias reload='sudo systemctl reload'
alias restart='sudo systemctl restart'
alias status='sudo systemctl status'
alias dl='sudo systemctl daemon-reload'

# Journalctl.
alias logsl='sudo journalctl --no-hostname --lines 50 --unit'  # Recent logs.
alias logsf='sudo journalctl --no-hostname --follow --unit'  # Tail (live) logs.
alias logsla='sudo journalctl --no-hostname -u mongod -u nginx -u assistant --lines'
alias logsfa='sudo journalctl --no-hostname -u mongod -u nginx -u assistant --follow'
alias loa="sudo echo; logsfa > out.log &"

# Search processes.
format='-eo pid,user,group,%cpu,%mem,start,command'
alias psg="ps $format | head -1; ps $format | grep"

# MongoDB.
alias mongo='sudo mongosh mongodb://%2Frun%2Fmongodb%2Fmongodb-27017.sock'
alias mongoa='sudo mongosh mongodb://%2Frun%2Fmongodb%2Fmongodb-27017.sock/assistant'

######################################################################################
#                     https://github.com/cykerway/complete-alias                     #
######################################################################################

complete_alias="$HOME/complete_alias"
bash_completion="$HOME/.bash_completion"
source_command="source $complete_alias"

if [ ! -f "$complete_alias" ]; then
    wget https://raw.githubusercontent.com/cykerway/complete-alias/master/complete_alias
fi

if [ ! -f "$bash_completion" ] || ! grep -Fxq "$source_command" $bash_completion; then
    echo "$source_command" >> $bash_completion
fi

complete -F _complete_alias "${!BASH_ALIASES[@]}"

######################################################################################
