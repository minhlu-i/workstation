#!/usr/bin/env bash
set -euo pipefail
module=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
mode=${1-}
case $mode in
    ''|--configure-only) (( $# <= 1 )) || exit 2 ;;
    --help) printf 'Usage: setup-tools/install.sh [--configure-only|--help]\n'; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$mode" >&2; exit 2 ;;
esac
fail() { printf 'setup-tools/install.sh: %s\n' "$*" >&2; exit 1; }
[[ ${XDG_CONFIG_HOME:-$HOME/.config} == "$HOME/.config" ]] || fail 'XDG_CONFIG_HOME must be ~/.config for this module.'
[[ ${MISE_CONFIG_DIR:-$HOME/.config/mise} == "$HOME/.config/mise" ]] || fail 'MISE_CONFIG_DIR must be ~/.config/mise.'
[[ -z ${MISE_GLOBAL_CONFIG_FILE-} ]] || fail 'Unset MISE_GLOBAL_CONFIG_FILE before setup.'
source "$module/dependencies.bash"
load_tool_environment
if [[ $mode != --configure-only ]]; then
    case $(uname -s) in
        Darwin) ;;
        Linux) source /etc/os-release; [[ $ID == ubuntu ]] || fail 'Supported Linux platform: Ubuntu/WSL2 Ubuntu.' ;;
        *) fail 'Supported platforms: macOS and Ubuntu/WSL2 Ubuntu.' ;;
    esac
    if [[ -z $BREW ]]; then
        source "$module/bootstrap.bash"
        bootstrap_homebrew
    fi
    "$BREW" --version >/dev/null || fail 'Homebrew is installed but broken.'
    # Do not let installing one missing formula update existing packages.
    export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_UPGRADE=1
    for command in curl git less xz mise; do ensure_command "$command" "$command"; done
fi
source "$module/file-operations.bash"
source "$module/../setup-shell/manifest.bash"
migrate_legacy_shell_manifest
configure_mise_tools "$module/files/mise.toml" "$HOME/.config/mise/conf.d/bash-workstation.toml" .config/mise/conf.d/bash-workstation.toml "$mode"
if [[ $mode == --configure-only ]]; then
    printf 'Tools configuration generated; no packages or tools installed.\n'
else
    source "$module/zed.bash"
    install_zed
    bash "$module/verify.sh"
fi
