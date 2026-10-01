#!/usr/bin/env bash
set -euo pipefail
set +x
module=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
case ${1-} in
    ''|--config-only) (( $# <= 1 )) || exit 2 ;;
    --help) printf 'Usage: setup-git/verify-personal.sh [--config-only]\nChecks saved identities and configured SSH keys locally; never authenticates.\n'; exit 0 ;;
    *) exit 2 ;;
esac
source "$module/common.bash"
source "$module/personal.bash"
check_personal_environment
check_personal_paths
profile="$HOME/.config/git/workstation-profile.json"
[[ -f $profile ]] || fail 'Local Git profile missing; choose --profile FILE or --bitwarden explicitly.'
[[ $(file_mode "$profile") == 600 ]] || fail 'Git profile must have mode 600.'
umask 077
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
normalize_profile "$profile" "$work/profile.json"
profile="$work/profile.json"
check_personal_paths "$profile"
render_git "$profile" "$work/gitconfig"
cmp -s "$work/gitconfig" "$HOME/.config/git/workstation.gitconfig" || fail 'Managed Git config missing or changed; rerun install-personal.sh.'
git config --global --get-all include.path | grep -Fxq '~/.config/git/workstation.gitconfig' || fail 'Missing global Git include.'
[[ $(git config --global --includes --get user.useConfigOnly) == true ]] || fail 'Expected user.useConfigOnly=true.'
for account in $(accounts "$profile"); do
    render_identity "$profile" "$account" "$work/identity"
    cmp -s "$work/identity" "$HOME/.config/git/workstation-identities/$account.gitconfig" || fail "Missing/changed $account identity."
    [[ $(file_mode "$HOME/.config/git/workstation-identities/$account.gitconfig") == 600 ]] || fail "$account identity must have mode 600."
done
for account in $(ssh_accounts "$profile"); do
    require_ssh
    [[ $(file_mode "$HOME/.ssh") == 700 && $(file_mode "$HOME/.ssh/workstation") == 700 ]] || fail 'SSH directories must have mode 700.'
    [[ -f $HOME/.ssh/workstation/$account && $(file_mode "$HOME/.ssh/workstation/$account") == 600 ]] || fail "Private $account key must exist with mode 600."
    validate_key_pair "$HOME/.ssh/workstation/$account" "$HOME/.ssh/workstation/$account.pub"
    alias=$(field "$profile" "$account" sshAlias)
    effective=$(ssh -G -F "$HOME/.ssh/config" "$alias" 2>/dev/null) || fail "Invalid SSH config for $alias."
    value() { printf '%s\n' "$effective" | awk -v key="$1" '$1 == key { $1=""; sub(/^ /, ""); print }'; }
    [[ $(value hostname) == github.com && $(value user) == git && $(value identitiesonly) == yes ]] || fail "SSH alias $alias overridden."
    identities=$(value identityfile)
    [[ $identities == "~/.ssh/workstation/$account" || $identities == "$HOME/.ssh/workstation/$account" ]] || fail "Unexpected additional/replaced IdentityFile for $alias. Reserve this alias for setup-git."
    [[ $(value identityagent) == none ]] || fail "SSH agent must be disabled for $alias."
done
printf 'PASS Git workspace identities and optional local SSH keys (no authentication attempted).\n'
