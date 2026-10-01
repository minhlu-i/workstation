# Isolated vault double with real, disposable OpenSSH key pairs.
prepare_vault_fixture() {
    export VAULT_FIXTURE="$work/vault" VAULT_CALLS="$work/vault-calls"
    mkdir -p "$VAULT_FIXTURE" "$work/bin"
    for account in personal s5tech; do
        ssh-keygen -q -t ed25519 -N '' -C fixture -f "$VAULT_FIXTURE/$account"
        jq -n --rawfile private "$VAULT_FIXTURE/$account" --rawfile public "$VAULT_FIXTURE/$account.pub" '{type:5,sshKey:{privateKey:$private,publicKey:$public}}' > "$VAULT_FIXTURE/$account.json"
    done
    ssh-keygen -q -t ed25519 -N fixture-passphrase -C fixture -f "$VAULT_FIXTURE/encrypted"
    jq -n --rawfile private "$VAULT_FIXTURE/encrypted" --rawfile public "$VAULT_FIXTURE/encrypted.pub" '{type:5,sshKey:{privateKey:$private,publicKey:$public}}' > "$VAULT_FIXTURE/encrypted.json"
    cat > "$VAULT_FIXTURE/profile.json" <<'JSON'
{"version":1,"accounts":{"personal":{"name":"fixture-personal","email":"personal@example.invalid","githubOwner":"fixture-personal","sshKeyItem":"personal"},"s5tech":{"name":"fixture-work","email":"work@example.invalid","githubOwner":"fixture-work","sshKeyItem":"s5tech"}}}
JSON
    cat > "$work/bin/bw" <<'DOUBLE'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$*" >> "$VAULT_CALLS"
case $1 in
status) printf '{"status":"%s"}\n' "${VAULT_STATE:-unlocked}" ;;
login|unlock) [[ ${VAULT_CASE-} != auth-failure ]] || exit 1; printf 'fixture-session\n' ;;
lock) [[ ${VAULT_CASE-} != lock-failure ]] ;;
sync) [[ ${VAULT_CASE-} != sync-failure ]] ;;
get)
    if [[ $2 == notes ]]; then
        [[ $3 == workstation-git || $3 == profile-id ]] || exit 1
        case ${VAULT_CASE-} in
            bad-profile) printf '{}' ;;
            duplicate-owner) jq '.accounts.s5tech.githubOwner="FIXTURE-PERSONAL"' "$VAULT_FIXTURE/profile.json" ;;
            *) cat "$VAULT_FIXTURE/profile.json" ;;
        esac
    else
        [[ $2 == item ]] || exit 9
        case ${VAULT_CASE-}:$3 in
            missing:s5tech) exit 1 ;;
            encrypted:personal) cat "$VAULT_FIXTURE/encrypted.json" ;;
            mismatch:personal) jq --rawfile public "$VAULT_FIXTURE/s5tech.pub" '.sshKey.publicKey=$public' "$VAULT_FIXTURE/personal.json" ;;
            *) cat "$VAULT_FIXTURE/$3.json" ;;
        esac
    fi ;;
*) exit 9 ;;
esac
DOUBLE
    chmod +x "$work/bin/bw"
    export PATH="$work/bin:$PATH" BW_SESSION=fixture-session
}
