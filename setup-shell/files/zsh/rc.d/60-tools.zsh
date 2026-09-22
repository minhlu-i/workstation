if (( $+commands[mise] )); then
    eval "$(mise activate zsh)"
    eval "$(mise env --shell zsh)"
fi
if (( $+commands[zoxide] )); then
    eval "$(zoxide init zsh)"
fi
