# Ignore insecure completion directories, without disabling compinit's audit.
autoload -Uz compinit
compinit -i -d "$HOME/.config/zsh/.zcompdump" || return
__workstation_completion_ready=1
