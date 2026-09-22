#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
shell_args=()
if (( $# )); then
    [[ $# == 2 && $1 == --shell && ( $2 == bash || $2 == zsh ) ]] || { printf 'Usage: doctor/check.sh [--shell bash|zsh]\n' >&2; exit 2; }
    shell_args=("$@")
fi
failures=0
for domain in setup-tools setup-shell setup-git setup-docker; do
    printf '==> Checking %s (implemented)\n' "$domain"
    args=()
    [[ $domain != setup-shell ]] || args=(${shell_args[@]+"${shell_args[@]}"})
    if bash "$root/$domain/verify.sh" ${args[@]+"${args[@]}"}; then
        printf 'PASS %s\n' "$domain"
    else
        printf 'FAIL %s\n' "$domain" >&2
        failures=$((failures+1))
    fi
done
printf 'PLANNED (not checked): setup-editor setup-workspace\n'
if (( failures )); then
    printf 'Implemented-domain checks failed: %s\n' "$failures" >&2
    exit 1
fi
printf 'Tools, shell, Git and Docker checks passed. Full workstation readiness is not assessed.\n'
