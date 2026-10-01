#!/usr/bin/env bash
set -euo pipefail
module=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
case ${1-} in
    ''|--config-only) (( $# <= 1 )) || exit 2 ;;
    --help) printf 'Usage: setup-git/verify-personal.sh [--config-only]\n'; exit 0 ;;
    *) exit 2 ;;
esac
source "$module/common.bash"
check_environment
set +x
check_local_paths
profile="$HOME/.config/git/workstation-profile.json"
[[ -f $profile ]] || fail 'Local Git profile missing; restore with setup-git/install-personal.sh.'
validate_profile "$profile"
[[ $(file_mode "$profile") == 600 ]] || fail 'Git profile must have mode 600.'
[[ $(file_mode "$HOME/.ssh") == 700 && $(file_mode "$HOME/.ssh/workstation") == 700 ]] || fail 'SSH directories must have mode 700.'
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
render_git "$profile" "$work/gitconfig"
cmp -s "$work/gitconfig" "$HOME/.config/git/workstation.gitconfig" || fail 'Managed Git config missing or changed; rerun setup-git.'
git config --global --get-all include.path | grep -Fxq '~/.config/git/workstation.gitconfig' || fail 'Missing global Git include.'
[[ $(git config --global --includes --get init.defaultBranch) == main ]] || fail 'Expected init.defaultBranch=main.'
[[ $(git config --global --includes --get user.useConfigOnly) == true ]] || fail 'Expected user.useConfigOnly=true.'
for account in personal s5tech; do
    render_identity "$profile" "$account" "$work/identity"
    cmp -s "$work/identity" "$HOME/Workspace/$account/.gitconfig" || fail "Missing/changed $account identity."
    [[ -f $HOME/.ssh/workstation/$account && $(file_mode "$HOME/.ssh/workstation/$account") == 600 ]] || fail "Private $account key must exist with mode 600."
    validate_key_pair "$HOME/.ssh/workstation/$account" "$HOME/.ssh/workstation/$account.pub"
    alias=gh-p; [[ $account != s5tech ]] || alias=gh-s5
    effective=$(ssh -G -F "$HOME/.ssh/config" "$alias" 2>/dev/null) || fail "Invalid SSH config for $alias."
    value() { printf '%s\n' "$effective" | awk -v key="$1" '$1 == key { $1=""; sub(/^ /, ""); print }'; }
    [[ $(value hostname) == github.com && $(value user) == git && $(value identitiesonly) == yes ]] || fail "SSH alias $alias overridden."
    identities=$(value identityfile)
    [[ $identities == "~/.ssh/workstation/$account" || $identities == "$HOME/.ssh/workstation/$account" ]] || fail "Unexpected additional/replaced IdentityFile for $alias. Reserve this alias for setup-git."
    [[ $(value identityagent) == none ]] || fail "SSH agent must be disabled for $alias."
done
printf 'PASS Git identities, local key pairs/permissions and effective SSH aliases (no authentication attempted).\n'
