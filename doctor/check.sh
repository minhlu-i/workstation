#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
shell_args=()
if (( $# )); then
    [[ $# == 2 && $1 == --shell && ( $2 == bash || $2 == zsh ) ]] || { printf 'Usage: doctor/check.sh [--shell bash|zsh]\n' >&2; exit 2; }
    shell_args=("$@")
fi
pretty=0
if [[ -t 1 && -t 2 && ${TERM-} != dumb && -z ${NO_COLOR-} ]]; then
    gum_path=$(command -v gum 2>/dev/null || :)
    # Never execute mise shims here: doctor must not download missing tools.
    case $gum_path in
        ''|*/mise/shims/*|"${MISE_DATA_DIR:-$HOME/.local/share/mise}"/shims/*)
            mise_path=$(command -v mise 2>/dev/null || :)
            case $mise_path in
                ''|*/mise/shims/*) gum_path='' ;;
                *) gum_path=$(cd "$HOME" && "$mise_path" which gum 2>/dev/null || :) ;;
            esac ;;
    esac
    case $gum_path in
        ''|*/mise/shims/*|"${MISE_DATA_DIR:-$HOME/.local/share/mise}"/shims/*) ;;
        *) if [[ -x $gum_path ]] && "$gum_path" --version >/dev/null 2>&1; then pretty=1; fi ;;
    esac
fi
style() {
    local color=$1 message=$2
    if (( pretty )); then
        "$gum_path" style --foreground "$color" -- "$message" || printf '%s\n' "$message"
    else
        printf '%s\n' "$message"
    fi
}
if (( pretty )); then
    "$gum_path" style --foreground 6 --border rounded --border-foreground 6 \
        --padding '0 2' -- 'WORKSTATION DOCTOR' || printf 'WORKSTATION DOCTOR\n'
    printf '\n'
fi
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
failures=0
checks=0
personalized=0
for path in "$HOME/.config/git/workstation-profile.json" \
    "$HOME/.config/git/workstation.gitconfig" \
    "$HOME/.config/git/workstation-identities" \
    "$HOME/.config/bash/rc.d/40-git-workspace.bash" \
    "$HOME/.config/zsh/rc.d/40-git-workspace.zsh" \
    "$HOME/.ssh/workstation/config"; do
    if [[ -e $path || -L $path ]]; then personalized=1; break; fi
done
run_check() {
    local label=$1 log="$work/check.log" result=0 line rerun
    shift
    checks=$((checks + 1))
    : > "$log"
    if (( pretty )); then
        # Capture verifier output ourselves so diagnostics remain attached to FAIL.
        "$gum_path" spin --spinner dot --spinner.foreground 6 \
            --title "Checking $label" -- bash -c \
            'log=$1; shift; exec "$@" > "$log" 2>&1' doctor-check "$log" "$@" || result=$?
    else
        printf '==> Checking %s (implemented)\n' "$label"
        "$@" > "$log" 2>&1 || result=$?
    fi
    if (( result == 0 )); then
        if (( ! pretty )); then cat "$log"; fi
        style 2 "PASS $label"
    else
        style 1 "FAIL $label (exit $result)" >&2
        if [[ -s $log ]]; then
            while IFS= read -r line || [[ -n $line ]]; do
                printf '  %s\n' "$line" >&2
            done < "$log"
        else
            printf '  No diagnostic output; the check or its runner exited unexpectedly.\n' >&2
        fi
        printf -v rerun '%q ' "$@"
        printf '  Inspect: %s\n' "${rerun% }" >&2
        failures=$((failures + 1))
    fi
}
for domain in setup-tools setup-shell setup-git setup-docker; do
    args=()
    [[ $domain != setup-shell ]] || args=(${shell_args[@]+"${shell_args[@]}"})
    run_check "$domain" bash "$root/$domain/verify.sh" ${args[@]+"${args[@]}"}
    if [[ $domain == setup-git ]] && (( personalized )); then
        run_check setup-git-personal bash "$root/setup-git/verify-personal.sh"
    fi
done
if (( ! personalized )); then
    style 8 'SKIP (not configured): Git personalization; no managed local configuration found'
fi
style 8 'PLANNED (not checked): setup-workspace'
if (( failures )); then
    style 1 "Implemented-domain checks failed: $failures" >&2
    status=1
else
    style 2 'All configured checks passed. Full workstation readiness is not assessed.'
    status=0
fi
if (( pretty )); then
    printf '\n'
    style 6 "$((checks - failures)) passed · $failures failed"
fi
if (( ! personalized )); then
    printf '\nOptional next step: Git personalization (choose new / bitwarden).\n'
    printf '  bash %q\n' "$root/setup-git/install-personal.sh"
fi
exit "$status"
