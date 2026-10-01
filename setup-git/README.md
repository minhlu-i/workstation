# Setup Git

Basic setup checks Git and sets `init.defaultBranch=main` if no global default
exists. Existing identities, credentials and SSH configuration are preserved.

```bash
./setup-git/install.sh
./setup-git/verify.sh
```

Git must already be installed by [setup-tools](../setup-tools/README.md).
`--configure-only` performs the same offline configuration. Invalid global config
stops setup; a symlinked config requiring a write needs manual handling.
Doctor always checks basic setup. If managed personalization files exist, it also
runs `verify-personal.sh` locally. Missing or damaged personal configuration fails
that check; GitHub authentication remains a separate step.

## Optional Git personalization

Choose a source after basic setup:

```bash
./setup-git/install-personal.sh            # first run: choose new or bitwarden
./setup-git/install-personal.sh new        # generate a local identity and key
./setup-git/install-personal.sh bitwarden  # restore keys from the vault
```

Personalization requires Git and jq, plus OpenSSH for SSH keys and `bw` for
Bitwarden. Accounts can have workspace identities without SSH.

### New identity and key

`new` asks for GitHub username, Git email, commit author name and workspace.
The author name defaults to the username. It generates an Ed25519 key with no
passphrase and saves the configuration.

| Default | Value |
| --- | --- |
| Account | `personal` |
| Workspace | `~/Workspace/personal` |
| SSH alias | `gh-personal` |
| Key | `~/.ssh/workstation/personal` |

Register the public key on GitHub before using SSH:

```bash
cat ~/.ssh/workstation/personal.pub
```

Create or clone repositories beneath the configured workspace; `new` does not
create that directory. Existing valid key pairs are reused. Partial or invalid
pairs stop setup with recovery instructions.

Add another account, or supply values for automation:

```bash
./setup-git/install-personal.sh new --account work --workspace Projects/Work
./setup-git/install-personal.sh new --username YOUR-USERNAME --email you@example.com --git-name 'Your Name' --no-input
```

`--git-name` sets the commit author name. `--github-owner` stores GitHub metadata;
it does not route repository URLs. `--no-input` requires all necessary values
and an unlocked vault when using Bitwarden.

### Bitwarden source

```bash
./setup-git/install-personal.sh bitwarden
```

Setup logs in/unlocks when needed, syncs, and lists non-deleted SSH key items.
Use arrows to move, Space to select, Enter to confirm, `a` to select all, or Esc
to cancel. Cancellation deploys nothing.

For each selected key, enter GitHub username, email, author name and a HOME-relative
workspace. The default workspace is `Workspace/<key-name-slug>`. Saved values are
offered independently on later selections. Setup creates selected workspace
directories; existing repositories stay where they are.

Duplicate key names receive unique account IDs. Imports use exact vault item IDs.
Unselected accounts retain their local configuration. Selected pairs are staged
and validated before workspace or configuration changes.

Choose your vault server before login if needed:

```bash
bw config server https://vault.bitwarden.eu
```

For API-key authentication, run `bw login --apikey` first. A supplied `BW_SESSION`
is preserved; setup locks sessions it creates, including on failure or cancellation.
If locking fails, follow the printed instructions to run `bw lock`. Key contents
and session tokens are not printed or persisted in listing data.

### Advanced local identity profile

Copy [the example](files/profile.example.json) outside the repo and edit it:

```bash
cp setup-git/files/profile.example.json ~/workstation-git.json
./setup-git/install-personal.sh --profile ~/workstation-git.json
```

A minimal identity-only profile:

```json
{
  "version": 2,
  "accounts": {
    "developer": {
      "name": "Your Name",
      "email": "you@example.com",
      "workspace": "Projects/My Code"
    }
  }
}
```

Account IDs are lowercase slugs starting with a letter. At least one account is
required, each with name and email. Workspaces are literal HOME-relative ASCII
paths, defaulting to `Workspace/<account-id>`. Absolute paths, traversal, globs
and overlapping account workspaces are rejected.

Local profiles configure identities without creating workspace directories.
Repo-local identities override workspace defaults. `user.useConfigOnly=true`
prevents Git from guessing an identity; explicit global identities remain effective.
Editor, signing, pull/rebase and credential settings are preserved.

### Local SSH keys

Add these fields to an account in a local profile:

```json
{
  "privateKeyFile": "~/.ssh/id_ed25519",
  "publicKeyFile": "~/.ssh/id_ed25519.pub",
  "sshAlias": "gh-developer",
  "githubOwner": "YOUR-GITHUB-USERNAME"
}
```

Key paths may be absolute, `~/`-relative or HOME-relative. `publicKeyFile` is
optional; setup derives it when omitted. Validated pairs are copied to
`~/.ssh/workstation/<account-id>` and `.pub`; source files are preserved.

