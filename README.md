# Workstation

Goal: a new macOS/Linux/WSL2 machine → workstation setup → ready to code.
Currently tools, interactive shell, Git configuration and Docker are implemented.
Zed installation belongs to tools; workspace setup remains planned.
Doctor does not certify a complete development workstation.

```bash
./setup.sh                       # tools → native shell → Git → Docker → doctor
./setup-tools/install.sh         # Homebrew/mise and missing common CLI
./setup-shell/install.sh         # Bash on Ubuntu/WSL2; Zsh on macOS
./setup-docker/install.sh        # OrbStack / native Ubuntu Docker Engine
TERM=xterm-256color ./doctor/check.sh
```

## First run

Run this in Bash or Zsh as your intended user, without sudo:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/minhlu-i/workstation/main/bootstrap.sh)
```

This needs existing Bash, curl and tar (plus standard filesystem utilities), but
no Git, Homebrew or GitHub login. It downloads the public `main` archive to
`~/.local/share/workstation` and runs basic setup with terminal input preserved.
The bootstrap does not invoke Git personalization.

1. The one-command bootstrap runs `setup.sh`. If you already have a checkout,
   you can run `./setup.sh` directly instead. The
   [installer](setup.sh) runs tools (including missing Homebrew), shell, basic Git,
   Docker and doctor. Complete any CLT/OrbStack/WSL manual steps it reports, then rerun.
   For the archive installation, use the printed command or
   `bash ~/.local/share/workstation/setup.sh` to continue without downloading again.
   Doctor ends with the optional Git personalization command, including on reruns.
2. Optionally run `bash ~/.local/share/workstation/setup-git/install-personal.sh`
   (or `./setup-git/install-personal.sh` from your checkout). On a first interactive run,
   choose `new` or `bitwarden`; follow [Git personalization](setup-git/README.md)
   for key selection, identity and workspace defaults. This is a separate command.
3. Follow its GitHub public-key/authentication hints, and use
   `./setup-git/verify-personal.sh` for local personal checks. Doctor continues to
   assess basic Git only; it does not certify GitHub access.

Rerunning the one-command bootstrap downloads the latest `main`. It preserves the
previous managed copy under `~/.local/share/.workstation-backup.*/workstation`,
including any local edits, before replacing it. It refuses an existing unmanaged
directory or symlink at its destination. Download/extraction failures leave the
previous copy untouched; setup failures keep the new source for manual continuation.
These archive copies have no `.git` directory: update them through bootstrap,
rather than `git pull`. Backups remain until you remove them yourself.

Optional shell selection uses the same setup arguments:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/minhlu-i/workstation/main/bootstrap.sh) --shell bash
```

Run as the intended user, not with sudo. Homebrew's initial installation may need
sudo; native Docker installation on Ubuntu also uses sudo. Entry points work from any directory.
Basic setup does not change the login shell, system shell binary, login profile,
secrets or terminal settings.

## Platforms and package ownership

- **Ubuntu / WSL2 Ubuntu:** Bash + Flyline; Bash 5.3+ is required. An adequate
  existing Bash is reused. A missing/older version can be supplemented by brew Bash.
- **macOS:** existing Zsh 5.8+ + native completion/history, autosuggestions and
  syntax highlighting. Starship renders the prompt; no Oh My Zsh is needed.
