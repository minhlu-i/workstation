# Discover existing Homebrew without invoking it or changing provider precedence.
__workstation_brew=${commands[brew]-}
if [[ -z $__workstation_brew ]]; then
    for __workstation_candidate in "${HOMEBREW_PREFIX:-/opt/homebrew}/bin/brew" /home/linuxbrew/.linuxbrew/bin/brew /usr/local/bin/brew; do
        if [[ -x $__workstation_candidate ]]; then
            __workstation_brew=$__workstation_candidate
            break
        fi
    done
fi
if [[ -n $__workstation_brew ]]; then
    export HOMEBREW_PREFIX=${__workstation_brew%/bin/brew}
    for __workstation_directory in "$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin"; do
        (( ${path[(Ie)$__workstation_directory]} )) || path+=("$__workstation_directory")
    done
fi
unset __workstation_brew __workstation_candidate __workstation_directory
__workstation_dedupe_path() {
    local -a unique_path
    local entry
    local -A seen
    for entry in "${path[@]}"; do
        if [[ ! ${seen[x$entry]+present} ]]; then
            seen[x$entry]=1
            unique_path+=("$entry")
        fi
    done
    path=("${unique_path[@]}")
    export PATH
}
path=("$HOME/.local/bin" "${path[@]}")
__workstation_dedupe_path
if (( $+commands[lesspipe] )); then
    eval "$(SHELL=/bin/sh lesspipe)"
fi
