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

## Optional Git personalization

Default setup and doctor never invoke personalization. Choose it explicitly after
basic setup. The usual choices are new (create a local key/identity) or bitwarden
(restore existing data). No hand-written local JSON is needed for new.

```bash
./setup-git/install-personal.sh            # first run: choose new / bitwarden
./setup-git/install-personal.sh new        # enter username and email
./setup-git/install-personal.sh bitwarden  # restore from the vault
```

On a first interactive run without saved data, the command asks which mode to use.
New asks for your GitHub username and Git email, sets the username as Git's author
name, and runs ssh-keygen to generate an Ed25519 key with your email as its comment.
The key has no passphrase, matching the password-free local-key workflow.
Username also selects the GitHub owner whose SSH URLs are rewritten to the alias.

Defaults are account personal, workspace ~/Workspace/personal, alias gh-personal
and key ~/.ssh/workstation/personal. Configuration is saved automatically. Register
the generated public key with GitHub before using SSH:

```bash
cat ~/.ssh/workstation/personal.pub
```

New reuses an existing valid key pair; it never silently overwrites or rotates one.
Partial/invalid pairs fail with recovery instructions. You can add another account
while retaining existing accounts, and still enter username/email interactively:

```bash
./setup-git/install-personal.sh new --account work --workspace Projects/Work
# Automation only: supply the values and disable prompts.
./setup-git/install-personal.sh new --username YOUR-USERNAME --email you@example.com --no-input
```

--github-owner can override the owner when the chosen Git author name differs.
After setup, no-mode reruns reuse saved configuration/key pairs offline. Without
saved data and without a terminal, explicitly select new or bitwarden; --no-input
fails if new is missing username/email or the vault needs login/unlock.

Git and jq are required; OpenSSH only for configured SSH keys, and bw only for
Bitwarden. Advanced profiles can define any number of workspace identities and
omit SSH entirely. Account names and company mappings are not fixed.

### Advanced local identity profile

Copy [the example](files/profile.example.json) to a private location outside this
repo, edit your name/email and choose the workspace containing your repositories:

```bash
cp setup-git/files/profile.example.json ~/workstation-git.json
# Edit ~/workstation-git.json, then:
./setup-git/install-personal.sh --profile ~/workstation-git.json
./setup-git/verify-personal.sh
```

The version-2 JSON format is:

```json
{
  "version": 2,
  "accounts": {
    "developer": {
      "name": "YOUR_NAME",
      "email": "you@example.com",
      "workspace": "Projects/My Code"
    }
  }
}
```

Account IDs are lowercase slugs, starting with a letter. Any number is supported;
at least one account is required. Each needs name/email. Workspace is a literal
HOME-relative ASCII directory, defaulting to Workspace/<account-id>. It cannot contain
absolute paths, traversal, glob characters or overlap another account's workspace.
Personalization creates identity/configuration files, not workspace directories.
Existing repo-local identities override the workspace defaults.

Without SSH fields, setup never invokes bw, ssh or ssh-keygen and creates no SSH
files. This is enough to identify your commits; remote authentication remains your
existing HTTPS/credential-helper configuration. user.useConfigOnly=true prevents
Git from guessing identities; existing explicit global or repo-local identities
remain effective. Your existing default branch is preserved; an unset branch is
initialized to main. Editor, signing, pull/rebase and credential settings survive.

### Local SSH keys

For an account that needs GitHub SSH, add privateKeyFile and optionally
publicKeyFile, sshAlias and githubOwner:

```json
{
  "version": 2,
  "accounts": {
    "developer": {
      "name": "YOUR_NAME",
      "email": "you@example.com",
      "privateKeyFile": "~/.ssh/id_ed25519",
      "sshAlias": "gh-developer",
      "githubOwner": "YOUR-GITHUB-OWNER"
    }
  }
}
```

Run the same --profile command. Local key paths are absolute, ~/ relative, or
HOME-relative. Public key is derived when publicKeyFile is omitted. Setup stages
and validates the pair, then copies it to ~/.ssh/workstation/<account-id> and .pub.
Original files are not modified. These local-source imports never invoke bw.

SSH aliases default to gh-<account-id>; alias and githubOwner values must be unique.
The account ID config is reserved when SSH is enabled, to avoid its managed file.
SSH currently targets github.com as user git. githubOwner is optional: when present,
Git rewrites that owner's standard GitHub SSH URLs through the alias. Without it,
use git@<ssh-alias>:OWNER/REPO directly. HTTPS URLs stay HTTPS.

Managed aliases use IdentityAgent none and IdentitiesOnly yes. Keys must be valid
and unencrypted for password-free daily use; encrypted keys fail, and setup never
removes passphrases. Private keys have mode 600 and SSH directories mode 700.
Anyone able to read an unencrypted key can use it; vault locking cannot revoke a
restored local key. Register its public key with GitHub separately.

### Bitwarden source

Run the chooser; no Secure Note or hand-written profile is required:

```bash
./setup-git/install-personal.sh bitwarden
```

After login/unlock and sync, setup counts and lists only non-deleted **SSH key**
items. In a terminal, use arrows to move, Space to select/unselect multiple keys,
Enter to confirm, a to select all, or Esc to cancel. The native checkbox menu needs
no extra CLI dependency and pages long lists. Cancellation deploys nothing.

For each selected key, enter GitHub username/Git name, email and a HOME-relative
workspace. Workspace defaults to Workspace/<key-name-slug>; you can accept the
suggestion with Enter. Re-selecting a saved item offers its existing values.
Setup creates the selected workspace directories and configures Git identities
for repositories beneath them. Existing repositories are not moved or cloned.