- Other Linux distributions and Windows outside WSL2 are not implemented.
  Homebrew must support the host OS/architecture; consult its [requirements](https://docs.brew.sh/Installation).

**Check first, install only what is missing.** A working tool on PATH is reused,
regardless of whether apt, the OS, brew or mise supplied it. Setup prints the chosen
path; it does not uninstall, adopt into another manager, or upgrade existing tools.
Bash version and completion loading are checked, not merely package names.
Commands must provide the required executable names and behavior; for example,
Python `yq` is not a substitute for the Mike Farah `yq` used here.

Missing base commands and Zsh plugins use **brew**; missing common CLI and
Starship/zoxide/Flyline use **mise**. Manifests retain `latest` for mise-managed
entries, but omit working external tools to avoid competing installations.
Project runtimes (Node/Python/Go, etc.) remain in each project's `mise.toml`.

Common CLI include Bitwarden CLI (`bw`), Codex (`codex`) and Claude Code (`claude`)
on all supported platforms, including WSL2. Setup reuses existing installations or
installs missing ones with mise. Sign in to Codex/Claude manually afterward; their
account/configuration sync is not managed. Default Git setup does not configure
accounts or contact the vault. Explicit personal restoration is described in
[setup-git](setup-git/README.md).

Zed uses the macOS Homebrew cask or its official installer on native Ubuntu;
WSL skips Zed. Restore editor settings from your online configuration manually.

Apt and Xcode Command Line Tools provide the OS bootstrap layer. Docker is the
domain-specific exception: Ubuntu/WSL2 uses Docker's official APT repository;
macOS uses the OrbStack cask and its bundled CLI/plugins. When Homebrew is missing,
setup prepares the bootstrap layer automatically:

- Ubuntu: check existing commands, display missing prerequisite packages, then
  run `sudo apt-get update` and install only the missing packages with
  `--no-upgrade`. Already-installed but unavailable commands produce a repair
  message rather than a reinstall. There is no general system upgrade.
- macOS: if CLT is absent, request `xcode-select --install`. Complete Apple's
  dialog. Setup rechecks and stops with rerun instructions if installation is not
  finished; it does not poll indefinitely or install the full Xcode application.

At a privileged step, sudo prompts directly in your terminal if authentication is
needed. Cached credentials are reused. Setup does not read/store passwords or run
entirely as root. A cancelled/failed authentication stops the step. Without a
terminal and without cached authorization, it fails with instructions to rerun in
an interactive terminal or authenticate first with `sudo -v`.

Homebrew's official installer runs as your user after sudo validation. Existing
Homebrew/mise installations are reused; when brew already exists, this bootstrap
path is skipped. No automatic package upgrades are requested; repair or upgrade a
broken installed dependency explicitly. The archive bootstrap obtains the source
without Git; direct checkout installation also remains supported.

## Domains

| Domain | Responsibility / status |
|---|---|
| [setup-tools](setup-tools/README.md) | Implemented: Homebrew bootstrap, mise, base commands, common CLI and Zed |
| [setup-shell](setup-shell/README.md) | Implemented: native shell, shell plugins, shared Starship/zoxide, modular startup |
| [setup-git](setup-git/README.md) | Implemented: basic Git checks/default branch; personal workflow is separate |
| [setup-docker](setup-docker/README.md) | Implemented: OrbStack / native Docker Engine, CLI, Compose and Buildx |
| [setup-workspace](setup-workspace/README.md) | Planned: workspace organization |

Read [module conventions](docs/module-conventions.md) before extending the repo.

Setup may need a manual continuation: launch OrbStack once to expose its CLI and
plugins, enable systemd and restart WSL if needed, or relogin after a Docker group
change. Linux setup adds the current user to the docker group when needed; this
grants root-equivalent access. It prints relogin/WSL restart instructions when
saved membership is not active yet. Setup does not launch OrbStack.
Missing first-launch tools stop installation; an inaccessible
Engine fails doctor. See [Docker setup and recovery](setup-docker/README.md).

## Configuration, migration and recovery

```bash
./setup-tools/install.sh --configure-only
./setup-shell/install.sh --configure-only
./setup-git/install.sh --configure-only
```

The setup code in this mode never installs/downloads tools or invokes brew/mise.
Zsh startup-path inspection evaluates your `.zshenv`; any commands in that personal
file retain their normal behavior.
They generate configuration based on currently discoverable external executables;
missing dependencies remain for a subsequent full setup. Configuration alone is not
runtime readiness. Non-default XDG/mise config locations are rejected; Zsh also
requires `ZDOTDIR` unset or equal to HOME.

Bash deployment paths are unchanged. Zsh uses the corresponding `~/.zshrc` and
`~/.config/zsh/` layout. Customize the user-owned `local.bash`/`local.zsh`,
`45-user-aliases.*`, or additional fragments; managed files are replaced with backups.
See [shell ownership and recovery](setup-shell/README.md).

The legacy `~/.config/mise/conf.d/bash-workstation.toml` now contains only common
CLI declarations selected for mise. Shell declarations use `setup-shell.toml` in
the same directory. Shell-owned migration preserves old shell declarations before
tools replaces a combined manifest. Unrelated mise files and old installed tools
remain untouched. A setup manages one selected shell's manifest; normal selection
is platform-native. Cross-shell configuration is available for offline testing.

Backups remain under `~/.local/state/workstation/bash-workstation/backups/` for
compatibility, including Zsh changes. Identical files create no backups. Installation
is fail-fast, not transactional: resolve a failed step and rerun, or restore the
home-relative files from its printed backup directory. When restoring an old
combined manifest, remove `setup-shell.toml` only if migration created it, or restore
the matching previous pair to avoid duplicate declarations.

The legacy wrapper remains explicitly Bash-targeted:

```bash
./setup-bash-workstation
./setup-bash-workstation --configure-only
./setup-bash-workstation --verify
./setup-bash-workstation --help
```

Full Bash installation remains an Ubuntu/WSL2 operation. On macOS use `./setup.sh`
for Zsh. `--shell bash|zsh` can explicitly select shell configuration/verification.

## Verification

Doctor checks all implemented domains, continues after a verifier fails, reports
planned domains separately and returns nonzero on mandatory failure. It does not
install or repair configuration. Shell verification executes interactive startup,
including personal fragments, and may create normal history/completion caches.

Default Git setup and doctor check only Git and its default branch. Identity and
SSH are not assessed; doctor explicitly reports personalization as SKIP. Existing
personal configuration is preserved. Use the separate
[Git personal verifier](setup-git/verify-personal.sh) after optional personalization;
see [Git setup and recovery](setup-git/README.md).
Docker runtime checks require the selected local OrbStack/native Engine socket
to be reachable by the current user. They never pull images or run containers;
`./setup-docker/verify.sh --tools-only` checks installed tools without probing it.

Tests use temporary homes:

```bash
./tests/test-bootstrap                   # archive download/setup doubles; no host install
./setup-git/tests/test-basic             # basic setup; no vault/SSH calls
./setup-git/tests/test-new               # prompts and local ssh-keygen setup
./setup-git/tests/test-personal          # optional identities/local keys/sources
./setup-git/tests/test-configure         # personal configuration and compatibility
./setup-git/tests/test-bitwarden         # generated keys and bw double
./setup-git/tests/test-bitwarden-select  # checkbox selection and workspace mapping
./setup-tools/tests/test-providers
./setup-tools/tests/test-bootstrap       # OS/sudo/installer doubles
./setup-tools/tests/test-configure
./setup-tools/tests/test-dispatch
./setup-docker/tests/test-linux        # APT/systemd/provider doubles
./setup-docker/tests/test-macos        # OrbStack/Homebrew doubles
./setup-docker/tests/test-verify       # local socket/context/CLI fixtures
./setup-shell/tests/test-module
./setup-shell/tests/test-install-dependencies
./setup-shell/tests/test-native-config  # requires Zsh
./setup-shell/tests/test-zsh            # real Zsh; plugin/CLI doubles
```

Tests with package-manager/plugin doubles prove selection and error handling,
not actual installations. Real dependency suites require the tools already installed:

```bash
./setup-shell/tests/test-runtime       # Bash/Flyline; also Python for prompt test
./setup-shell/tests/test-zsh-runtime   # Zsh/plugins/mise/Starship/zoxide
```

Missing prerequisites are reported rather than treated as passes. Configuration
checks on macOS are not clean-machine bootstrap evidence. Test clean Ubuntu/WSL
and macOS installations separately, then smoke-test editing/completion in a terminal.

## GitHub maintenance

Manage GitHub CLI separately as a personal mise tool:

```bash
mise use --global gh@latest
mise exec gh -- gh auth login --hostname github.com --git-protocol https --web
mise exec gh -- gh repo view
```
