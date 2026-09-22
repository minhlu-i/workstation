__workstation_load_flyline() {
    local directory library
    [[ $(type -t flyline) == builtin ]] && return 0
    command -v mise >/dev/null 2>&1 || return 1
    directory=$(mise where github:HalFrgrd/flyline 2>/dev/null) || return 1
    while IFS= read -r -d '' library; do
        if enable -f "$library" flyline; then
            return 0
        fi
    done < <(find "$directory" -type f -name 'libflyline.so*' -print0)
    return 1
}
if __workstation_load_flyline && flyline mouse --mode disabled && flyline set-style --default-theme dark; then
    __workstation_flyline_ready=1
else
    printf 'workstation: Flyline could not initialize; run setup-bash-workstation --verify.\n' >&2
fi
unset -f __workstation_load_flyline
