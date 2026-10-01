# Module conventions

Modules live at the repo root. Implemented modules own `install.sh`, `verify.sh`,
`tests/` and configuration templates in `files/` as needed. Planned modules have
only documentation. Add platform-specific files when implementing that platform.

## Entry points

`setup.sh` runs tools → shell → Git → Docker → doctor. It stops at the first
installation failure and names the failed step. Doctor runs all implemented
verifiers, aggregates failures and reports planned modules separately.

Keep dispatch explicit. Resolve paths from each entry point so commands work from
any directory.

`bootstrap.sh` downloads public `main` without Git or a login, then runs setup from
`~/.local/share/workstation`. It requires Bash, curl, tar and filesystem utilities,
preserves terminal input and forwards shell selection. Complete download and
extraction before replacing a managed copy. Back up that copy; refuse unmanaged
paths and symlinks. Keep downloaded source after setup failure for continuation.
Archive updates use bootstrap; checkouts use Git.

## Ownership

| Module | Owns |
| --- | --- |
| `setup-tools` | Homebrew bootstrap, mise, base commands, common CLI, Zed |
| `setup-shell` | Bash/Zsh, completion/plugins, Flyline, Starship, zoxide, shell configuration |
| `setup-git` | Default branch; separate optional identities, keys and workspace selection |
| `setup-docker` | OrbStack/native Engine, Docker CLI, Compose, Buildx |
| `setup-workspace` | Planned; no deployed files |

Each dependency has one module owner, regardless of its installed provider.
Check capabilities before installing. Reuse working system, APT, Homebrew or mise
tools. Do not remove, adopt or silently upgrade existing tools. Project runtimes
belong in project `mise.toml` files.

Common CLI declarations use
`~/.config/mise/conf.d/bash-workstation.toml`; shell declarations use
`setup-shell.toml` in the same directory. Include only tools needing mise, using
`latest`. Preserve unrelated mise files.

## Tools and shell

Missing Homebrew prerequisites use APT on Ubuntu or Command Line Tools on macOS.
Sudo handles passwords directly; never capture credentials. Fail clearly on
cancelled authentication, missing noninteractive authorization or unfinished CLT.
Zed uses the macOS cask or official native Ubuntu installer; WSL skips it.
Settings and extensions remain user-managed.

Use Bash on Ubuntu / WSL2 and Zsh on macOS. Preserve login shells and profiles.
Keep Bash/Zsh templates modular with native syntax and hooks; share Starship's
configuration. Preserve deployed Bash paths and mirror responsibilities for Zsh.
Load Zsh highlighting after local widgets. Do not add Oh My Zsh, Atuin, fzf or a
dotfile manager to this setup.

## Git

Basic setup requires only Git. Set `init.defaultBranch=main` only when unset;
preserve personal configuration. Doctor reports personalization as skipped.
Default setup and bootstrap must never run personal entry points.

Personalization supports arbitrary workspace identities with optional SSH. Sources
are interactive `new`, local JSON or explicit Bitwarden imports. Collect GitHub
username, email, author name and workspace separately; retain saved defaults.
`new` generates Ed25519 keys and saves a profile. The Bitwarden chooser lists SSH
key metadata, imports selected IDs and creates selected workspace directories.
Keep duplicate vault names unambiguous. Retain version-1 and Secure Note support.
No-source reruns stay offline; refresh reuses saved references.

Select SSH keys by workspace. Existing repositories use `core.sshCommand`;
pre-clone commands use Git-owned `40-git-workspace` fragments for both shells.
Preserve explicit transport overrides and user local/alias files.

Require jq for personalization, OpenSSH for keys and bw for vault access. Stage
and validate imports before deployment. Private files use mode 600; SSH directories
use mode 700. Managed aliases disable agents. Never log key JSON or remove
passphrases. Lock setup-owned vault sessions. Rotation backups contain private keys.

## Docker

Use the OrbStack cask on macOS and official Docker APT packages on Ubuntu / WSL2.
Reuse working providers; preserve packages and contexts. Enable/start only a newly
installed Linux Engine.

First launch, WSL systemd configuration and relogin are manual steps. After tool
verification, add the current non-root user to `docker` when needed, preserving
other groups. Explain root-equivalent access and distinguish saved membership
from the active session. Print continuation instructions for stale sessions.
Doctor must fail on inaccessible sockets. Tools-only checks skip the daemon;
runtime checks require the selected platform's local socket.

## Writes and recovery

Generate deterministic output. Back up changed files before atomic replacement.
Seed user local/alias files only when absent; preserve additional user fragments.
Avoid appending duplicate startup blocks.

Use shared `setup-tools/file-operations.bash` and provider helpers. Retain the
legacy backup directory for both shells. Document partial migration recovery;
installation does not roll back earlier steps on failure.

Configure-only must not invoke package managers or downloaders. It does not promise
runtime readiness. Doctor verifies capabilities and configuration without repairs.
Interactive checks execute personal startup code and may create normal caches.

## Tests

Use temporary homes. Report fixture tests, real shell tests, installed dependency
checks and clean-machine installation separately. Missing prerequisites must not
count as passes. Test upstream plugin initialization and each shell's hook behavior.
State actual macOS/Ubuntu verification limits rather than inferring support from
path detection.
