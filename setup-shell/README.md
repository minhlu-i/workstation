# Setup shell

Ubuntu/WSL2 uses Bash + Flyline. macOS uses Zsh with native completion/history,
[zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) and
[zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting).
Both use Starship, zoxide, mise activation and once-per-session CLI hints.
Oh My Zsh, Atuin and fzf are not part of this setup.

```bash
./setup-tools/install.sh
./setup-shell/install.sh
./setup-shell/install.sh --configure-only
./setup-shell/verify.sh
```

Native shell selection follows the OS. Explicit `--shell bash|zsh` is available
for offline configuration and verification; full installation supports only Bash
on Ubuntu/WSL2 and Zsh on macOS. Full setup requires setup-tools and prints its
command when prerequisites are missing. Configure-only installs nothing.

## Dependencies and existing providers

Bash must be 5.3+ for the Flyline baseline. An adequate existing Bash is reused;
otherwise setup searches for an already-installed brew Bash before installing it.
It never replaces `/bin/bash`, changes the account login shell, or edits profiles.
When an ordinary interactive session starts an older distro Bash, the managed
`.bashrc` can hand it to an already-installed adequate brew Bash. Login profiles
are not re-executed during this handoff. Explicit `bash -ic` command bodies are never
discarded; invoke the adequate Bash directly for those commands.

Bash has basic completion built in; `bash-completion` provides additional recipes.
Setup loads the available completion entry point in the selected Bash and checks
`_completion_loader`. Working system/apt completion is reused even when brew does
not own it. Only missing completion is installed via `brew install bash-completion@2`.
That formula may bring its own Bash dependency; existing system packages are retained.

Zsh 5.8+ is required; macOS's existing Zsh is used. Existing plugin files are checked
before installing missing plugins with brew. Native completion is initialized with
compinit's security audit. Syntax highlighting loads after custom widgets and
`local.zsh`. Plugin load failures are reported by verification.

Starship/zoxide and Bash's Flyline declarations belong to the selected shell's
`~/.config/mise/conf.d/setup-shell.toml`. Working external Starship/zoxide are reused
and omitted from this manifest. Flyline's shared library continues to be located
through mise. Common CLI and mise itself belong exclusively to setup-tools.

## Files and customization

The [Bash templates](files/bash) and [Zsh templates](files/zsh) mirror responsibilities
but use each shell's own syntax and hook APIs. [starship.toml](files/starship.toml)
is shared; its ASCII prompt does not require a Nerd Font.

| Destination | Ownership |
|---|---|
| `~/.bashrc` / `~/.zshrc` | Managed bootstrap for selected shell |
| `~/.config/bash/bashrc` / `~/.config/zsh/zshrc` | Managed ordered fragment loader |
| `~/.config/<shell>/rc.d/` managed fragments | PATH, history, aliases, completion, tools, prompt, hints |
| `rc.d/45-user-aliases.bash` / `.zsh` | User-owned; created only when absent |
| `~/.config/<shell>/local.bash` / `.zsh` | User-owned; loaded after ordinary fragments |
| Additional `rc.d/*.bash` / `*.zsh` | User-owned; preserved and syntax-checked |
| `~/.config/zsh/highlighting.zsh` | Managed final plugin loader |
| `~/.config/starship.toml` | Managed shared prompt configuration |
| `~/.config/mise/conf.d/setup-shell.toml` | Managed shell tool declarations |

Managed files are copied, so moving the checkout does not break startup. Existing
bootstrap contents are backed up, not executed automatically. Move wanted personal
configuration into the user-owned files. Startup is guarded against duplicate hooks;
open a new shell after editing customization. Zsh's ordinary `~/.zsh_history` and
completion cache remain native runtime data, not managed configuration templates.

Fixed `~/.config` paths are intentional. Non-default XDG/mise config paths are
rejected. Zsh requires `ZDOTDIR` unset or HOME, including in personal startup code;
no `.zshenv`, `.zprofile`, `.bash_profile` or unrelated profile is rewritten.
Before writing Zsh files, setup evaluates `.zshenv` in a noninteractive Zsh to
check its effective startup path and RCS setting. This runs personal `.zshenv` code,
including in configure-only mode, but does not load the old interactive `.zshrc`.

CLI hints suggest alternatives for simple leading ls/cat/find/man and recursive
grep commands. They do not rewrite commands or override Enter; history filtering,
compound commands and complex quoting can prevent hints. Zsh uses precmd hooks,
Bash uses PROMPT_COMMAND; both preserve existing hooks and incoming command status.

## Recovery and verification

Changed managed files are backed up at original home-relative paths under
`~/.local/state/workstation/bash-workstation/backups/`. The legacy directory name is
retained for both shells. Identical files produce no backup; user files are never
overwritten. Restore only the affected paths from the printed directory. For a newly
created file, remove it only if it is managed; preserve user customizations and
shared installations. See root [manifest migration recovery](../README.md#configuration-migration-and-recovery).

Installation is fail-fast, not transactional. Dependency installation or a previous
domain may have completed before a later step fails. Fix the cause and rerun.

Verification checks owned configuration, required commands and actual interactive
initialization: completion, plugins/Flyline, Starship prompt, zoxide, mise, history
and hook integrity. It also identifies failed personal startup fragments. It does
not install or repair files; normal runtime caches/history can be written by the
shell or plugins. For headless checks set `TERM=xterm-256color`.

See the root [test commands and limits](../README.md#verification). A configuration
or fixture pass is not proof of real plugin compatibility or clean OS bootstrap.
