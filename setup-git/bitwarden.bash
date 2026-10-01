# Import only the workstation profile and referenced SSH key items.
# Caller owns a private staging directory and cleans up its own CLI session.
import_bitwarden() {
    local status item account reference
    command -v bw >/dev/null || fail 'Install Bitwarden CLI through setup-tools first.'
    status=$(bw status | jq -er '.status') || fail 'Cannot determine Bitwarden CLI status.'
    if [[ $status != unlocked ]]; then
        [[ -z ${BW_SESSION-} ]] || fail 'Supplied BW_SESSION is invalid/locked; unlock Bitwarden before retrying.'
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
    # Do not persist arbitrary note fields or log decrypted item JSON.
    if ! bw get notes "${WORKSTATION_GIT_PROFILE_ITEM:-workstation-git}" 2>/dev/null |
        jq -e '{version, accounts: {personal: .accounts.personal, s5tech: .accounts.s5tech}} | .accounts |= with_entries(.value |= {name,email,githubOwner,sshKeyItem})' > "$work/profile.json"; then
        fail 'Cannot read workstation Git Secure Note; check its name/ID and JSON contents.'
    fi
    validate_profile "$work/profile.json"
    for account in personal s5tech; do
        reference=$(jq -r --arg account "$account" '.accounts[$account].sshKeyItem' "$work/profile.json")
        item=$(bw get item "$reference" 2>/dev/null) || fail "Cannot read $account SSH key item; use a unique name or exact item ID."
        printf '%s' "$item" | jq -ej 'select(.type == 5) | .sshKey.privateKey | select(type == "string" and length > 0)' > "$work/$account" || fail "Missing $account SSH private key."
        printf '%s' "$item" | jq -ej 'select(.type == 5) | .sshKey.publicKey | select(type == "string" and length > 0)' > "$work/$account.pub" || fail "Missing $account SSH public key."
        unset item
        validate_key_pair "$work/$account" "$work/$account.pub"
    done
}
