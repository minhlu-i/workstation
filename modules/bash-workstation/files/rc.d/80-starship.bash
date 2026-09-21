if command -v starship >/dev/null 2>&1; then
    export STARSHIP_CONFIG="$HOME/.config/starship.toml"
    __workstation_prompt_hooks=("${PROMPT_COMMAND[@]}")
    unset PROMPT_COMMAND
    eval "$(starship init bash)"
    PROMPT_COMMAND=("${PROMPT_COMMAND[@]}" "${__workstation_prompt_hooks[@]}")
    unset __workstation_prompt_hooks
fi
