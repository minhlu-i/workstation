# Setup Git

Configures this personal workstation's Git identities and GitHub SSH aliases.
Git itself belongs to setup-tools; any installed working Git is reused, without
version pinning. No chezmoi, global ignore, private key export or package install.

```bash
./setup-git/install.sh                   # configure; no network authentication
./setup-git/install.sh --configure-only  # same behavior; no downloads
./setup-git/verify.sh --config-only      # Git files and effective SSH config
./setup-git/verify.sh                    # additionally check agent/key presence
```

## Identity and URLs

- `~/Workspace/personal/`: minhlu-i, REDACTED.
- `~/Workspace/s5tech/`: REDACTED, REDACTED.
- New repositories default to `main`; `user.useConfigOnly=true` prevents guessed
  identities outside configured workspaces. Explicit repo-local identity wins.
- `git@github.com:minhlu-i/...` and `ssh://git@github.com/minhlu-i/...` use `gh-p`.
- Equivalent SSH URLs under `99techteam` use `gh-s5`. HTTPS stays HTTPS.
- Pull/rebase, signing, editor and credential-helper preferences are not changed.

The committed `.pub` files are public keys for the existing Bitwarden personal
and s5tech items. They are deliberately not private keys. Update them when rotating
vault keys, rerun setup, and ensure GitHub has the corresponding public keys.

## Bitwarden setup and authorization

Install/open Bitwarden Desktop, sign in, and ensure `personal` and `s5tech` are
SSH key items. In Settings enable SSH Agent and select **Remember until vault is
locked** under **Ask for authorization when using SSH agent**. This desktop
preference is manual; this repository does not edit Bitwarden's private app state.
Each key requires initial approval, remembered until lock. A locked vault still
needs unlocking. See [Bitwarden SSH Agent](https://bitwarden.com/help/ssh-agent/).

Only `gh-p` and `gh-s5` use the chosen `IdentityAgent`; `SSH_AUTH_SOCK` and other SSH
hosts are not changed. `IdentityFile` selects a public key and `IdentitiesOnly yes`
restricts key selection. Local private key files are neither read nor removed.

Setup discovers an existing App Store, Flatpak or Snap socket, otherwise selects
`~/.bitwarden-ssh-agent.sock` (macOS DMG/native Linux). For a desktop installed later,
or another location, explicitly select its socket when running setup:

```bash
WORKSTATION_SSH_AGENT_SOCKET="$HOME/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock" ./setup-git/install.sh
```

Keep passing an override on subsequent setup runs when using a custom socket.
The top-level setup inherits this environment variable too.

**WSL2:** the Windows Bitwarden agent is not automatically available as a Linux
Unix socket. Establish an agent bridge separately, then pass its absolute Unix
socket path via `WORKSTATION_SSH_AGENT_SOCKET`. This repo does not install a relay
or change Windows services. Missing sockets fail runtime verification explicitly.
WSL bridging and actual clean-machine Bitwarden behavior remain unverified.

After desktop setup, manually exercise authentication:

```bash
ssh -T git@gh-p
ssh -T git@gh-s5
```

GitHub's successful SSH greeting normally exits 1; check the account in the greeting.
Then test pull/push in each workspace. Doctor only checks the socket and the two
expected public-key fingerprints. A listed key does not prove the vault is unlocked,
authorization is granted, or GitHub permissions are correct. Verification does not
contact GitHub or request signing.

## Ownership, migration and recovery

Managed files: `~/.config/git/workstation.gitconfig`, both Workspace `.gitconfig`
files, and `~/.ssh/workstation/{config,personal.pub,s5tech.pub}`. Root
`~/.gitconfig` gains a managed include; unrelated settings survive. A legacy
`core.excludesFile` pointing exactly to `~/.gitignore_global` (or its absolute HOME
path) is removed, while the ignore file itself is preserved. Other ignore settings
are left alone. Existing conditional identity includes may remain harmlessly.

The SSH root gains a leading managed Include. Existing standalone `Host gh-p` and
`Host gh-s5` blocks are replaced by managed definitions; other blocks survive.
Do not also define these aliases in combined Host patterns or other includes.
Extra IdentityFile entries from wildcard blocks cause verification to fail with
instructions, rather than silently selecting another key. Move those entries to
specific unrelated hosts. Root Git/SSH config symlinks are refused for manual handling.

Changed files are backed up under the shared legacy directory
`~/.local/state/workstation/bash-workstation/backups/`. Identical reruns create no
backup. Setup is not transactional: on failure, inspect its message, fix conflicting
configuration and rerun. To restore, copy backed-up files to their home-relative
locations and remove newly created managed files/includes only if appropriate.

## Tests

```bash
./setup-git/tests/test-configure
./setup-git/tests/test-agent       # Python 3 test dependency; agent double
./setup-tools/tests/test-dispatch
```

Tests use temporary HOME and explicit SSH config paths (OpenSSH's default home
lookup does not follow the HOME environment variable). No host provisioning or
real Bitwarden authentication occurs. Python is only a test dependency.
