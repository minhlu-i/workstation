# Optional profile, identities and local SSH configuration.
check_personal_environment() {
    check_git_environment
    local branch
    if branch=$(git config --global --includes --get init.defaultBranch); then
        git check-ref-format --branch "$branch" >/dev/null 2>&1 || fail 'Invalid init.defaultBranch; repair your Git configuration.'
    fi
    [[ $HOME != *'*'* && $HOME != *'?'* && $HOME != *'['* && $HOME != *']'* ]] || fail 'HOME must not contain Git includeIf glob characters.'
    command -v jq >/dev/null || fail 'Install jq through setup-tools first.'
}
normalize_profile() {
    jq -S -e -f "$module/profile.jq" "$1" > "$2" 2>/dev/null ||
        fail 'Invalid Git profile: require version 1/2, valid account IDs (config is reserved for SSH), name/email, distinct workspace paths and SSH aliases/owners.'
}
accounts() { jq -r '.accounts | keys[]' "$1"; }
ssh_accounts() { jq -r '.accounts | to_entries[] | select(.value.sshAlias) | .key' "$1"; }
field() { jq -r --arg account "$2" --arg field "$3" '.accounts[$account][$field] // empty' "$1"; }
require_ssh() {
    command -v ssh >/dev/null && command -v ssh-keygen >/dev/null || fail 'OpenSSH client is required for configured SSH keys.'
}
check_directory() {
    local path=$1
    while [[ $path != "$HOME" && $path != / ]]; do
        [[ ! -L $path && ( ! -e $path || -d $path ) ]] || fail "Refusing non-directory/symlink configuration parent: $path"
        path=$(dirname -- "$path")
    done
    [[ -d $HOME && ! -L $HOME ]] || fail 'HOME must be a real directory.'
}
check_file() {
    [[ ! -L $1 && ( ! -e $1 || -f $1 ) ]] || fail "Refusing non-regular config/key: $1"
    check_directory "$(dirname -- "$1")"
}
check_personal_paths() {
    local profile=${1-} account path
    for path in "$HOME/.gitconfig" "$HOME/.config/git/workstation-profile.json" "$HOME/.config/git/workstation.gitconfig"; do check_file "$path"; done
    check_directory "$HOME/.local/state/workstation/bash-workstation/backups"
    [[ -n $profile ]] || return 0
    for account in $(accounts "$profile"); do
        check_file "$HOME/.config/git/workstation-identities/$account.gitconfig"
        check_directory "$HOME/$(field "$profile" "$account" workspace)"
    done
    for account in $(ssh_accounts "$profile"); do
        check_file "$HOME/.ssh/config"
        check_file "$HOME/.ssh/workstation/config"
        check_file "$HOME/.ssh/workstation/$account"
        check_file "$HOME/.ssh/workstation/$account.pub"
    done
}
render_identity() {
    local profile=$1 account=$2 destination=$3
    : > "$destination"
    git config --file "$destination" user.name "$(field "$profile" "$account" name)"
    git config --file "$destination" user.email "$(field "$profile" "$account" email)"
}
render_git() {
    local profile=$1 destination=$2 account workspace owner alias
    : > "$destination"
    git config --file "$destination" user.useConfigOnly true
    for account in $(accounts "$profile"); do
        workspace=$(field "$profile" "$account" workspace)
        git config --file "$destination" "includeIf.gitdir:$HOME/$workspace/.path" "$HOME/.config/git/workstation-identities/$account.gitconfig"
        owner=$(field "$profile" "$account" githubOwner)
        [[ -n $owner ]] || continue
        alias=$(field "$profile" "$account" sshAlias)
        git config --file "$destination" --add "url.git@$alias:$owner/.insteadOf" "git@github.com:$owner/"
        git config --file "$destination" --add "url.git@$alias:$owner/.insteadOf" "ssh://git@github.com/$owner/"
    done
}
render_ssh() {
    local profile=$1 account alias
    for account in $(ssh_accounts "$profile"); do
        alias=$(field "$profile" "$account" sshAlias)
        printf 'Host %s\n    HostName github.com\n    User git\n    IdentityAgent none\n    IdentitiesOnly yes\n    IdentityFile "%s/.ssh/workstation/%s"\n\n' "$alias" "$HOME" "$account"
    done
    printf 'Host *\n'
}
validate_key_pair() {
    local private=$1 public=$2 derived expected
    [[ -f $private && -f $public && ! -L $private && ! -L $public ]] || fail 'Missing regular local SSH key pair.'
    derived=$(ssh-keygen -y -P '' -f "$private" 2>/dev/null) || fail 'Private key is invalid or passphrase-protected; use a valid key without a passphrase. No passphrase was removed.'
    expected=$(ssh-keygen -lf "$public" -E sha256 2>/dev/null | awk '{print $2}') || fail 'Invalid public key.'
    [[ -n $expected && $expected != *$'\n'* ]] || fail 'Expected exactly one public key.'
    [[ $(printf '%s\n' "$derived" | ssh-keygen -lf /dev/stdin -E sha256 2>/dev/null | awk '{print $2}') == "$expected" ]] || fail 'Private/public SSH key mismatch.'
}
local_path() {
    case $1 in
        /*) printf '%s\n' "$1" ;;
        '~/'*) printf '%s/%s\n' "$HOME" "${1#\~/}" ;;
        *) printf '%s/%s\n' "$HOME" "$1" ;;
    esac
}
stage_local_keys() {
    local profile=$1 use_sources=$2 account private public
    for account in $(ssh_accounts "$profile"); do
        require_ssh
        if [[ -f $work/$account && -f $work/$account.pub ]]; then
            validate_key_pair "$work/$account" "$work/$account.pub"
            continue
        fi
        private=''; public=''
        [[ $use_sources != 1 ]] || private=$(field "$profile" "$account" privateKeyFile)
        if [[ -n $private ]]; then
            private=$(local_path "$private")
            [[ -f $private && ! -L $private ]] || fail "Missing regular privateKeyFile for $account."
            cp "$private" "$work/$account"
            chmod 600 "$work/$account"
            public=$(field "$profile" "$account" publicKeyFile)
            if [[ -n $public ]]; then
                public=$(local_path "$public")
                [[ -f $public && ! -L $public ]] || fail "Missing regular publicKeyFile for $account."
                cp "$public" "$work/$account.pub"
            else
                ssh-keygen -y -P '' -f "$work/$account" > "$work/$account.pub" 2>/dev/null || fail 'Private key is invalid or passphrase-protected.'
            fi
        else
            [[ -f $HOME/.ssh/workstation/$account && -f $HOME/.ssh/workstation/$account.pub ]] || fail 'Local Git profile/key pairs missing; choose new to create keys, or bitwarden to restore (advanced: --profile).'
            cp "$HOME/.ssh/workstation/$account" "$work/$account"
            cp "$HOME/.ssh/workstation/$account.pub" "$work/$account.pub"
            chmod 600 "$work/$account"
        fi
        validate_key_pair "$work/$account" "$work/$account.pub"
    done
}
