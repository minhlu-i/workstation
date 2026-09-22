#!/usr/bin/env bash
set -euo pipefail
module=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
case ${1-} in
    ''|--config-only) (( $# <= 1 )) || exit 2 ;;
    --help) printf 'Usage: setup-git/verify.sh [--config-only]\n'; exit 0 ;;
    *) exit 2 ;;
esac
source "$module/common.bash"
check_environment
cmp -s "$module/files/gitconfig" "$HOME/.config/git/workstation.gitconfig" || fail 'Managed Git config missing or changed; rerun setup-git.'
git config --global --get-all include.path | grep -Fxq '~/.config/git/workstation.gitconfig' || fail 'Missing global Git include.'
[[ $(git config --global --includes --get init.defaultBranch) == main ]] || fail 'Expected init.defaultBranch=main.'
[[ $(git config --global --includes --get user.useConfigOnly) == true ]] || fail 'Expected user.useConfigOnly=true.'
agent=''
for account in personal s5tech; do
    cmp -s "$module/files/$account.gitconfig" "$HOME/Workspace/$account/.gitconfig" || fail "Missing/changed $account identity."
    cmp -s "$module/files/$account.pub" "$HOME/.ssh/workstation/$account.pub" || fail "Missing/changed $account public key."
    alias=gh-p; [[ $account != s5tech ]] || alias=gh-s5
    effective=$(ssh -G -F "$HOME/.ssh/config" "$alias" 2>/dev/null) || fail "Invalid SSH config for $alias."
    value() { printf '%s\n' "$effective" | awk -v key="$1" '$1 == key { $1=""; sub(/^ /, ""); print }'; }
    [[ $(value hostname) == github.com && $(value user) == git && $(value identitiesonly) == yes ]] || fail "SSH alias $alias overridden."
    identities=$(value identityfile)
    [[ $identities == "~/.ssh/workstation/$account.pub" || $identities == "$HOME/.ssh/workstation/$account.pub" ]] || fail "Unexpected additional/replaced IdentityFile for $alias. Reserve this alias for setup-git."
    current=$(value identityagent)
    [[ $current == /* ]] || fail "Missing absolute Bitwarden agent socket for $alias."
    [[ -z $agent || $agent == "$current" ]] || fail 'Aliases use different agents.'
    agent=$current
done
printf 'PASS Git identities/config and effective SSH aliases (no authentication attempted).\n'
[[ ${1-} != --config-only ]] || exit 0
[[ -S $agent ]] || fail "Bitwarden agent socket missing: $agent. Enable the desktop agent; WSL needs a Unix socket bridge."
command -v ssh-add >/dev/null || fail 'ssh-add is required to inspect agent readiness.'
keys=$(SSH_AUTH_SOCK="$agent" ssh-add -l -E sha256 2>/dev/null) || fail 'Agent unavailable or has no keys. Open/unlock Bitwarden and check SSH key items.'
for account in personal s5tech; do
    fingerprint=$(ssh-keygen -lf "$module/files/$account.pub" -E sha256 | awk '{print $2}')
    printf '%s\n' "$keys" | awk '{print $2}' | grep -Fxq "$fingerprint" || fail "Agent does not list the expected $account key."
done
printf 'PASS agent lists both expected public keys. Unlock/authorization and GitHub access still require a real pull/push test.\n'
