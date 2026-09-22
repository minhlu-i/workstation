# OrbStack owns the macOS runtime and bundled Docker CLI/plugins.
install_macos_docker() {
    local app
    if app=$(orbstack_app); then
        printf 'Reuse OrbStack: %s\n' "$app"
    else
        [[ -n $BREW ]] || fail 'Homebrew missing; run setup-tools/install.sh first.'
        "$BREW" --version >/dev/null || fail 'Homebrew is unavailable/broken.'
        if "$BREW" list --cask --versions orbstack >/dev/null 2>&1; then
            fail 'OrbStack cask exists but its app is missing/broken. Repair it before retrying.'
        fi
        HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_UPGRADE=1 "$BREW" install --cask orbstack || fail 'OrbStack installation failed.'
        orbstack_app >/dev/null || fail 'OrbStack app unavailable after installation. Check its installation location.'
    fi
    printf 'OrbStack supplies Docker CLI, Compose and Buildx. Open OrbStack once to finish setup/start its engine, then rerun if checks fail.\n'
    printf 'Existing Docker providers, contexts and data were not changed by this script.\n'
}
