#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
if [[ ${1-} == --help && $# == 1 ]]; then
    printf 'Usage: setup.sh [--shell bash|zsh]\nInstalls tools, shell, basic Git and Docker, then runs doctor.\nGit identity, SSH and vault configuration are not performed.\n'
    exit 0
fi
shell_args=()
if (( $# )); then
    [[ $# == 2 && $1 == --shell && ( $2 == bash || $2 == zsh ) ]] || { printf 'Usage: setup.sh [--shell bash|zsh]\n' >&2; exit 2; }
    shell_args=("$@")
fi
for domain in setup-tools setup-shell setup-git setup-docker; do
    printf '==> Installing %s\n' "$domain"
    args=()
    [[ $domain != setup-shell ]] || args=(${shell_args[@]+"${shell_args[@]}"})
    if bash "$root/$domain/install.sh" ${args[@]+"${args[@]}"}; then :; else
        status=$?
        printf 'FAIL installation step: %s (exit %s)\n' "$domain" "$status" >&2
        exit "$status"
    fi
done
printf '==> Checking implemented domains with doctor\n'
exec bash "$root/doctor/check.sh" ${shell_args[@]+"${shell_args[@]}"}
