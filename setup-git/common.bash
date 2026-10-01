# Shared setup-git paths and deterministic SSH configuration.
fail() { printf 'setup-git: %s\n' "$*" >&2; exit 1; }
check_environment() {
    [[ ${HOME-} == /* && $HOME != *$'\n'* && $HOME != *'"'* && $HOME != *'$'* && $HOME != *'%'* && $HOME != *'\'* ]] || fail 'HOME must be an absolute literal path without SSH expansion characters.'
    [[ ${XDG_CONFIG_HOME:-$HOME/.config} == "$HOME/.config" ]] || fail 'XDG_CONFIG_HOME must be ~/.config.'
    [[ -z ${GIT_CONFIG_GLOBAL-} && -z ${GIT_CONFIG_SYSTEM-} && -z ${GIT_CONFIG_COUNT-} && -z ${GIT_CONFIG_PARAMETERS-} ]] || fail 'Unset Git config overrides before setup/verification.'
    command -v git >/dev/null && git --version >/dev/null || fail 'Install Git through setup-tools first.'
    command -v ssh >/dev/null && command -v ssh-keygen >/dev/null || fail 'OpenSSH client is required.'
    command -v jq >/dev/null || fail 'Install jq through setup-tools first.'
}
check_local_paths() {
    local path
    for path in "$HOME/.ssh" "$HOME/.ssh/workstation" "$HOME/.config" "$HOME/.config/git" "$HOME/Workspace" "$HOME/Workspace/personal" "$HOME/Workspace/s5tech"; do
        [[ ! -L $path && ( ! -e $path || -d $path ) ]] || fail "Refusing non-directory/symlink configuration parent: $path"
    done
    for path in "$HOME/.gitconfig" "$HOME/.ssh/config" "$HOME/.config/git/workstation-profile.json" "$HOME/.config/git/workstation.gitconfig" "$HOME/.ssh/workstation/config"; do
        [[ ! -L $path && ( ! -e $path || -f $path ) ]] || fail "Refusing non-regular config: $path"
    done
    for account in personal s5tech; do
        for path in "$HOME/.ssh/workstation/$account" "$HOME/.ssh/workstation/$account.pub" "$HOME/Workspace/$account/.gitconfig"; do
            [[ ! -L $path && ( ! -e $path || -f $path ) ]] || fail "Refusing non-regular identity/key: $path"
        done
    done
}
validate_profile() {
    jq -e '
      .version == 1 and (.accounts | type == "object") and
      ([.accounts.personal, .accounts.s5tech] | all(
        type == "object" and
        ([.name, .email, .sshKeyItem] | all(type == "string" and length > 0 and (explode | all(. >= 32)))) and
        (.githubOwner | type == "string" and test("^[A-Za-z0-9][A-Za-z0-9-]*$"))
      )) and
      ([.accounts.personal.githubOwner, .accounts.s5tech.githubOwner] | map(ascii_downcase) | unique | length == 2)' "$1" >/dev/null 2>&1 ||
        fail 'Invalid Git profile: require version=1, distinct personal/s5tech GitHub owners, and name, email, githubOwner, sshKeyItem for each account.'
}
render_git() {
    local profile=$1 destination=$2 account owner alias
    cp "$module/files/gitconfig" "$destination"
    for account in personal s5tech; do
        owner=$(jq -r --arg account "$account" '.accounts[$account].githubOwner' "$profile")
        alias=gh-p; [[ $account != s5tech ]] || alias=gh-s5
        git config --file "$destination" --add "url.git@$alias:$owner/.insteadOf" "git@github.com:$owner/"
        git config --file "$destination" --add "url.git@$alias:$owner/.insteadOf" "ssh://git@github.com/$owner/"
    done
}
render_identity() {
    local profile=$1 account=$2 destination=$3
    : > "$destination"
    git config --file "$destination" user.name "$(jq -r --arg account "$account" '.accounts[$account].name' "$profile")"
    git config --file "$destination" user.email "$(jq -r --arg account "$account" '.accounts[$account].email' "$profile")"
}
validate_key_pair() {
    local private=$1 public=$2 derived expected
    [[ -f $private && -f $public && ! -L $private && ! -L $public ]] || fail 'Missing regular local SSH key pair.'
    derived=$(ssh-keygen -y -P '' -f "$private" 2>/dev/null) || fail 'Private key is invalid or passphrase-protected; use a valid key without a passphrase. No passphrase was removed.'
    expected=$(ssh-keygen -lf "$public" -E sha256 2>/dev/null | awk '{print $2}') || fail 'Invalid public key.'
    [[ -n $expected && $expected != *$'\n'* ]] || fail 'Expected exactly one public key.'
    [[ $(printf '%s\n' "$derived" | ssh-keygen -lf /dev/stdin -E sha256 2>/dev/null | awk '{print $2}') == "$expected" ]] || fail 'Private/public SSH key mismatch.'
}
file_mode() {
    if stat -f '%Lp' "$1" >/dev/null 2>&1; then stat -f '%Lp' "$1"; else stat -c '%a' "$1"; fi
}
render_ssh() {
    local account alias
    for account in personal s5tech; do
        alias=gh-p; [[ $account != s5tech ]] || alias=gh-s5
        printf 'Host %s\n    HostName github.com\n    User git\n    IdentityAgent none\n    IdentitiesOnly yes\n    IdentityFile "%s/.ssh/workstation/%s"\n\n' "$alias" "$HOME" "$account"
    done
    printf 'Host *\n'
}
