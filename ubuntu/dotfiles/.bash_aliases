# Python and Pip.
alias python='python3.8'
alias pip='pip3'

# List all files and folders in current directory
# with permissions, owners and modification dates.
alias lsl='ls -la'

# List all files and folders in current directory
# with their sizes, sorted by size in ascending order.
alias lss='du -bahd1 | sort -rh'

# Show disk usage with total.
alias lsd='df -h --total'

# Find a command in terminal history.
# Usage 1: hg <command>
# Usage 2: hg '<regex>'
alias hg='history | grep'

# Git.
alias gs='git status'
alias gfp='git fetch -p'
alias glo='git log --oneline'

# Jupyter Lab.
alias jl='jupyter lab'

# Bpython.
alias bp='bpython'
