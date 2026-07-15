alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'

alias gs='git status -sb'
alias gd='git diff'
alias gl='git log --oneline --decorate --graph --all'
alias gsw='git switch'

alias t='tmux new-session -A -s main'
alias tl='tmux ls'
alias tk='tmux kill-session -t'
alias ta='tmux attach -t'

mkd() { mkdir -p "$1" && cd "$1"; }

