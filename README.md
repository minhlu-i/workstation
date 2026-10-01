# Workstation

Personal workstation setup for macOS and Ubuntu / WSL2: CLI tools, shell, Git and Docker.

## Quick start

Run in Bash or Zsh as your normal user:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/minhlu-i/workstation/main/bootstrap.sh)
```

Requires Bash, curl and tar. Downloads `main` to `~/.local/share/workstation`,
then runs tools → shell → Git → Docker → checks. Git and a GitHub login are not
needed to download the source.

From an existing checkout:

```bash
./setup.sh
```

If setup stops for a manual step, follow the printed instructions and rerun.
Common steps are completing Xcode Command Line Tools installation, opening
OrbStack once, enabling systemd on WSL2, or logging in again after a Docker group
change. Run without sudo; individual installation steps request it when needed.

For an archive installation, continue with:

```bash
bash ~/.local/share/workstation/setup.sh
```

Rerun the bootstrap command to download the latest `main`. It backs up the previous
managed source, including local edits, under
`~/.local/share/.workstation-backup.*/workstation`. Archive installations have no
`.git` directory.

## Platforms and package ownership

| Platform | Shell | Docker | Editor |
| --- | --- | --- | --- |
| macOS | Zsh 5.8+, autosuggestions, syntax highlighting | OrbStack | Zed |
| Ubuntu / WSL2 Ubuntu | Bash 5.3+, Flyline | Native Docker Engine | Zed on native Ubuntu |

Both shells use Starship, zoxide and mise. Other Linux distributions and Windows
outside WSL2 are not supported.

Working tools on `PATH` are reused. Missing base tools and Zsh plugins use
Homebrew; common CLI tools use mise. Setup does not upgrade existing tools.
Project runtimes belong in each project's `mise.toml`.

The [CLI inventory](setup-tools/files/mise.toml) includes bat, eza, fd, ripgrep,
jq, yq, delta, tldr, Bitwarden, Codex and Claude Code. Sign in to Codex and Claude
and restore Zed settings separately.

On Ubuntu, Docker uses its official APT repository. Setup adds your user to the
`docker` group when needed; this grants root-equivalent access. See
[Docker setup](setup-docker/README.md) for first launch, WSL2 and socket issues.

## Git personalization

Basic setup configures the default branch to `main` if unset. To configure your
identity, workspace and SSH key, run separately:

```bash
cd ~/.local/share/workstation  # or your checkout
./setup-git/install-personal.sh new        # create a local identity and key
./setup-git/install-personal.sh bitwarden  # restore keys from Bitwarden
./setup-git/verify-personal.sh
```

Choose one installation command. Follow its instructions to register or confirm
the public key on GitHub. Personal verification checks local configuration;
GitHub authentication is a separate step.

See [Git setup](setup-git/README.md) for multiple accounts and workspace selection.

## Modules

Each module can be installed and checked separately.

| Module | Includes |
| --- | --- |
| [setup-tools](setup-tools/README.md) | Homebrew, mise, common CLI, Zed |
| [setup-shell](setup-shell/README.md) | Shell configuration, plugins, prompt, navigation |
| [setup-git](setup-git/README.md) | Default branch; optional identities and SSH keys |
| [setup-docker](setup-docker/README.md) | Docker runtime, CLI, Compose, Buildx |
| [setup-workspace](setup-workspace/README.md) | Planned |

## Configuration, migration and recovery

Apply configuration using installed tools:

```bash
./setup-tools/install.sh --configure-only
./setup-shell/install.sh --configure-only
./setup-git/install.sh --configure-only
```

Shell selection follows the platform. Use `--shell bash|zsh` on shell configuration
or verification commands to select it explicitly. Full shell installation supports
Bash on Ubuntu / WSL2 and Zsh on macOS. The legacy `setup-bash-workstation` wrapper
selects Bash.

Put shell customizations in `local.bash` / `local.zsh`, `45-user-aliases.*`, or your
own fragments. See [shell configuration](setup-shell/README.md) for file ownership.

Changed configuration files are backed up under
`~/.local/state/workstation/bash-workstation/backups/`; identical reruns create no
backups. To recover, fix the reported error and rerun, or restore home-relative
files from the printed backup directory. Setup stops at the first installation
failure and does not roll back earlier steps.

When restoring an old combined mise manifest, restore the matching previous pair
of `bash-workstation.toml` and `setup-shell.toml`. Remove `setup-shell.toml` only if
the migration created it. Details: [tools](setup-tools/README.md) ·
[shell](setup-shell/README.md).

## Verification

```bash
./doctor/check.sh
./setup-docker/verify.sh --tools-only  # skip the Docker runtime check
```

Doctor checks tools, interactive shell startup, basic Git and the local Docker
runtime. It reports all failures and exits nonzero if a required check fails.
It does not install or repair anything, check GitHub access, or run containers.

Tests use temporary homes and command doubles. Test commands and prerequisites
are documented in each module; the archive bootstrap test is:

```bash
./tests/test-bootstrap
```

Shell runtime tests require real installed dependencies. Fixture tests do not
replace a clean-machine installation or a terminal smoke test.

Read [module conventions](docs/module-conventions.md) before extending the repo.
