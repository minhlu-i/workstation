__workstation_source_plugin() {
    local name=$1 file
    for file in "/usr/share/$name/$name.zsh" "/usr/share/zsh/plugins/$name/$name.zsh"         "${HOMEBREW_PREFIX:-/opt/homebrew}/share/$name/$name.zsh"         "/usr/local/share/$name/$name.zsh" "/home/linuxbrew/.linuxbrew/share/$name/$name.zsh"; do
        if [[ -r $file ]]; then
            source "$file"
            return $?
        fi
    done
    printf 'workstation: missing %s; run setup-shell/install.sh.\n' "$name" >&2
    return 1
}
if (( ! $+functions[_zsh_autosuggest_start] )); then
    __workstation_source_plugin zsh-autosuggestions || return
fi
__workstation_suggestions_ready=1
