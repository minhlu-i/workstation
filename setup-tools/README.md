# Setup tools

Checks Homebrew, mise, base commands (`curl`, `git`, `less`, `xz`) and the common
CLI inventory in [files/mise.toml](files/mise.toml). Reuses working executables before
considering installation, independently of their package manager. It never removes
apt packages or automatically upgrades existing tools.

```bash
./setup-tools/install.sh
./setup-tools/install.sh --configure-only
./setup-tools/verify.sh
```

Missing Homebrew uses its official installer after the [bootstrap helper](bootstrap.bash)
prepares missing OS prerequisites. Ubuntu uses sudo + apt-get; macOS requests CLT
and rechecks completion. Authentication happens at privileged steps through sudo;
see the root [bootstrap instructions](../README.md#platforms-and-package-ownership).
Missing base commands and mise use brew. Missing common CLI use mise with the
existing `latest` policy. Existing resolved mise installations are reused.
No project language runtimes or project requirements belong here.

The CLI inventory includes Bitwarden CLI (`bw`, mise tool `bitwarden`), Codex CLI
(`codex`) and Claude Code CLI (`claude`) on
macOS, Ubuntu and WSL2. Missing installations use the corresponding
[mise registry](https://mise.jdx.dev/registry) entries; working external installs
(including Homebrew or native installers) are reused. Setup does not install a
global Node.js runtime for these tools or upgrade existing installations.
Doctor checks `--version`, not account access. Optional Git personalization can
use bw to restore profiles/local keys, or use a local profile without bw. Basic
setup does not access the vault. See [setup-git](../setup-git/README.md). Run `codex` or `claude` yourself
after setup to sign in; credentials, settings, skills and plugins remain user-owned.
See [Codex CLI](https://developers.openai.com/codex/cli) and
[Claude Code setup](https://code.claude.com/docs/en/setup).

The [dependency checks](dependencies.bash) preserve existing PATH precedence and
avoid executing mise shims during discovery. External tools are checked with
`--version`; yq additionally requires the Mike Farah implementation. The manifest
at `~/.config/mise/conf.d/bash-workstation.toml` contains only the subset requiring
mise. This legacy filename is preserved to migrate the old combined file in place.
Other mise configuration remains user-owned. Doctor validates the allowed manifest
subset and the actual provider of each required tool; it does not require that brew
or mise own an otherwise working external executable.

Before replacing an old combined manifest, the shell-owned
[migration helper](../setup-shell/manifest.bash) preserves its shell declarations.
Shell dependencies and their separate manifest belong to
[setup-shell](../setup-shell/README.md).

The shared [file writer](file-operations.bash) preserves atomic replacement,
backups and user files. Its existing backup location remains
`~/.local/state/workstation/bash-workstation/backups/`. Restore home-relative paths
from the printed backup directory; see root [migration recovery](../README.md#configuration-migration-and-recovery)
when restoring an old combined manifest. Do not uninstall shared tool installations
as part of configuration recovery.

Zed is installed only when missing: the [Homebrew cask](https://formulae.brew.sh/cask/zed)
on macOS and the [official installer](https://zed.dev/docs/installation) on native
Ubuntu. WSL skips both installation and verification; install the Windows editor
separately. Linux does not use a Homebrew cask or a mise tool declaration.
Existing working Zed installations are reused; broken/partial installations require
manual repair. Linux installs to `~/.local/zed.app` with a CLI in `~/.local/bin`.
Setup does not launch Zed or manage settings/extensions; restore your online
configuration manually. `--configure-only` does not install or check Zed.
Doctor checks CLI availability, not graphical startup, GPU support or settings sync.

Run `bash setup-tools/tests/test-zed` for isolated platform/provider fixtures.
