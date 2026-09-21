# Hints observe history; they never wrap or rewrite commands.
declare -A __workstation_hints_seen
# A first prompt is not a newly executed command from a previous shell's history.
if [[ ! ${__workstation_hint_last+initialized} ]]; then
    __workstation_hint_last=$(fc -ln -0 2>/dev/null) || __workstation_hint_last=''
fi
__workstation_hint() {
    local status=$? line command replacement='' option skip=0
    local -a words=()
    line=$(fc -ln -0 2>/dev/null) || return "$status"
    [[ $line != "${__workstation_hint_last-}" ]] || return "$status"
    __workstation_hint_last=$line
    # Deliberately only recognize simple leading commands, not arbitrary shell syntax.
    read -r -a words <<< "$line"
    command=${words[0]-}
    case $command in
        ls) replacement=eza ;;
        cat) replacement=bat ;;
        find) replacement=fd ;;
        man) replacement=tldr ;;
        grep)
            for option in "${words[@]:1}"; do
                if (( skip )); then skip=0; continue; fi
                case $option in
                    --) break ;;
                    --recursive|--dereference-recursive) replacement=rg; break ;;
                    -e|-f|-m|-A|-B|-C|-D|-d|--regexp|--file|--max-count|--after-context|--before-context|--context|--devices|--directories|--include|--exclude|--exclude-from|--exclude-dir) skip=1 ;;
                    --*=*) ;;
                    -*)
                        # Stop at options consuming a value, including an attached value.
                        local flags=${option#-} flag
                        while [[ -n $flags ]]; do
                            flag=${flags:0:1}; flags=${flags:1}
                            case $flag in
                                r|R) replacement=rg; break ;;
                                e|f|m|A|B|C|D|d) [[ -n $flags ]] || skip=1; break ;;
                            esac
                        done
                        [[ -z $replacement ]] || break
                        ;;
                    *) break ;;
                esac
            done
            ;;
    esac
    if [[ -n $replacement && ! ${__workstation_hints_seen[$command]+seen} ]] &&
        command -v "$replacement" >/dev/null 2>&1; then
        __workstation_hints_seen[$command]=1
        printf 'hint: try %s as an alternative to %s; see %s --help for its syntax.
' "$replacement" "$command" "$replacement" >&2
    fi
    return "$status"
}
__workstation_add_hint_hook() {
    local hook
    for hook in "${PROMPT_COMMAND[@]}"; do
        [[ $hook == __workstation_hint ]] && return
    done
    PROMPT_COMMAND=("${PROMPT_COMMAND[@]}" __workstation_hint)
}
__workstation_add_hint_hook
unset -f __workstation_add_hint_hook
