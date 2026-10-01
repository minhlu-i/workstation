# Provider-aware dependency helpers, compatible with the macOS system Bash.
# Discovery never writes files or invokes package managers.
append_tool_path() {
    case :$PATH: in *:"$1":*) ;; *) PATH="$PATH:$1" ;; esac
}
load_tool_environment() {
    BREW=$(command -v brew 2>/dev/null || :)
    if [[ -z $BREW ]]; then
        for candidate in /opt/homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew /usr/local/bin/brew; do
            if [[ -x $candidate ]]; then BREW=$candidate; break; fi
        done
    fi
    if [[ -n $BREW ]]; then
        export HOMEBREW_PREFIX=${BREW%/bin/brew}
        append_tool_path "$HOMEBREW_PREFIX/bin"
        append_tool_path "$HOMEBREW_PREFIX/sbin"
    fi
    append_tool_path "$HOME/.local/bin"
    export PATH
}
working_command() {
    local location
    location=$(command -v "$1" 2>/dev/null) || return 1
    # Package-manager discovery must not execute a shim that may download.
    case $location in */mise/shims/*|"${MISE_DATA_DIR:-$HOME/.local/share/mise}"/shims/*) return 1 ;; esac
    "$location" --version >/dev/null 2>&1
}
ensure_command() {
    local executable=$1 formula=$2
    if working_command "$executable"; then
        printf 'Reuse %s: %s\n' "$executable" "$(command -v "$executable")"
        return
    fi
    [[ -n ${BREW-} ]] || fail "Missing working $executable and Homebrew; run setup-tools/install.sh."
    if "$BREW" list --versions "$formula" >/dev/null 2>&1; then
        fail "Homebrew $formula is installed but $executable is unavailable/broken; repair it or its PATH before retrying."
    fi
    HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_UPGRADE=1 "$BREW" install "$formula" || fail "Homebrew installation failed: $formula"
    hash -r
    working_command "$executable" || fail "Installed $formula but $executable is unavailable/broken."
}
tool_command() {
    case $1 in bitwarden) printf bw ;; ripgrep) printf rg ;; tealdeer) printf tldr ;; *) printf '%s' "$1" ;; esac
}
external_tool_works() {
    local executable location version
    [[ $1 != github:HalFrgrd/flyline ]] || return 1
    executable=$(tool_command "$1")
    location=$(command -v "$executable" 2>/dev/null) || return 1
    # Executing a shim can download a missing tool. Never invoke it for discovery.
    case $location in
        */mise/shims/*|*/mise/installs/*|"${MISE_DATA_DIR:-$HOME/.local/share/mise}"/*) return 1 ;;
    esac
    version=$("$location" --version 2>/dev/null) || return 1
    # Python kislyuk/yq has different semantics despite sharing the command name.
    if [[ $executable == yq ]]; then
        [[ $version == *github.com/mikefarah/yq* ]] || return 1
    fi
    return 0
}
configure_mise_tools() {
    local template=$1 destination=$2 relative=$3 mode=${4-} generated line tool
    local missing=()
    generated=$(mktemp)
    printf '[tools]\n' > "$generated"
    while IFS= read -r line; do
        case $line in '"'*'" = "'*) ;; *) continue ;; esac
        tool=${line#\"}; tool=${tool%%\"*}
        if external_tool_works "$tool"; then
            printf 'Reuse external tool: %s\n' "$tool"
        else
            printf '%s\n' "$line" >> "$generated"
        fi
    done < "$template"
    write_owned "$generated" "$destination" "$relative"
    rm -f -- "$generated"
    [[ $mode != --configure-only ]] || return 0
    while IFS= read -r line; do
        case $line in '"'*'" = "'*) ;; *) continue ;; esac
        tool=${line#\"}; tool=${tool%%\"*}
        (cd "$HOME" && mise where "$tool" >/dev/null 2>&1) || missing+=("$tool")
    done < "$destination"
    if (( ${#missing[@]} )); then
        (cd "$HOME" && mise install "${missing[@]}") || fail 'mise installation failed.'
    fi
}
verify_mise_tools() {
    local template=$1 destination=$2 line tool executable location failed=0
    if [[ ! -f $destination ]]; then printf 'Missing manifest: %s\n' "$destination" >&2; return 1; fi
    # Owned manifests contain only a tools table and exact approved declarations.
    while IFS= read -r line; do
        [[ $line == '[tools]' ]] && continue
        if ! grep -Fxq -- "$line" "$template" || [[ $line != \"* ]]; then
            printf 'Unexpected manifest content: %s\n' "$destination" >&2; failed=1
        fi
    done < "$destination"
    grep -Fxq '[tools]' "$destination" || failed=1
    # Duplicate tables/keys would make TOML invalid even if each line is approved.
    if [[ -n $(sort "$destination" | uniq -d) ]]; then
        printf 'Duplicate manifest content: %s\n' "$destination" >&2; failed=1
    fi
    while IFS= read -r line; do
        case $line in '"'*'" = "'*) ;; *) continue ;; esac
        tool=${line#\"}; tool=${tool%%\"*}
        if grep -Fxq -- "$line" "$destination"; then
            if [[ $tool == github:HalFrgrd/flyline ]]; then
                (cd "$HOME" && mise where "$tool" >/dev/null 2>&1) || { printf 'Missing mise tool: %s\n' "$tool" >&2; failed=1; }
            else
                executable=$(tool_command "$tool")
                if ! location=$(cd "$HOME" && mise which "$executable" 2>/dev/null) || ! "$location" --version >/dev/null 2>&1; then
                    printf 'Broken/missing mise tool: %s\n' "$tool" >&2; failed=1
                fi
            fi
        elif ! external_tool_works "$tool"; then
            printf 'Broken/missing external tool: %s\n' "$tool" >&2; failed=1
        fi
    done < "$template"
    return "$failed"
}
