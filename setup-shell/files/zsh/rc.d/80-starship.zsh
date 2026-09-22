if (( $+commands[starship] )); then
    export STARSHIP_CONFIG="$HOME/.config/starship.toml"
    eval "$(starship init zsh)"
fi
