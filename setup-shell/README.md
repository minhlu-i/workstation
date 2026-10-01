# Setup shell

| Platform | Shell | Completion and editing |
| --- | --- | --- |
| Ubuntu / WSL2 | Bash 5.3+ | bash-completion, Flyline |
| macOS | Zsh 5.8+ | Native completion, autosuggestions, syntax highlighting |

Both use Starship, zoxide, mise and once-per-session CLI hints.

```bash
./setup-tools/install.sh
./setup-shell/install.sh
./setup-shell/verify.sh
```

Apply configuration without installing dependencies:

```bash
./setup-shell/install.sh --configure-only
```

Shell selection follows the platform. `--shell bash|zsh` selects configuration or
verification explicitly; full installation supports Bash on Ubuntu / WSL2 and
Zsh on macOS.

## Dependencies

Setup reuses an adequate Bash or an existing Homebrew Bash before installing one.
It keeps `/bin/bash`, the login shell and login profiles unchanged. An ordinary
interactive session started with an older Bash can hand off to an adequate
Homebrew Bash through the managed `.bashrc`. This does not re-execute login
profiles. For `bash -ic` commands, invoke the adequate Bash directly.

Working system bash-completion is reused after checking `_completion_loader`.
Missing completion uses `brew install bash-completion@2`, which may install its
own Bash dependency.

macOS uses its existing Zsh. Missing autosuggestions and syntax highlighting use
Homebrew. Completion runs `compinit` with its security audit; highlighting loads
after user widgets and `local.zsh`.

`~/.config/mise/conf.d/setup-shell.toml` owns Starship, zoxide and Bash's Flyline
declarations. Working external Starship/zoxide are omitted. Flyline's shared
library is located through mise at startup.

## Files and customization

[Bash templates](files/bash) and [Zsh templates](files/zsh) share a
[Starship configuration](files/starship.toml) with an ASCII prompt.

| Destination | Ownership |
| --- | --- |
| `~/.bashrc` / `~/.zshrc` | Managed startup bootstrap |
| `~/.config/<shell>/bashrc` / `zshrc` | Managed fragment loader |
| Managed `~/.config/<shell>/rc.d/` fragments | PATH, history, aliases, completion, tools, prompt, hints |
| `rc.d/45-user-aliases.bash` / `.zsh` | User-owned; seeded only when absent |
| `~/.config/<shell>/local.bash` / `.zsh` | User-owned; loaded after ordinary fragments |
| Additional `rc.d/*.bash` / `*.zsh` | User-owned; preserved and syntax-checked |
| `~/.config/zsh/highlighting.zsh` | Managed final plugin loader |
| `~/.config/starship.toml` | Managed prompt |
| `~/.config/mise/conf.d/setup-shell.toml` | Managed shell tools |

Files are copied, so moving the checkout does not break startup. Existing startup
contents are backed up; move any wanted customizations into user-owned files.
Open a new shell after changes. Startup guards prevent duplicate hooks.

Setup requires default `~/.config` and mise paths. Zsh also requires `ZDOTDIR`
unset or equal to `HOME`. Before writing files, it evaluates your `.zshenv` to check
startup paths and `RCS`, including in configure-only mode. Login profiles and
`.zshenv` are preserved.

CLI hints suggest alternatives for simple `ls`, `cat`, `find`, `man` and recursive
`grep` commands. They preserve commands, Enter behavior, existing prompt hooks and
command status. Complex quoting, compound commands or history filtering can suppress hints.

## Recovery and verification

Changed managed files are backed up under
`~/.local/state/workstation/bash-workstation/backups/` for both shells. Identical
files create no backup. Restore affected home-relative paths from the printed
directory; preserve user files and shared tools. See
[manifest recovery](../README.md#configuration-migration-and-recovery) for old mise files.

Installation stops on failure without rolling back earlier steps. Fix the cause
and rerun.

Verification checks configuration and actual interactive startup: completion,
plugins, prompt, navigation, mise, history and hooks. It reports failed personal
fragments and can create normal history/completion caches. For headless checks:

```bash
TERM=xterm-256color ./setup-shell/verify.sh
```

## Tests

Fixture tests use temporary homes and command doubles:

```bash
./setup-shell/tests/test-module
./setup-shell/tests/test-install-dependencies
./setup-shell/tests/test-native-config  # requires Zsh
./setup-shell/tests/test-zsh            # requires Zsh
```

Runtime tests require installed dependencies:

```bash
./setup-shell/tests/test-runtime      # Bash/Flyline; Python for prompt checks
./setup-shell/tests/test-zsh-runtime  # Zsh, plugins, mise, Starship, zoxide
```

Missing prerequisites are reported. Check clean-machine installation and terminal
editing/completion separately.
