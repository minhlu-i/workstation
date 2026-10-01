# Module conventions

Domains live directly at root: setup-tools, setup-shell, setup-git,
setup-docker and setup-workspace. Implemented domains own install.sh, verify.sh,
tests/ and files/ when deploying configuration. Planned domains have a README only, never a success-returning
installer. Platform-specific files are introduced only for real implementation.

setup.sh explicitly runs tools → shell → Git → Docker → doctor, stops on installation failure and
identifies the step. Doctor aggregates implemented verifiers and distinguishes
planned domains. Keep dispatch explicit; no plugin registry or framework. Resolve
paths relative to each entry point, independent of the caller's directory.

Each dependency/configuration has one domain owner, independently of its installed
provider. Check actual capability before installing; a working apt/system/brew/mise
tool does not need a second installation just because the preferred manager does
not own it. Do not uninstall, take over or silently upgrade existing tools.

- setup-tools owns Homebrew bootstrap, mise/base-command checks, common CLI and
  Zed installation (macOS cask, official Linux installer, skipped on WSL).
  Zed settings/extensions are restored by the user from their online configuration.
  Missing CLI additions use brew/mise. Missing Homebrew bootstrap prerequisites
  use apt-get/CLT within setup: sudo owns password entry; never capture credentials.
  Fail clearly on cancelled/noninteractive authentication and incomplete CLT.
- setup-shell owns Bash/Zsh, their completion/editor plugins, Starship/zoxide,
  Flyline on Bash, and their configuration. Native selection is Ubuntu/WSL2 Bash
  and macOS Zsh. No login-shell/default-profile changes.
- Existing managed mise paths remain: bash-workstation.toml for common CLI and
  setup-shell.toml for shell tools under ~/.config/mise/conf.d/. Manifests contain
  the approved subset needing mise; working external tools are omitted. The
  latest/missing-only policy remains for mise-managed entries.
- setup-git owns fixed Workspace identities, Git preferences and GitHub SSH aliases
  with local private/public key pairs restored through Bitwarden CLI. Git metadata
  comes from a Secure Note; key material comes from SSH key items. Private files
  use mode 600 and SSH directories mode 700; disable agents for managed aliases.
  Stage/validate imports before deployment, lock setup-owned sessions and never
  log key JSON or remove passphrases. Offline reruns reuse the local profile/keys.
  No Git version pin or global ignore. Rotation backups contain private keys.
- setup-docker owns OrbStack on macOS and native Engine on Ubuntu/WSL2, plus CLI,
  Compose and Buildx. OrbStack's cask supplies macOS tools; Linux uses official
  Docker APT packages, an exception to common-tool brew/mise ownership. Reuse
  working providers; never remove/upgrade packages or change Docker contexts.
  First launch, WSL systemd configuration and group membership are manual. Only
  a newly installed Linux Engine is explicitly enabled/started. Tools-only checks
  never probe the daemon; doctor requires the selected platform's local socket.
- Project runtimes belong to each project's mise.toml. Planned domains own no
  current files. Personal mise files and shell customizations remain user-owned.

Keep files/bash and files/zsh modular within setup-shell; share Starship's config,
not shell-specific syntax or hooks. Preserve deployed Bash paths. New Zsh paths
mirror Bash, with highlighting loaded after local widgets. No Oh My Zsh, Atuin/fzf
or additional dotfile manager is introduced.

Managed output is deterministic. Back up changed files before atomic replacement;
never append startup blocks or overwrite user-owned local/alias files. The two
domains share setup-tools/file-operations.bash and provider helpers because they
use the same ownership rules. Preserve the legacy backup location, including for
Zsh. Document partial migration/recovery; installation is not transactional.

Configure-only never invokes package managers/downloaders and does not promise
runtime readiness. Doctor never installs or repairs configuration; it checks
capabilities and configuration, not package-manager ownership alone. Interactive
verification executes personal startup code and may create normal runtime caches.

Tests use temporary homes. Distinguish fixture/provider tests, real shell behavior,
actual installed dependency runtime and clean-machine bootstrap. Report missing
prerequisites explicitly, never as passes. Keep upstream plugin init assumptions
verified; shell hook names differ between Bash and Zsh. macOS and Ubuntu support
must be reported with actual verification limits, not inferred from path detection.
