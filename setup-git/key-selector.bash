# Native checkbox selector: no additional CLI dependency or key material.
checkbox_keys() {
    local file=$1 label count current=0 top=0 index end mark pointer key sequence total
    local labels=() selected=()
    while IFS= read -r label; do labels+=("$label"); done < <(jq -r '.[] | "\(.name) [\(.id)]"' "$file")
    count=${#labels[@]}
    [[ $count -gt 0 ]] || return 1
    # Keep raw input active across key reads so arrow sequences are not flushed.
    selector_terminal_settings=$(stty -g) || return 1
    restore_selector() {
        stty "$selector_terminal_settings" >/dev/null 2>&1 || :
        printf '\033[?25h\033[?1049l' >&2
    }
    # Runs in a command-substitution subshell; always restore its terminal.
    trap restore_selector EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    stty -echo -icanon min 1 time 0 || return 1
    printf '\033[?1049h\033[?25l' >&2
    while :; do
        total=0
        for ((index=0; index<count; index++)); do
            [[ ${selected[index]:-0} == 0 ]] || total=$((total + 1))
        done
        [[ $current -ge $top ]] || top=$current
        [[ $current -lt $((top + 10)) ]] || top=$((current - 9))
        end=$((top + 10)); [[ $end -le $count ]] || end=$count
        printf '\033[H\033[2JSSH keys: %s found, %s selected\nArrows: move | Space: toggle | a: select all | Enter: confirm | Esc: cancel\n\n' "$count" "$total" >&2
        for ((index=top; index<end; index++)); do
            mark=' '; pointer=' '
            [[ ${selected[index]:-0} == 0 ]] || mark=x
            [[ $index != "$current" ]] || pointer='>'
            printf '%s [%s] %s\n' "$pointer" "$mark" "${labels[index]}" >&2
        done
        printf '\nShowing %s-%s of %s\n' "$((top + 1))" "$end" "$count" >&2
        key=''
        IFS= read -rsn1 key || return 1
        case $key in
            ' ') selected[current]=$((1 - ${selected[current]:-0})) ;;
            a) for ((index=0; index<count; index++)); do selected[index]=1; done ;;
            j) [[ $current -ge $((count - 1)) ]] || current=$((current + 1)) ;;
            k) [[ $current -le 0 ]] || current=$((current - 1)) ;;
            ''|$'\r')
                [[ $total -gt 0 ]] || continue
                for ((index=0; index<count; index++)); do
                    [[ ${selected[index]:-0} == 0 ]] || printf '%s\n' "$((index + 1))"
                done | jq -sc 'map(tonumber)'
                return 0 ;;
            $'\033')
                sequence=''
                IFS= read -rsn2 -t 1 sequence || return 1
                case $sequence in
                    '[A'|'OA') [[ $current -le 0 ]] || current=$((current - 1)) ;;
                    '[B'|'OB') [[ $current -ge $((count - 1)) ]] || current=$((current + 1)) ;;
                esac ;;
        esac
    done
}
