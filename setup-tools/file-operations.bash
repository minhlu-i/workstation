# Shared atomic writes; callers provide fail(). Keep the deployed backup path.
backup=''
write_owned() {
    local source=$1 destination=$2 relative=$3 mode=${4:-644} temporary
    [[ ! -d $destination ]] || fail "Expected a file, found directory: $destination"
    if [[ -f $destination && ! -L $destination ]] && cmp -s "$source" "$destination"; then
        chmod "$mode" "$destination"
        return
    fi
    if [[ -e $destination || -L $destination ]]; then
        if [[ -z $backup ]]; then
            mkdir -p "$HOME/.local/state/workstation/bash-workstation/backups"
            backup=$(mktemp -d "$HOME/.local/state/workstation/bash-workstation/backups/$(date -u +%Y%m%dT%H%M%SZ)-XXXXXX")
            printf 'Backup: %s\n' "$backup"
        fi
        mkdir -p "$(dirname -- "$backup/$relative")"
        cp -a -- "$destination" "$backup/$relative"
    fi
    mkdir -p "$(dirname -- "$destination")"
    temporary=$(mktemp "${destination}.XXXXXX")
    cp -- "$source" "$temporary"
    chmod "$mode" "$temporary"
    mv -f -- "$temporary" "$destination"
}
write_user() {
    local source=$1 destination=$2
    if [[ ! -e $destination && ! -L $destination ]]; then
        mkdir -p "$(dirname -- "$destination")"
        # Noclobber also protects against another setup process creating this file.
        (set -o noclobber; cat "$source" > "$destination")
    fi
}
