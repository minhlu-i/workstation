# Runs in an actual interactive Bash, without forcing errexit on third-party init.
__workstation_verify() {
    local failures=0 name hook hints=0 first=0 second=0 before executable
    for name in "${__workstation_startup_failures[@]}"; do
        printf 'FAIL startup file returned nonzero: %s\n' "$name" >&2
        ((failures+=1))
    done
    if (( BASH_VERSINFO[0] < 5 || (BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] < 3) )); then
        printf 'FAIL Bash 5.3+ required\n' >&2; ((failures+=1))
    fi
    printf 'Bash %s\n' "$BASH_VERSION"
    for name in mise zoxide starship bat delta eza fd jq rg tldr yq; do
        if ! command -v "$name"; then printf 'FAIL missing %s\n' "$name" >&2; ((failures+=1)); fi
    done
    if [[ $(type -t flyline) != builtin || ${__workstation_flyline_ready-} != 1 ]]; then printf 'FAIL Flyline builtin\n' >&2; ((failures+=1)); fi
    type flyline
    for name in z starship_precmd _mise_hook_prompt_command; do
        declare -F "$name" >/dev/null || { printf 'FAIL initialization: %s\n' "$name" >&2; ((failures+=1)); }
    done
    if ! declare -F _completion_loader; then printf 'FAIL bash-completion\n' >&2; ((failures+=1)); fi
    for name in bat delta eza fd jq ripgrep starship tealdeer yq zoxide github:HalFrgrd/flyline; do
        mise where "$name" >/dev/null 2>&1 || { printf 'FAIL mise installation: %s\n' "$name" >&2; ((failures+=1)); }
    done
    for name in bat delta eza fd jq rg starship tldr yq zoxide; do
        if executable=$(mise which "$name") && "$executable" --version >/dev/null; then
            printf 'PASS executable: %s\n' "$name"
        else
            printf 'FAIL executable: %s\n' "$name" >&2; ((failures+=1))
        fi
    done
    starship --version || ((failures+=1))
    starship prompt >/dev/null || ((failures+=1))
    mise ls || ((failures+=1))
    for hook in "${PROMPT_COMMAND[@]}"; do
        case $hook in
            __workstation_hint) ((hints+=1)) ;;
            '__workstation_verify_first=1') first=1 ;;
            '__workstation_verify_second=1') second=1 ;;
        esac
    done
    (( hints == 1 && first == 1 && second == 1 )) || { printf 'FAIL PROMPT_COMMAND integrity\n' >&2; ((failures+=1)); }
    before=$(declare -p PROMPT_COMMAND)
    source "$HOME/.bashrc"
    [[ $(declare -p PROMPT_COMMAND) == "$before" ]] || { printf 'FAIL duplicate startup hooks\n' >&2; ((failures+=1)); }
    declare -p PROMPT_COMMAND
    (( failures == 0 )) || return 1
    printf 'PASS Bash workstation runtime\n'
}
__workstation_verify
