# Loaded after local.zsh so syntax highlighting can observe all widgets.
if (( ! $+functions[_zsh_highlight] )); then
    __workstation_source_plugin zsh-syntax-highlighting || return
fi
__workstation_highlighting_ready=1
