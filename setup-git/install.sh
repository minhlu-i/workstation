#!/usr/bin/env bash
set -euo pipefail
module=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
case ${1-} in
    ''|--configure-only) (( $# <= 1 )) || exit 2 ;;
    --help) printf 'Usage: setup-git/install.sh [--configure-only]\nOptional WORKSTATION_SSH_AGENT_SOCKET: absolute Unix socket path.\n'; exit 0 ;;
    *) exit 2 ;;
esac
source "$module/common.bash"
check_environment
select_agent
source "$module/../setup-tools/file-operations.bash"
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
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
render_ssh > "$work/ssh-managed"
for account in personal s5tech; do
    ssh-keygen -lf "$module/files/$account.pub" >/dev/null || fail "Invalid $account public key."
done
write_owned "$module/files/gitconfig" "$HOME/.config/git/workstation.gitconfig" .config/git/workstation.gitconfig
for account in personal s5tech; do
    write_owned "$module/files/$account.gitconfig" "$HOME/Workspace/$account/.gitconfig" "Workspace/$account/.gitconfig"
    write_owned "$module/files/$account.pub" "$HOME/.ssh/workstation/$account.pub" ".ssh/workstation/$account.pub"
done
write_owned "$work/ssh-managed" "$HOME/.ssh/workstation/config" .ssh/workstation/config
write_owned "$work/ssh-root" "$HOME/.ssh/config" .ssh/config
write_owned "$work/gitconfig" "$HOME/.gitconfig" .gitconfig
bash "$module/verify.sh" --config-only
printf 'Git configured. Bitwarden Desktop: enable SSH Agent and choose Remember until vault is locked.\n'
printf 'Agent socket: %s\nRun setup-git/verify.sh after unlocking Bitwarden; no private keys were exported.\n' "$agent"
