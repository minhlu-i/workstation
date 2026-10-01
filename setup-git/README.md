# Setup Git

Default Git setup is generic: check the existing Git installed by setup-tools,
then set `init.defaultBranch=main` only when no global default branch is configured.
An existing valid default branch is reused. No account or identity is required.

```bash
./setup-git/install.sh
./setup-git/install.sh --configure-only
./setup-git/verify.sh
```

Both install modes perform the same offline basic configuration; neither installs
packages. Git must already work. Verification checks Git, global configuration and
its default branch, without network authentication or installing/repairing files.
The old `--config-only` verification flag remains compatible.

Basic setup preserves existing names/emails, user.useConfigOnly, conditional
workspace identities, URL rewrites, credential helpers, SSH aliases, key files,
permissions and Bitwarden configuration. It does not create Workspace directories,
SSH files, personal profiles or managed personalization includes. It never calls
bw, jq, ssh or ssh-keygen. Existing invalid global Git syntax/default branch is a
failure, not an excuse to overwrite configuration. A symlinked root config is
reused when it already has a valid branch; if a write is needed it requires manual
handling. Non-default XDG/Git config overrides retain the repo's current restrictions.

Changed ~/.gitconfig is backed up under the shared
`~/.local/state/workstation/bash-workstation/backups/` path, preserving its original
file mode. A newly created config has mode 600. Reruns make no changes or backups
when the branch is already configured. Root setup and doctor run only this basic
entry point. Doctor reports personalization as SKIP and does not certify identity
or SSH readiness, even when existing personal data is present.

Run `./setup-git/tests/test-basic` for isolated fresh/existing HOME, no-vault/SSH
calls, preservation, backup, rerun and failure checks. Python 3 is used only for
file/permission snapshots in this test.

## Saved personal workflow

The previous vault/local-key implementation is preserved in separate entry points
for the next personalization phase. It still uses exactly personal/s5tech accounts;
its generic optional-profile interface has not been implemented. Default setup and
doctor do not invoke it. Only run these commands when explicitly restoring personal
data:

```bash
./setup-git/install-personal.sh                   # restore/reuse personal data
./setup-git/install-personal.sh --refresh         # import vault updates
./setup-git/install-personal.sh --configure-only  # reuse local profile/key pairs
./setup-git/verify-personal.sh                    # check identity and local keys
```

## Prepare the vault once

Keep your existing **SSH key** items `personal` and `s5tech`, each with its private
and public key. Create a separate **Secure Note** named `workstation-git` whose
notes contain the JSON below, replacing the example identity/owner values:

```json
{
  "version": 1,
  "accounts": {
    "personal": {
      "name": "YOUR_PERSONAL_NAME",
      "email": "personal@example.com",
      "githubOwner": "YOUR-PERSONAL-GITHUB-OWNER",
      "sshKeyItem": "personal"
    },
    "s5tech": {
      "name": "YOUR_WORK_NAME",
      "email": "work@example.com",
      "githubOwner": "YOUR-WORK-GITHUB-OWNER",
      "sshKeyItem": "s5tech"
    }
  }
}
```

The Secure Note stores Git metadata, not keys. `sshKeyItem` accepts an exact item
ID or a unique item name. Duplicate names fail; use IDs to resolve ambiguity.
Override the note lookup with `WORKSTATION_GIT_PROFILE_ITEM=<name-or-id>`.
No shell code from the vault is evaluated.

Choose the correct Bitwarden server before login (for example
`bw config server https://vault.bitwarden.eu` for EU accounts). First installation
prompts through bw for login/unlock. It synchronizes the vault, stages only the
profile and two key pairs, and validates everything before deployment. A supplied
`BW_SESSION` can be used; setup preserves caller-owned sessions. Sessions created
by setup are locked on success/failure, and decrypted staging files are removed.
Failed lock cleanup returns failure with instructions to run `bw lock` yourself.
For API-key authentication, run `bw login --apikey` first, then setup prompts for
unlock. Login/unlock may require interactive input; credentials are never embedded
in commands or configuration. See [Bitwarden CLI](https://bitwarden.com/help/cli/).

## Local keys and daily use

Keys are written to `~/.ssh/workstation/{personal,s5tech}` with mode 600, alongside
`.pub` files. The SSH directories have mode 700. `gh-p` and `gh-s5` explicitly set
`IdentityAgent none` and select their local private key with `IdentitiesOnly yes`.
Git can then use the keys without a Bitwarden session, Desktop or WSL agent bridge.
The matching public keys must already be registered with the intended GitHub accounts.

This flow requires valid, matching keys **without a passphrase** for password-free
SSH. Encrypted or invalid private keys fail before deployment; setup never removes
passphrases. Anyone able to read an unencrypted private key can use it. Protect the
machine/account and its backups; vault locking does not disable a restored local key.
Key rotation needs both an updated GitHub public key and `--refresh` on each machine.
See [OpenSSH identity configuration](https://man.openbsd.org/ssh_config#IdentityAgent).

```bash
ssh -T git@gh-p
ssh -T git@gh-s5
```

Check the account in GitHub's successful greeting (normally exit code 1), then
exercise pull/push. Verification is local: it does not contact GitHub or prove
account permissions. First connection may ask you to verify the server host key;
setup never disables host verification or downloads unverified known_hosts entries.

## Identity, ownership and recovery

`~/Workspace/personal/` and `~/Workspace/s5tech/` receive identities from the
profile. New repos default to main; `user.useConfigOnly=true` prevents guessed
identities outside these workspaces. Explicit repo-local identity wins. SSH URLs
for each configured GitHub owner map to gh-p/gh-s5; HTTPS stays HTTPS. Pull/rebase,
signing, editor and credential helper settings remain user-owned.

Local profile: `~/.config/git/workstation-profile.json` (mode 600). This contains
metadata/key references, not private keys. Managed files also include
`~/.config/git/workstation.gitconfig`, each Workspace `.gitconfig`, and
`~/.ssh/workstation/{config,personal,personal.pub,s5tech,s5tech.pub}`. Root Git/SSH
files gain managed includes. Existing standalone gh-p/gh-s5 blocks are replaced,
including legacy Bitwarden-agent definitions; unrelated blocks survive. Additional
IdentityFile entries from wildcard blocks fail verification rather than selecting
another key silently. Symlinked managed files and configuration parents are refused.
The known experimental ~/.gitignore_global reference is removed; the file remains.

Default reruns reuse local profile/key pairs and do not access Bitwarden. Offline
configure-only repairs configuration/permissions but cannot restore missing or invalid
key material; use a normal install or --refresh. Neither mode changes vault contents.

Changed files are backed up under
`~/.local/state/workstation/bash-workstation/backups/`. **Rotation backups contain
old private keys**, with mode 600 in protected newly created directories. Identical
reruns create no backups. Installation is fail-fast, not transactional: fix the
reported condition and rerun. Restore home-relative files from the printed backup
folder when needed; never commit the deployed profile, keys or backups.

## Tests and publication

```bash
./setup-git/tests/test-configure
./setup-git/tests/test-bitwarden
./setup-tools/tests/test-providers
./setup-tools/tests/test-dispatch
```

Tests use temporary HOME, generated disposable key pairs and an explicit bw double.
They cover import failures/session cleanup, key matching, passphrase rejection,
permissions, refresh/backups, offline reruns and configuration preservation. They
never authenticate to a real vault or GitHub and do not prove real CLI installation.

The current source tree no longer contains personal identities/public keys, but
historical commits still do. Before making this repository public, separately clean
its history or publish a sanitized snapshot with new history. Repository visibility
and history are not changed by setup.
