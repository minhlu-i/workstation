# OS prerequisites and privilege validation for installing a missing Homebrew.
# Passwords are handled exclusively by sudo on the user's terminal.
require_bootstrap_sudo() {
    command -v sudo >/dev/null 2>&1 || fail 'sudo is required for bootstrap; ask an administrator to prepare the prerequisites.'
    if sudo -n -v 2>/dev/null; then return; fi
    [[ -t 0 ]] || fail 'Bootstrap needs sudo authentication. Run setup in an interactive terminal, or authenticate with sudo -v first.'
    printf 'Bootstrap requires administrator privileges; sudo will prompt in this terminal.\n'
    sudo -v || fail 'sudo authentication failed or was cancelled; bootstrap stopped.'
}
prepare_ubuntu_bootstrap() {
    local entry command package found existing
    local packages=()
    for entry in cc:build-essential make:build-essential ps:procps curl:curl file:file git:git; do
        command=${entry%%:*}; package=${entry#*:}
        command -v "$command" >/dev/null 2>&1 && continue
        if [[ $(dpkg-query -W -f='${Status}' "$package" 2>/dev/null || :) == 'install ok installed' ]]; then
            fail "$package is installed but $command is unavailable. Repair the installation or PATH before retrying."
        fi
        found=0
        for existing in ${packages[@]+"${packages[@]}"}; do [[ $existing != "$package" ]] || found=1; done
        (( found )) || packages+=("$package")
    done
    # HTTPS bootstrap needs the OS trust store even when curl is already present.
    [[ $(dpkg-query -W -f='${Status}' ca-certificates 2>/dev/null || :) == 'install ok installed' ]] || packages+=(ca-certificates)
    if (( ${#packages[@]} )); then
        printf 'Missing OS bootstrap packages: %s\n' "${packages[*]}"
        require_bootstrap_sudo
        sudo apt-get update || fail 'apt-get update failed; fix the error and rerun setup.'
        sudo apt-get install --no-upgrade -y "${packages[@]}" || fail 'OS prerequisite installation failed; fix the error and rerun setup.'
    fi
    for command in cc make ps curl file git; do
        command -v "$command" >/dev/null 2>&1 || fail "Bootstrap prerequisite still missing: $command"
    done
    [[ $(dpkg-query -W -f='${Status}' ca-certificates 2>/dev/null || :) == 'install ok installed' ]] || fail 'ca-certificates is still missing after bootstrap.'
}
prepare_macos_bootstrap() {
    if ! xcode-select -p >/dev/null 2>&1; then
        printf 'Requesting Apple Command Line Tools. Complete the installation dialog, then rerun setup if it is still in progress.\n'
        xcode-select --install || fail 'Could not request Command Line Tools; complete/install them with xcode-select --install and rerun setup.'
        xcode-select -p >/dev/null 2>&1 || fail 'Command Line Tools installation is not complete. Finish the Apple dialog, then rerun setup.'
    fi
}
bootstrap_homebrew() {
    case $(uname -s) in
        Linux) prepare_ubuntu_bootstrap ;;
        Darwin) prepare_macos_bootstrap ;;
    esac
    # Homebrew runs as the user; only its privileged setup uses sudo. Validate
    # immediately before invoking its noninteractive installer, never at startup.
    require_bootstrap_sudo
    local installer
    installer=$(mktemp)
    trap 'rm -f -- "$installer"' EXIT
    curl --proto '=https' --tlsv1.2 -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$installer" || fail 'Could not download the Homebrew installer.'
    NONINTERACTIVE=1 /bin/bash "$installer" || fail 'Homebrew bootstrap failed; resolve the reported error and rerun setup.'
    rm -f -- "$installer"
    trap - EXIT
    load_tool_environment
    [[ -n $BREW ]] || fail 'Homebrew installed outside standard paths; add its bin directory to PATH and retry.'
}
