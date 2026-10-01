#!/usr/bin/env bash
set -euo pipefail
module=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
case ${1-} in
    ''|--configure-only) (( $# <= 1 )) || exit 2 ;;
    --help) printf 'Usage: setup-git/install.sh [--configure-only]\nChecks Git and sets init.defaultBranch=main only when unset.\nDoes not configure identity, SSH or Bitwarden.\n'; exit 0 ;;
    *) printf 'Usage: setup-git/install.sh [--configure-only]\n' >&2; exit 2 ;;
esac
source "$module/common.bash"
check_git_environment
# Environment checks validate global configuration before any write.
if branch=$(git config --global --includes --get init.defaultBranch); then
    git check-ref-format --branch "$branch" >/dev/null 2>&1 || fail 'Invalid init.defaultBranch; repair your Git configuration.'
    printf 'Reuse Git default branch: %s\n' "$branch"
else
    status=$?
    [[ $status == 1 ]] || fail 'Cannot read Git default branch.'
    [[ ! -L $HOME/.gitconfig && ( ! -e $HOME/.gitconfig || -f $HOME/.gitconfig ) ]] || fail 'Refusing non-regular ~/.gitconfig; configure init.defaultBranch manually.'
    umask 077
    work=$(mktemp -d)
    trap 'rm -rf -- "$work"' EXIT
    if [[ -f $HOME/.gitconfig ]]; then cp "$HOME/.gitconfig" "$work/gitconfig"; else : > "$work/gitconfig"; fi
    git config --file "$work/gitconfig" init.defaultBranch main
    source "$module/../setup-tools/file-operations.bash"
    mode=600
    [[ ! -f $HOME/.gitconfig ]] || mode=$(file_mode "$HOME/.gitconfig")
    write_owned "$work/gitconfig" "$HOME/.gitconfig" .gitconfig "$mode"
fi
bash "$module/verify.sh"
printf 'Git basic setup complete. Identity and SSH configuration were preserved.\n'
