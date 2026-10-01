#!/usr/bin/env bash
set -euo pipefail

fail() { printf 'bootstrap.sh: %s\n' "$*" >&2; exit 1; }
if [[ ${1-} == --help && $# == 1 ]]; then
    printf 'Usage: bootstrap.sh [--shell bash|zsh]\nDownloads public main to ~/.local/share/workstation and runs basic setup.\nGit personalization is a separate command.\n'
    exit 0
fi
if (( $# )); then
    [[ $# == 2 && $1 == --shell && ( $2 == bash || $2 == zsh ) ]] || fail 'Usage: bootstrap.sh [--shell bash|zsh]'
fi
[[ $EUID != 0 ]] || fail 'Run as your intended user, without sudo.'
[[ ${HOME-} == /* && $HOME != / ]] || fail 'HOME must be an absolute user directory.'
for tool in curl tar mktemp mkdir mv rm; do
    command -v "$tool" >/dev/null || fail "Required command is missing: $tool"
done

parent="$HOME/.local/share"
destination="$parent/workstation"
marker='workstation archive bootstrap v1'
for path in "$HOME/.local" "$parent" "$destination"; do
    [[ ! -L $path ]] || fail "Refusing symlink: $path"
done
if [[ -e $destination ]]; then
    [[ -d $destination && -f $destination/.workstation-bootstrap && ! -L $destination/.workstation-bootstrap ]] || fail "Refusing to replace an unmanaged path: $destination"
    IFS= read -r existing_marker < "$destination/.workstation-bootstrap" || fail 'Invalid bootstrap ownership marker.'
    [[ $existing_marker == "$marker" ]] || fail 'Unrecognized bootstrap ownership marker.'
fi
mkdir -p -- "$parent"
staging=$(mktemp -d "$parent/.workstation-download.XXXXXX")
trap 'rm -rf -- "$staging"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

printf '==> Downloading public workstation main (no Git or GitHub login required)\n'
curl -fLS --retry 2 --connect-timeout 20 \
    https://codeload.github.com/minhlu-i/workstation/tar.gz/refs/heads/main \
    -o "$staging/source.tar.gz" || fail 'Download failed; existing installation was not changed.'
mkdir -- "$staging/source"
tar -xzf "$staging/source.tar.gz" --strip-components=1 -C "$staging/source" || fail 'Invalid archive; existing installation was not changed.'
[[ -f $staging/source/setup.sh && -f $staging/source/setup-git/install-personal.sh ]] || fail 'Archive is missing workstation entry points.'
printf '%s\n' "$marker" > "$staging/source/.workstation-bootstrap"

backup=''
if [[ -d $destination ]]; then
    backup=$(mktemp -d "$parent/.workstation-backup.XXXXXX")
    mv -- "$destination" "$backup/workstation"
    printf 'Previous installation preserved at: %s\n' "$backup/workstation"
fi
if ! mv -- "$staging/source" "$destination"; then
    [[ -z $backup ]] || mv -- "$backup/workstation" "$destination"
    fail 'Could not place the downloaded installation.'
fi
printf 'Installation source: %s\n' "$destination"
printf 'Rerun basic setup after any manual continuation:\n  bash %q' "$destination/setup.sh"
for argument in "$@"; do printf ' %q' "$argument"; done
printf '\n'
printf 'Optional Git personalization (new / bitwarden):\n  bash %q\n' "$destination/setup-git/install-personal.sh"
if bash "$destination/setup.sh" "$@"; then
    printf 'Basic setup completed. Git personalization remains optional.\n'
else
    status=$?
    printf 'Basic setup stopped (exit %s). Source remains at %s for rerunning.\n' "$status" "$destination" >&2
    exit "$status"
fi