Aliases default to `gh-<account-id>` and target `github.com` as user `git`.
Aliases and supplied `githubOwner` values must be unique. The account ID `config`
is reserved for SSH accounts. `githubOwner` is metadata; URLs are not rewritten.

Keys must be unencrypted. Setup rejects encrypted keys and never removes
passphrases. Private keys use mode 600, SSH directories mode 700. Managed aliases
use `IdentityAgent none` and `IdentitiesOnly yes`. Locking the vault does not revoke
restored local keys.

### Workspace selection

Each SSH workspace sets `core.sshCommand` to its local key with agents disabled.
This covers Git in existing repositories, including IDEs that use Git's transport.
Before cloning, managed Bash/Zsh fragments select the key by current directory,
including leading or repeated `git -C` options:

```bash
cd ~/Workspace/work
git clone git@github.com:YOUR-ORG/REPO.git
```

Open a new managed terminal after personalization, or source
`~/.config/<shell>/rc.d/40-git-workspace.<shell>`. Other shell setups need to source
that fragment explicitly.

Clone from within the intended workspace. A destination path inside a workspace
does not select its key when cloning from outside. Outside configured workspaces,
Git runs normally. Explicit `GIT_SSH_COMMAND` and `GIT_SSH` are preserved. HTTPS
uses its existing credential handling; explicit SSH aliases remain available.
An alias for another account can add that account's key through SSH configuration.

Reruns remove old managed owner-based URL rewrites and regenerate both shell
fragments. Unrelated URL rules and user functions are preserved. A Git function
in `local.bash` or `local.zsh` loads later and can override workspace selection;
remove an old manual wrapper when adopting this one.

### Advanced Secure Note import

Existing automation can use a Secure Note with version-1/2 profile JSON and
`sshKeyItem` references:

```bash
./setup-git/install-personal.sh bitwarden --profile-item workstation-git
./setup-git/install-personal.sh bitwarden --profile-item MY-NOTE-ID --no-input
```

This bypasses the chooser. `WORKSTATION_GIT_PROFILE_ITEM` also selects a note;
the CLI option takes precedence. The variable applies only in Bitwarden mode.
References accept an exact ID or unique name; ambiguous names fail. These profiles
keep keys in separate SSH key items and cannot reference local key files.

## Rerun, refresh and verification

```bash
./setup-git/install-personal.sh                   # reuse saved local data
./setup-git/install-personal.sh --configure-only  # same offline behavior
./setup-git/install-personal.sh --profile ~/workstation-git.json
./setup-git/install-personal.sh bitwarden         # select keys again
./setup-git/install-personal.sh --refresh         # refresh saved vault references
./setup-git/verify-personal.sh
```

No-source reruns use saved local data without accessing the vault or rereading
original sources. Missing saved data or keys require an explicit import. Source
options are mutually exclusive.

`--refresh` reuses saved item IDs and identities; an explicitly selected note also
refreshes metadata. Without saved data it opens the chooser. For unattended refresh,
provide an unlocked session and `--refresh --no-input`. Local-only accounts stay offline.

The verifier checks local identities, includes, keys, permissions and effective
SSH aliases. Check GitHub authentication separately using the alias printed by setup:

```bash
ssh -T git@YOUR-ALIAS
```

Confirm the expected account in GitHub's greeting, then test pull/push. First
connection may require host-key verification. Setup preserves that check.

## Compatibility and recovery

Version-1 profiles are normalized to version 2 while retaining old workspace paths
and aliases. Current identities live in
`~/.config/git/workstation-identities/<id>.gitconfig`. Old workspace `.gitconfig`
files remain on disk but are no longer included by managed configuration.

`~/.config/git/workstation-profile.json` has mode 600 and stores metadata/source
references, never private keys. Unknown fields are discarded. Managed includes
preserve unrelated global Git/SSH content. Matching single-host alias blocks are
replaced; wildcard `IdentityFile` additions fail verification. Symlinked managed
paths and non-default XDG/Git config overrides are rejected.

Removing an account or its SSH fields deactivates managed includes and aliases.
Old keys and identity files remain available for manual recovery.

Changed files are backed up under
`~/.local/state/workstation/bash-workstation/backups/`. Rotation backups include
old private keys in protected directories. Identical reruns create no backups.
Fix a failed step and rerun, or restore home-relative paths from the printed backup
directory. Earlier changes are not rolled back automatically. Key rotation also
requires updating GitHub's registered public key.

Keep profiles, private keys and backups outside repository history.

## Tests

```bash
./setup-git/tests/test-basic
./setup-git/tests/test-new
./setup-git/tests/test-personal
./setup-git/tests/test-configure
./setup-git/tests/test-bitwarden
./setup-git/tests/test-bitwarden-select
./setup-tools/tests/test-dispatch
```

Tests use temporary homes, disposable keys and command doubles. They cover
configuration preservation, sources, migration, key validation, rotation and
session cleanup. They do not authenticate to real vaults or GitHub.
