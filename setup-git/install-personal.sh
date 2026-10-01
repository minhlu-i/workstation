#!/usr/bin/env bash
set -euo pipefail
# Never trace decrypted key material or session tokens.
set +x
umask 077
module=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
case ${1-} in
    ''|--configure-only|--refresh) (( $# <= 1 )) || exit 2 ;;
    --help) printf 'Usage: setup-git/install-personal.sh [--configure-only|--refresh]\nWORKSTATION_GIT_PROFILE_ITEM: Secure Note name/ID (default workstation-git).\n'; exit 0 ;;
    *) exit 2 ;;
esac
source "$module/common.bash"
check_environment
check_local_paths
source "$module/../setup-tools/file-operations.bash"
work=$(mktemp -d)
owns_session=0
cleanup() {
    local result=$?
    trap - EXIT
    if [[ $owns_session == 1 ]]; then
        if ! bw lock >/dev/null 2>&1; then
            printf 'setup-git: Failed to lock Bitwarden; run bw lock manually.\n' >&2
            result=1
        fi
        unset BW_SESSION
    fi
    rm -rf -- "$work"
    exit "$result"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
for file in "$HOME/.gitconfig" "$HOME/.ssh/config"; do
    [[ ! -L $file && ! -d $file ]] || fail "Refusing non-regular root config: $file"
done
# Stage and validate root configs before writes. Keep unrelated user settings.
if [[ -f $HOME/.gitconfig ]]; then cp "$HOME/.gitconfig" "$work/gitconfig"; else : > "$work/gitconfig"; fi
git config --file "$work/gitconfig" --list >/dev/null || fail 'Invalid ~/.gitconfig.'
if ! git config --file "$work/gitconfig" --get-all include.path | grep -Fxq '~/.config/git/workstation.gitconfig'; then
    git config --file "$work/gitconfig" --add include.path '~/.config/git/workstation.gitconfig'
fi
# Remove only the known experimental global-ignore reference; preserve its file.
ignore=$(git config --file "$work/gitconfig" --get-all core.excludesfile || :)
if [[ $ignore == "$HOME/.gitignore_global" || $ignore == '~/.gitignore_global' ]]; then
    git config --file "$work/gitconfig" --unset-all core.excludesfile
fi
printf 'Include "%s/.ssh/workstation/config"\n' "$HOME" > "$work/ssh-root"
if [[ -f $HOME/.ssh/config ]]; then
    # These two single-host aliases belong to this domain. Other blocks survive.
    awk -v managed="Include \"$HOME/.ssh/workstation/config\"" '
        tolower($1) == "host" || tolower($1) == "match" { skip = (tolower($1) == "host" && NF == 2 && ($2 == "gh-p" || $2 == "gh-s5")) }
        $0 == "Include ~/.ssh/workstation/config" || $0 == managed { next }
        !skip { print }
    ' "$HOME/.ssh/config" >> "$work/ssh-root"
fi
# Stage all vault data and validate it before changing configuration or keys.
profile="$HOME/.config/git/workstation-profile.json"
local_data_complete() {
    [[ -f $profile ]] || return 1
    local account
    for account in personal s5tech; do
        [[ -f $HOME/.ssh/workstation/$account && -f $HOME/.ssh/workstation/$account.pub ]] || return 1
    done
}
if [[ ${1-} != --refresh ]] && local_data_complete; then
    cp "$profile" "$work/profile.json"
    validate_profile "$work/profile.json"
    for account in personal s5tech; do
        cp "$HOME/.ssh/workstation/$account" "$work/$account"
        cp "$HOME/.ssh/workstation/$account.pub" "$work/$account.pub"
        chmod 600 "$work/$account"
        validate_key_pair "$work/$account" "$work/$account.pub"
    done
elif [[ ${1-} == --configure-only ]]; then
    fail 'Local Git profile/key pairs missing; run setup-git/install-personal.sh to restore from Bitwarden first.'
else
    source "$module/bitwarden.bash"
    import_bitwarden
fi
render_ssh > "$work/ssh-managed"
render_git "$work/profile.json" "$work/git-managed"
for account in personal s5tech; do
    render_identity "$work/profile.json" "$account" "$work/$account.gitconfig"
done
mkdir -p "$HOME/.ssh/workstation" "$HOME/.config/git"
chmod 700 "$HOME/.ssh" "$HOME/.ssh/workstation"
write_owned "$work/profile.json" "$profile" .config/git/workstation-profile.json 600
write_owned "$work/git-managed" "$HOME/.config/git/workstation.gitconfig" .config/git/workstation.gitconfig
for account in personal s5tech; do
    # Harden an existing private key before making any rotation backup.
    [[ ! -f $HOME/.ssh/workstation/$account ]] || chmod 600 "$HOME/.ssh/workstation/$account"
    write_owned "$work/$account.gitconfig" "$HOME/Workspace/$account/.gitconfig" "Workspace/$account/.gitconfig"
    write_owned "$work/$account" "$HOME/.ssh/workstation/$account" ".ssh/workstation/$account" 600
    write_owned "$work/$account.pub" "$HOME/.ssh/workstation/$account.pub" ".ssh/workstation/$account.pub"
done
write_owned "$work/ssh-managed" "$HOME/.ssh/workstation/config" .ssh/workstation/config
write_owned "$work/ssh-root" "$HOME/.ssh/config" .ssh/config
write_owned "$work/gitconfig" "$HOME/.gitconfig" .gitconfig
bash "$module/verify-personal.sh" --config-only
printf 'Git configured with local SSH keys; no SSH agent or Bitwarden session is needed for Git.\n'
