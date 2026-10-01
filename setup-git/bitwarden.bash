# Import only the workstation profile and referenced SSH key items.
# Caller owns a private staging directory and cleans up its own CLI session.
import_bitwarden() {
    local status item account reference
    command -v bw >/dev/null || fail 'Install Bitwarden CLI through setup-tools first.'
    status=$(bw status | jq -er '.status') || fail 'Cannot determine Bitwarden CLI status.'
    if [[ $status != unlocked ]]; then
        [[ -z ${BW_SESSION-} ]] || fail 'Supplied BW_SESSION is invalid/locked; unlock Bitwarden before retrying.'
        [[ $no_input == 0 ]] || fail 'Bitwarden is locked/not logged in; supply an unlocked session before --no-input.'
        owns_session=1
        if [[ $status == unauthenticated ]]; then
            BW_SESSION=$(bw login --raw) || fail 'Bitwarden login failed.'
        elif [[ $status == locked ]]; then
            BW_SESSION=$(bw unlock --raw) || fail 'Bitwarden unlock failed.'
        else
            fail 'Unexpected Bitwarden CLI status.'
        fi
        [[ -n $BW_SESSION ]] || fail 'Bitwarden returned an empty session.'
        export BW_SESSION
    fi
    bw sync >/dev/null || fail 'Bitwarden sync failed.'
    local vault_route=note
    if [[ $item_selected == 1 || -n ${WORKSTATION_GIT_PROFILE_ITEM-} ]]; then
        # Advanced explicit note import remains compatible.
        if ! bw get notes "$profile_item" > "$work/vault-profile.json" 2>/dev/null; then
            fail 'Cannot read workstation Git Secure Note; check its name/ID and JSON contents.'
        fi
        normalize_profile "$work/vault-profile.json" "$work/profile.json"
    elif [[ $refresh == 1 && -f $work/previous.json ]]; then
        vault_route=cache
        cp "$work/previous.json" "$work/profile.json"
    else
        vault_route=select
        source "$module/bitwarden-select.bash"
        select_bitwarden_keys
    fi
    check_personal_paths "$work/profile.json"
    for account in $(ssh_accounts "$work/profile.json"); do
        if [[ $vault_route == select ]]; then
            grep -Fxq "$account" "$work/selected-accounts" || continue
        elif [[ $vault_route == cache && -z $(field "$work/profile.json" "$account" sshKeyItem) ]]; then
            continue
        fi
        require_ssh
        [[ -z $(field "$work/profile.json" "$account" privateKeyFile) && -z $(field "$work/profile.json" "$account" publicKeyFile) ]] || fail 'Bitwarden profiles must use sshKeyItem, not local key-file paths.'
        reference=$(field "$work/profile.json" "$account" sshKeyItem)
        [[ -n $reference ]] || fail "Missing $account sshKeyItem."
        item=$(bw get item "$reference" 2>/dev/null) || fail "Cannot read $account SSH key item; use a unique name or exact item ID."
        printf '%s' "$item" | jq -ej 'select(.type == 5) | .sshKey.privateKey | select(type == "string" and length > 0)' > "$work/$account" 2>/dev/null || fail "Missing $account SSH private key."
        printf '%s' "$item" | jq -ej 'select(.type == 5) | .sshKey.publicKey | select(type == "string" and length > 0)' > "$work/$account.pub" 2>/dev/null || fail "Missing $account SSH public key."
        unset item
        validate_key_pair "$work/$account" "$work/$account.pub"
    done
    # Keep unselected/local accounts offline while validating the whole deployment.
    stage_local_keys "$work/profile.json" 0
}
