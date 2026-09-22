# Shell owns these declarations, including migration from the combined fragment.
shell_manifest_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
write_shell_manifest() {
    configure_mise_tools "$shell_manifest_root/files/$shell_name/mise.toml" \
        "$HOME/.config/mise/conf.d/setup-shell.toml" .config/mise/conf.d/setup-shell.toml "$mode"
}
migrate_legacy_shell_manifest() {
    local legacy=$HOME/.config/mise/conf.d/bash-workstation.toml temporary
    if [[ -f $legacy && ! -e $HOME/.config/mise/conf.d/setup-shell.toml ]] &&
        grep -Eq '^[[:space:]]*"(starship|zoxide|github:HalFrgrd/flyline)"[[:space:]]*=' "$legacy"; then
        # Transfer existing declarations before tools replaces the legacy file.
        # Do not alter an already-migrated shell manifest or invoke an installer.
        temporary=$(mktemp)
        printf '[tools]\n' > "$temporary"
        grep -E '^[[:space:]]*"(starship|zoxide|github:HalFrgrd/flyline)"[[:space:]]*=' "$legacy" >> "$temporary"
        write_owned "$temporary" "$HOME/.config/mise/conf.d/setup-shell.toml" .config/mise/conf.d/setup-shell.toml
        rm -f -- "$temporary"
    fi
}
