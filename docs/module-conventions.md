# Module conventions

Domains live directly at root: setup-tools, setup-shell, setup-git,
setup-docker and setup-workspace. Implemented domains own install.sh, verify.sh,
tests/ and files/ when deploying configuration. Planned domains have a README only, never a success-returning
installer. Platform-specific files are introduced only for real implementation.

setup.sh explicitly runs tools → shell → Git → Docker → doctor, stops on installation failure and
identifies the step. Doctor aggregates implemented verifiers and distinguishes
planned domains. Keep dispatch explicit; no plugin registry or framework. Resolve
paths relative to each entry point, independent of the caller's directory.

Root bootstrap.sh owns downloading the public main archive without Git/login and
running setup.sh from ~/.local/share/workstation. It requires existing Bash/curl/tar
and standard filesystem utilities, preserves terminal input, forwards shell
selection, and never invokes personalization. Download/extraction must complete
before replacing a bootstrap-owned copy; preserve that copy as a backup and refuse
unmanaged destinations/symlinks. A failed setup retains the downloaded source for
manual continuation. Archive updates and checkout Git updates remain separate.

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
- setup-git defaults to basic Git checks and init.defaultBranch=main only when
  no global default exists. Reuse existing preferences; never create/update
  identity, SSH or vault files in this path. Basic checks need Git only and doctor
  reports personalization as SKIP. Git installation remains owned by setup-tools.
  The optional install-personal.sh/verify-personal.sh entry points accept arbitrary
  workspace identities and optional SSH keys. Sources are an explicit local JSON
  profile or Bitwarden Secure Note/SSH key items. Interactive new mode collects
  GitHub username/email, a separate author name (defaulting to username) and
  workspace, generates an Ed25519 pair with ssh-keygen and saves its profile
  automatically; existing valid keys are reused. First interactive setup offers
  new/bitwarden choices. Bitwarden lists SSH-key metadata in a native multi-select
  checkbox menu, then collects GitHub usernames, emails, separate author names and
  workspaces, and creates selected folders. Preserve saved defaults independently;
  SSH transport selects keys by workspace, never by repository owner or author name.
  Per-workspace core.sshCommand covers existing repositories; setup-git owns
  40-git-workspace fragments in both shell rc.d directories for pre-clone selection.
  Preserve user-owned local/alias files and explicit transport overrides.
  Store item IDs to resolve duplicate names; cached refresh needs no chooser/note.
  Explicit Secure Note import remains compatible. No-source reruns stay offline;
  no implicit vault login. Version-1 profiles remain compatible. Identity-only
  setup needs Git/jq; SSH/bw dependencies apply only when their features are chosen.
  Private files use mode 600 and SSH directories mode 700; managed aliases disable
  agents. Stage/validate imports, lock setup-owned sessions and never log key JSON
  or remove passphrases. Rotation backups contain private keys. Default orchestration
  must not invoke these personal entry points.
- setup-docker owns OrbStack on macOS and native Engine on Ubuntu/WSL2, plus CLI,
  Compose and Buildx. OrbStack's cask supplies macOS tools; Linux uses official
  Docker APT packages, an exception to common-tool brew/mise ownership. Reuse
  working providers; never remove/upgrade packages or change Docker contexts.
  First launch, WSL systemd configuration and relogin remain manual. After tool
  verification, Linux setup adds the current non-root user to the docker group
  when needed, preserves other groups and explains root-equivalent access. Check
  saved versus active membership and print relogin/WSL restart instructions when
  the session is stale; doctor must still fail on inaccessible sockets. Only
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