Key names become safe account IDs; duplicate names get unique suffixes. The chooser
shows item IDs, and imports use exact IDs, so duplicate names are unambiguous. Only
selected keys are fetched. Existing unselected accounts remain configured using
local keys. Listing stores only names/IDs in private staging; decrypted full list
items, private key fields and session tokens are never printed or persisted there.
Selected key pairs are staged/validated before any workspace/config is deployed.

Choose the correct server before login, for example bw config server
https://vault.bitwarden.eu. Setup prompts through bw for login/unlock when needed.
For API-key authentication, run bw login --apikey first. A caller-provided
BW_SESSION is preserved; sessions created by setup are locked on success/failure,
including cancellation. Failed locking returns instructions to run bw lock manually.
Credentials and decrypted key JSON are never evaluated as shell code. The
[Bitwarden CLI](https://bitwarden.com/help/cli/) exposes SSH keys as type-5 items.

--no-input cannot run the chooser. To refresh already selected keys without prompts,
provide an unlocked CLI session and use --refresh --no-input. Saved item IDs and
identities are reused. Local-only accounts remain offline during that refresh.

#### Advanced explicit Secure Note import

For existing installations/automation, you can still explicitly select a Secure
Note containing version-1/2 profile JSON with sshKeyItem references:

```bash
./setup-git/install-personal.sh bitwarden --profile-item workstation-git
./setup-git/install-personal.sh bitwarden --profile-item MY-NOTE-ID --no-input
```

This bypasses the chooser. WORKSTATION_GIT_PROFILE_ITEM also explicitly selects a
note; the CLI option takes precedence and the variable is ignored outside Bitwarden
mode. An identity-only account can omit SSH fields. Item references accept a unique
name or exact ID; ambiguous names fail. These profiles cannot use local key-file
paths. Metadata belongs in the Secure Note, and keys remain separate SSH key items.

### Rerun, refresh and verification

```bash
./setup-git/install-personal.sh                   # reuse saved data offline
./setup-git/install-personal.sh --configure-only  # same offline behavior
./setup-git/install-personal.sh --profile ~/workstation-git.json  # update local source
./setup-git/install-personal.sh bitwarden         # choose keys/workspaces again
./setup-git/install-personal.sh --refresh         # refresh saved vault key IDs
./setup-git/verify-personal.sh
```

No-source reruns never implicitly access the vault or reread original key sources.
A missing local profile/key is an actionable failure. To import again, explicitly
choose new, bitwarden or an advanced --profile source. Source flags are mutually
exclusive. --refresh reuses saved references; an explicitly selected note refreshes
its metadata too. Without saved data, --refresh opens the chooser.

Verification is local and read-only with respect to deployed configuration. It
checks saved identities, managed includes and any configured key pairs, permissions
and effective SSH aliases. It never logs into Bitwarden or contacts GitHub. To
check permissions manually, run ssh -T git@YOUR-ALIAS and inspect the account in
GitHub's greeting (normally exit code 1), then exercise pull/push. First connection
may require host-key verification; setup never disables it or downloads unverified
known_hosts entries. See [OpenSSH configuration](https://man.openbsd.org/ssh_config#IdentityAgent).

### Compatibility and recovery

Version-1 profiles are normalized to version 2, retaining the previous personal
and s5tech workspace paths and gh-p/gh-s5 aliases. No vault conversion is required.
Current identities live in ~/.config/git/workstation-identities/<id>.gitconfig;
old Workspace .gitconfig files are retained but no longer included by managed
configuration. Names are treated generically in version-2 profiles.

The saved profile ~/.config/git/workstation-profile.json has mode 600 and contains
metadata/source references, never private keys. Unknown fields are discarded.
Global Git/SSH files gain managed includes; unrelated content survives. Single-host
blocks matching selected or previously managed aliases are replaced. Wildcard
IdentityFile additions fail verification rather than silently selecting other keys.
Symlinked managed files/parents and non-default XDG/Git overrides are refused.

Removing an account or its SSH fields regenerates managed includes and deactivates
its managed alias. Old keys/identity files remain on disk for manual recovery and
are never deleted automatically. Unrelated SSH blocks remain effective. Replacing
a profile therefore does not delete credentials.

Changed files are backed up under
~/.local/state/workstation/bash-workstation/backups/. Rotation backups contain old
private keys with mode 600 in protected directories. Identical reruns create no
backups. Installation is fail-fast, not transactional: fix the reported condition
and rerun, or restore home-relative files from the printed backup folder. Never
commit deployed profiles, private keys or backups. Rotation also requires updating
GitHub's registered public key.

## Tests and publication

```bash
./setup-git/tests/test-basic
./setup-git/tests/test-new
./setup-git/tests/test-personal
./setup-git/tests/test-configure
./setup-git/tests/test-bitwarden
./setup-git/tests/test-bitwarden-select
./setup-tools/tests/test-dispatch
```

Tests use temporary HOME, generated disposable keys and explicit doubles. They
cover optional sources/dependencies, arbitrary accounts, profile migration,
identity/key/config preservation, removal, passphrase/pair validation, permissions,
rotation and session cleanup. They do not authenticate to real vaults/GitHub or
prove clean-machine installation.

The source tree contains no actual personal identities/public keys, but historical
commits still do. Before making the repo public, separately clean history or publish
a sanitized snapshot with new history. Setup never changes repository visibility.
