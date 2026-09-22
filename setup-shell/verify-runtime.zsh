# Runs inside real interactive Zsh; do not impose errexit on third-party init.
__workstation_verify() {
    local failures=0 name hook before
    printf 'Zsh %s\n' "$ZSH_VERSION"
    [[ ${__workstation_zsh_loaded-} == 1 ]] || { printf 'FAIL Zsh startup not loaded\n' >&2; ((failures+=1)); }
    for name in "${__workstation_startup_failures[@]}"; do
        printf 'FAIL startup file returned nonzero: %s\n' "$name" >&2
        ((failures+=1))
    done
    for name in mise zoxide starship; do
        if ! command -v "$name"; then
            printf 'FAIL missing %s\n' "$name" >&2; ((failures+=1))
        elif ! "$name" --version >/dev/null; then
            printf 'FAIL executable: %s\n' "$name" >&2; ((failures+=1))
        fi
    done
    for name in z prompt_starship_precmd _mise_hook _zsh_autosuggest_start _zsh_highlight compdef; do
        (( $+functions[$name] )) || { printf 'FAIL initialization: %s\n' "$name" >&2; ((failures+=1)); }
    done
    [[ ${__workstation_completion_ready-} == 1 && ${__workstation_suggestions_ready-} == 1 && ${__workstation_highlighting_ready-} == 1 ]] || {
        printf 'FAIL completion or editor plugins\n' >&2; ((failures+=1))
    }
    [[ $HISTFILE == "$HOME/.zsh_history" && $HISTSIZE == 1000 && $SAVEHIST == 2000 && -o appendhistory && -o histignoredups && -o histignorespace ]] || {
        printf 'FAIL native history configuration\n' >&2; ((failures+=1))
    }
    for name in __workstation_hint __workstation_verify_first __workstation_verify_second prompt_starship_precmd; do
        local count=0
        for hook in "${precmd_functions[@]}"; do [[ $hook != "$name" ]] || ((count+=1)); done
        (( count == 1 )) || { printf 'FAIL precmd hook integrity: %s\n' "$name" >&2; ((failures+=1)); }
    done
    before=$(typeset -p precmd_functions preexec_functions chpwd_functions 2>/dev/null)
    source "$HOME/.zshrc"
    [[ $(typeset -p precmd_functions preexec_functions chpwd_functions 2>/dev/null) == "$before" ]] || {
        printf 'FAIL duplicate startup hooks\n' >&2; ((failures+=1))
    }
    starship prompt >/dev/null || { printf 'FAIL Starship prompt\n' >&2; ((failures+=1)); }
    (( failures == 0 )) || return 1
    printf 'PASS Zsh workstation runtime\n'
}
__workstation_verify
