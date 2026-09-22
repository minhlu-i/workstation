# Zed is an application dependency; settings and extensions remain user-owned.
zed_is_wsl() {
    [[ $(uname -s) == Linux ]] || return 1
    [[ -n ${WSL_DISTRO_NAME-}${WSL_INTEROP-} ]] || uname -r | grep -qi microsoft
}
zed_location() {
    local candidate
    local candidates=()
    candidate=$(command -v zed 2>/dev/null || :)
    case $candidate in */mise/shims/*|"${MISE_DATA_DIR:-$HOME/.local/share/mise}"/shims/*) candidate= ;; esac
    candidates=("$candidate" "$HOME/.local/bin/zed")
    if [[ $(uname -s) == Darwin ]]; then
        candidates+=(/Applications/Zed.app/Contents/MacOS/cli "$HOME/Applications/Zed.app/Contents/MacOS/cli")
    fi
    for candidate in "${candidates[@]}"; do
        if [[ -x $candidate ]] && "$candidate" --version >/dev/null 2>&1; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}
zed_present() {
    command -v zed >/dev/null 2>&1 && return 0
    case $(uname -s) in
        Darwin) [[ -e /Applications/Zed.app || -L /Applications/Zed.app || -e $HOME/Applications/Zed.app || -L $HOME/Applications/Zed.app ]] ;;
        Linux) [[ -e $HOME/.local/zed.app || -L $HOME/.local/zed.app || -e $HOME/.local/bin/zed || -L $HOME/.local/bin/zed || -e $HOME/.local/share/applications/dev.zed.Zed.desktop || -L $HOME/.local/share/applications/dev.zed.Zed.desktop ]] ;;
        *) return 1 ;;
    esac
}
install_zed() {
    local location installer status=0
    if zed_is_wsl; then printf 'SKIP Zed: WSL; install the editor on Windows separately.\n'; return; fi
    if location=$(zed_location); then printf 'Reuse Zed: %s\n' "$location"; return; fi
    # Upstream installers may replace these paths; preserve partial installs.
    zed_present && fail 'Zed is installed but unavailable/broken; repair it before retrying.'
    case $(uname -s) in
        Darwin)
            if "$BREW" list --cask zed >/dev/null 2>&1; then
                fail 'Zed is installed but unavailable/broken; repair it before retrying.'
            fi
            HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_UPGRADE=1 "$BREW" install --cask zed || fail 'Zed cask installation failed.'
            ;;
        Linux)
            installer=$(mktemp) || fail 'Could not create a temporary Zed installer.'
            curl --proto '=https' --tlsv1.2 -fsSL https://zed.dev/install.sh -o "$installer" || status=$?
            if (( status == 0 )); then
                (unset ZED_BUNDLE_PATH; ZED_CHANNEL=stable ZED_VERSION=latest sh "$installer") || status=$?
            fi
            rm -f -- "$installer"
            (( status == 0 )) || fail 'Zed installation failed; resolve the reported error and rerun.'
            ;;
        *) fail 'Zed installation supports macOS and Ubuntu.' ;;
    esac
    hash -r
    zed_location >/dev/null || fail 'Zed installed but its CLI is unavailable/broken.'
}
verify_zed() {
    if zed_is_wsl; then printf 'SKIP Zed: WSL.\n'; return; fi
    zed_location >/dev/null || { fail 'Missing/broken Zed; run setup-tools/install.sh.'; return 1; }
}
