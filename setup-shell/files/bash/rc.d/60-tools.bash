if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash)"
    # Activation normally populates PATH on the first prompt; zoxide is needed now.
    eval "$(mise env --shell bash)"
fi
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi
