#!/usr/bin/env bash
set -euo pipefail
set +x
umask 077
module=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
usage() {
    printf 'Usage: setup-git/install-personal.sh [new | bitwarden] [options]\nnew: enter username/email, or supply --username NAME --email EMAIL [--account ID] [--workspace PATH] [--github-owner OWNER]\nbitwarden: list/select SSH keys, enter identities and workspaces [advanced: --profile-item NAME_OR_ID]\n--no-input disables prompts. No mode reuses saved local data offline; first interactive setup offers new/bitwarden.\nAdvanced compatibility: --new, --bitwarden, --profile FILE, --refresh, --configure-only.\n'
}
source_mode=local
profile_file=''
profile_item=${WORKSTATION_GIT_PROFILE_ITEM:-workstation-git}
no_input=0
item_selected=0
refresh=0
create_workspaces=0
new_username=''
new_email=''
new_account=personal
new_workspace=''
new_owner=''
new_options_selected=0
while (( $# )); do
    case $1 in
        --help) usage; exit 0 ;;
        new|--new|bitwarden|--profile|--bitwarden|--refresh|--configure-only)
            [[ $source_mode == local ]] || { usage >&2; exit 2; }
            case $1 in
                --profile) (( $# >= 2 )) && [[ -n $2 && $2 != --* ]] || { usage >&2; exit 2; }; source_mode=file; profile_file=$2; shift ;;
                new|--new) source_mode=new ;;
                bitwarden|--bitwarden) source_mode=bitwarden ;;
                --refresh) source_mode=bitwarden; refresh=1 ;;
                --configure-only) source_mode=offline ;;
            esac ;;
        --profile-item) (( $# >= 2 )) && [[ -n $2 && $2 != --* ]] || { usage >&2; exit 2; }; profile_item=$2; item_selected=1; shift ;;
        --username|--email|--account|--workspace|--github-owner)
            (( $# >= 2 )) && [[ -n $2 && $2 != --* ]] || { usage >&2; exit 2; }
            case $1 in
                --username) new_username=$2 ;;
                --email) new_email=$2 ;;
                --account) new_account=$2 ;;
                --workspace) new_workspace=$2 ;;
                --github-owner) new_owner=$2 ;;
            esac
            new_options_selected=1; shift ;;
        --no-input) no_input=1 ;;
        *) usage >&2; exit 2 ;;
    esac
    shift
done
[[ $item_selected == 0 || $source_mode == bitwarden ]] || { usage >&2; exit 2; }
[[ $new_options_selected == 0 || $source_mode == new ]] || { usage >&2; exit 2; }
source "$module/common.bash"
source "$module/personal.bash"
check_personal_environment
check_personal_paths
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
profile="$HOME/.config/git/workstation-profile.json"
if [[ $source_mode == local && ! -f $profile && $no_input == 0 && -t 0 ]]; then
    printf 'Git personalization: new (generate SSH key) / bitwarden (restore vault)\n'
    read -r -p 'Choose new or bitwarden: ' source_mode || fail 'No personalization mode selected.'
    [[ $source_mode == new || $source_mode == bitwarden ]] || fail 'Choose new or bitwarden.'
fi
# Read the old profile only to deactivate aliases it used to own.
if [[ -f $profile ]]; then normalize_profile "$profile" "$work/previous.json"; fi
case $source_mode in
    new)
        source "$module/new.bash"
        create_local_account ;;
    file)
        [[ -f $profile_file && ! -L $profile_file ]] || fail 'Profile must be a regular local JSON file.'
        normalize_profile "$profile_file" "$work/profile.json"
        check_personal_paths "$work/profile.json"
        stage_local_keys "$work/profile.json" 1 ;;
    bitwarden)
        check_directory "$HOME/.ssh/workstation"
        source "$module/bitwarden.bash"
        import_bitwarden ;;
    *)
        [[ -f $profile ]] || fail 'Local Git profile missing; choose new or bitwarden (advanced: --profile FILE or --bitwarden explicitly).'
        cp "$work/previous.json" "$work/profile.json"
        check_personal_paths "$work/profile.json"
        stage_local_keys "$work/profile.json" 0 ;;
esac
# Prepare everything before deployment, preserving unrelated root settings.
if [[ -f $HOME/.gitconfig ]]; then cp "$HOME/.gitconfig" "$work/gitconfig"; else : > "$work/gitconfig"; fi
if ! git config --file "$work/gitconfig" --get-all include.path | grep -Fxq '~/.config/git/workstation.gitconfig'; then
    git config --file "$work/gitconfig" --add include.path '~/.config/git/workstation.gitconfig'
fi
# Preserve the prior migration of the known experimental ignore reference.
ignore=$(git config --file "$work/gitconfig" --get-all core.excludesfile || :)
if [[ $ignore == "$HOME/.gitignore_global" || $ignore == '~/.gitignore_global' ]]; then
    git config --file "$work/gitconfig" --unset-all core.excludesfile
fi
if ! git config --global --includes --get init.defaultBranch >/dev/null; then
    git config --file "$work/gitconfig" init.defaultBranch main
fi
render_git "$work/profile.json" "$work/git-managed"
for account in $(accounts "$work/profile.json"); do
    render_identity "$work/profile.json" "$account" "$work/$account.gitconfig"
done
has_ssh=0
[[ -z $(ssh_accounts "$work/profile.json") ]] || has_ssh=1
manage_ssh=$has_ssh
if [[ -f $HOME/.ssh/workstation/config ]]; then manage_ssh=1; fi
if [[ $manage_ssh == 1 ]]; then
    check_file "$HOME/.ssh/config"
    check_file "$HOME/.ssh/workstation/config"
    render_ssh "$work/profile.json" > "$work/ssh-managed"
    : > "$work/aliases"
    for candidate in "$work/profile.json" "$work/previous.json"; do
        [[ -f $candidate ]] || continue
        jq -r '.accounts[] | .sshAlias? // empty' "$candidate" >> "$work/aliases"
    done
    : > "$work/ssh-root"
    if [[ $has_ssh == 1 ]]; then printf 'Include "%s/.ssh/workstation/config"\n' "$HOME" > "$work/ssh-root"; fi
    if [[ -f $HOME/.ssh/config ]]; then
        awk -v managed="Include \"$HOME/.ssh/workstation/config\"" '
            FILENAME == ARGV[1] { owned[$0]=1; next }
            tolower($1) == "host" || tolower($1) == "match" { skip = (tolower($1) == "host" && NF == 2 && ($2 in owned)) }
            $0 == "Include ~/.ssh/workstation/config" || $0 == managed { next }
            !skip { print }
        ' "$work/aliases" "$HOME/.ssh/config" >> "$work/ssh-root"
    fi
fi
if [[ $create_workspaces == 1 ]]; then
    while IFS= read -r account; do
        mkdir -p "$HOME/$(field "$work/profile.json" "$account" workspace)"
    done < "$work/selected-accounts"
fi
write_owned "$work/profile.json" "$profile" .config/git/workstation-profile.json 600
write_owned "$work/git-managed" "$HOME/.config/git/workstation.gitconfig" .config/git/workstation.gitconfig
for account in $(accounts "$work/profile.json"); do
    write_owned "$work/$account.gitconfig" "$HOME/.config/git/workstation-identities/$account.gitconfig" ".config/git/workstation-identities/$account.gitconfig" 600
done
if [[ $has_ssh == 1 ]]; then
    mkdir -p "$HOME/.ssh/workstation"
    chmod 700 "$HOME/.ssh" "$HOME/.ssh/workstation"
    for account in $(ssh_accounts "$work/profile.json"); do
        [[ ! -f $HOME/.ssh/workstation/$account ]] || chmod 600 "$HOME/.ssh/workstation/$account"
        write_owned "$work/$account" "$HOME/.ssh/workstation/$account" ".ssh/workstation/$account" 600
        write_owned "$work/$account.pub" "$HOME/.ssh/workstation/$account.pub" ".ssh/workstation/$account.pub"
    done
fi
if [[ $manage_ssh == 1 ]]; then
    write_owned "$work/ssh-managed" "$HOME/.ssh/workstation/config" .ssh/workstation/config
    mode=600; [[ ! -f $HOME/.ssh/config ]] || mode=$(file_mode "$HOME/.ssh/config")
    write_owned "$work/ssh-root" "$HOME/.ssh/config" .ssh/config "$mode"
fi
mode=600; [[ ! -f $HOME/.gitconfig ]] || mode=$(file_mode "$HOME/.gitconfig")
write_owned "$work/gitconfig" "$HOME/.gitconfig" .gitconfig "$mode"
bash "$module/verify-personal.sh" --config-only
printf 'Git personalization complete. Daily Git uses local configuration and keys.\n'
if [[ $source_mode == new ]]; then
    printf '\nNext: register this public key with the intended GitHub account:\n  https://github.com/settings/keys\n'
    printf '  cat %q\n' "$HOME/.ssh/workstation/$new_account.pub"
elif [[ $source_mode == bitwarden && $has_ssh == 1 ]]; then
    printf '\nNext: confirm the restored public keys are still registered with the intended GitHub accounts:\n  https://github.com/settings/keys\n'
fi
if [[ $has_ssh == 1 ]]; then
    printf '\nCheck GitHub authentication manually and confirm the username in its greeting:\n'
    for account in $(ssh_accounts "$work/profile.json"); do
        alias=$(field "$work/profile.json" "$account" sshAlias)
        owner=$(field "$work/profile.json" "$account" githubOwner)
        printf '  ssh -T git@%s' "$alias"
        [[ -z $owner ]] || printf '  # expected GitHub account: %s' "$owner"
        printf '\n'
    done
    printf 'GitHub normally exits 1 after successful authentication. Setup has not performed these checks.\n'
fi
