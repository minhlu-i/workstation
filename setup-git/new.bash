# Create one account without requiring a hand-written profile or vault access.
create_local_account() {
    if [[ -z $new_username ]]; then
        [[ $no_input == 0 ]] || fail 'new requires --username and --email with --no-input.'
        read -r -p 'GitHub username: ' new_username || fail 'Provide --username USERNAME for new.'
    fi
    if [[ -z $new_email ]]; then
        [[ $no_input == 0 ]] || fail 'new requires --username and --email with --no-input.'
        read -r -p 'Git email: ' new_email || fail 'Provide --email EMAIL for new.'
    fi
    [[ $new_username =~ ^[A-Za-z0-9][A-Za-z0-9-]*$ ]] || fail 'GitHub username must contain letters, digits or hyphens, starting with a letter or digit.'
    local base="$work/previous.json"
    if [[ ! -f $base ]]; then
        base="$work/empty.json"
        printf '{"version":2,"accounts":{}}\n' > "$base"
    fi
    local default_name entered_name default_workspace entered_workspace
    default_name=$(field "$base" "$new_account" name)
    default_name=${default_name:-$new_username}
    if [[ -z $new_git_name ]]; then
        if [[ $no_input == 0 ]]; then
            read -r -p "Git author name [$default_name]: " entered_name || fail 'Git author name input cancelled.'
            new_git_name=${entered_name:-$default_name}
        else new_git_name=$default_name; fi
    fi
    if [[ -z $new_workspace && $no_input == 0 ]]; then
        default_workspace=$(field "$base" "$new_account" workspace)
        default_workspace=${default_workspace:-Workspace/$new_account}
        read -r -p "Workspace relative to HOME [$default_workspace]: " entered_workspace || fail 'Workspace input cancelled.'
        new_workspace=${entered_workspace:-$default_workspace}
    fi
    jq --arg id "$new_account" --arg name "$new_git_name" --arg username "$new_username" --arg email "$new_email" \
        --arg workspace "$new_workspace" --arg owner "$new_owner" '
        (.accounts // {}) as $accounts |
        {version:2, accounts: ($accounts + {($id): (
          {name:$name, email:$email,
           workspace: (if $workspace != "" then $workspace else $accounts[$id].workspace // ("Workspace/" + $id) end),
           privateKeyFile: (".ssh/workstation/" + $id),
           sshAlias: ($accounts[$id].sshAlias // ("gh-" + $id))} +
          (if $owner != "" then {githubOwner:$owner}
           else {githubOwner:$username} end)
        )})}' "$base" > "$work/new-profile.json"
    normalize_profile "$work/new-profile.json" "$work/profile.json"
    check_personal_paths "$work/profile.json"
    require_ssh
    if [[ -e $HOME/.ssh/workstation/$new_account || -e $HOME/.ssh/workstation/$new_account.pub ]]; then
        # Existing material must be complete/valid; new never silently rotates it.
        [[ -f $HOME/.ssh/workstation/$new_account && -f $HOME/.ssh/workstation/$new_account.pub ]] || fail 'Incomplete existing SSH pair; repair it or restore with bitwarden. new will not overwrite it.'
        printf 'Reuse local SSH key for %s.\n' "$new_account"
    else
        ssh-keygen -q -t ed25519 -N '' -C "$new_email" -f "$work/$new_account" || fail 'ssh-keygen failed; no new configuration was deployed.'
    fi
    stage_local_keys "$work/profile.json" 0
}
