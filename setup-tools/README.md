# Setup tools

Installs missing base commands, common CLI tools and Zed. Working tools on `PATH`
are reused regardless of their package manager.

```bash
./setup-tools/install.sh
./setup-tools/install.sh --configure-only
./setup-tools/verify.sh
```

## Package managers

| Dependency | Installation source |
| --- | --- |
| Homebrew | Official installer |
| Homebrew prerequisites | APT on Ubuntu; Xcode Command Line Tools on macOS |
| mise, curl, git, less, xz | Homebrew |
| [Common CLI](files/mise.toml) | mise |
| Zed | Homebrew cask on macOS; official installer on native Ubuntu |

Setup checks existing capabilities first and installs only what is missing. It
keeps existing packages and does not upgrade them. Broken providers require repair;
`yq` must be the Mike Farah implementation.

If Homebrew is missing, Ubuntu installs missing prerequisite packages with
`apt-get --no-upgrade`. macOS requests Command Line Tools and stops if installation
is unfinished. Sudo handles authentication directly in your terminal. See the
[root installation guide](../README.md#platforms-and-package-ownership).

## Configuration

`~/.config/mise/conf.d/bash-workstation.toml` declares only common CLI tools that
need mise, using `latest`. Working external tools are omitted. Other mise files
are preserved; project runtimes belong in each project's `mise.toml`.

Shell dependencies belong to [setup-shell](../setup-shell/README.md). When replacing
an old combined manifest, setup preserves its shell declarations in
`setup-shell.toml` first.

`--configure-only` writes configuration from discoverable executables without
installing tools or checking Zed. It does not establish runtime readiness.

## Applications

Bitwarden (`bw`), Codex (`codex`) and Claude Code (`claude`) are included on all
supported platforms. Sign in and manage their settings separately. Optional
[Git personalization](../setup-git/README.md) can use Bitwarden to restore keys;
basic setup does not access the vault.

Zed is installed only on macOS and native Ubuntu. On Linux it lives at
`~/.local/zed.app`, with its CLI in `~/.local/bin`. On WSL2, install the Windows
editor separately. Restore settings and extensions yourself.

## Verification and recovery

Verification checks executable versions, providers and the managed manifest.
Zed checks cover CLI availability; graphical startup and settings sync need a
manual check.

Changed files are backed up under
`~/.local/state/workstation/bash-workstation/backups/`. Restore affected
home-relative paths from the printed directory. See
[manifest recovery](../README.md#configuration-migration-and-recovery) when restoring
an old combined manifest.

## Tests

```bash
./setup-tools/tests/test-providers
./setup-tools/tests/test-bootstrap
./setup-tools/tests/test-configure
./setup-tools/tests/test-dispatch
./setup-tools/tests/test-zed
```

Tests use temporary homes and command doubles; they do not install packages on the host.
