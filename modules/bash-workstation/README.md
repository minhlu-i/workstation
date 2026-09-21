# Bash workstation

Configures interactive Bash with native history, bash-completion, mise, zoxide,
Flyline, Starship and educational CLI hints. Ubuntu / WSL2 with Bash 5.3+ is the
supported target. macOS installation is not implemented; completion lookup already
recognizes standard Homebrew paths.

```bash
./setup-bash-workstation                   # install missing dependencies, configure, verify
./setup-bash-workstation --configure-only  # generate files; no package/tool downloads
./setup-bash-workstation --verify          # check installed configuration and real runtime
```

Run as the intended user, not `sudo ./setup-bash-workstation`: only apt operations
use sudo. The entrypoint works from any directory. It does not change the login
shell or terminal profile. Start a new Bash shell after installation.

## Prerequisites and tool ownership

The installer checks Ubuntu and installs missing apt packages: Bash,
bash-completion, ca-certificates, curl, git, less and xz-utils. It attempts an apt
Bash upgrade when needed, then re-executes `/bin/bash`. If the available version
is older than 5.3, it stops before shell configuration changes with upgrade guidance.
Older Ubuntu releases may therefore require an OS upgrade. It does not compile
Bash or replace `/bin/bash` outside apt.

If mise is missing, the installer downloads its official HTTPS installer from
[mise.run](https://mise.jdx.dev/getting-started.html) into a temporary file and
installs it at `~/.local/bin/mise`. Existing mise is reused.

The [tool manifest](files/mise.toml) declares `latest` for bat, delta, eza, fd,
jq, ripgrep, starship, tealdeer, yq, zoxide and `github:HalFrgrd/flyline`.
An existing resolved mise installation is reused. Only missing tools are installed;
setup does not force upgrades or downloads on every run. Upgrade tools separately
with mise when desired. No development runtime such as Node or Python is installed
by this module; Starship detects runtimes already present in each project.

## Files and ownership

| Destination | Owner and behavior |
|---|---|
| `~/.bashrc` | Module; replaced with a bootstrap, previous contents backed up |
| `~/.config/bash/bashrc` | Module; interactive guard, ordered fragments, local customization |
| `~/.config/bash/rc.d/10-shell.bash` | Module; window size, lesspipe, PATH deduplication |
| `20-history.bash` | Module; native history, ignoreboth, append, 1000/2000 limits |
| `30-prompt.bash` | Module; fallback prompt |
| `40-aliases.bash` | Module; reserved, does not replace Unix commands |
| `45-user-aliases.bash` | User; created only when absent |
| `50-completion.bash` | Module; bash-completion |
| `60-tools.bash` | Module; mise and zoxide activation |
| `70-flyline.bash` | Module; dynamic shared-library load and theme/mouse settings |
| `80-starship.bash` | Module; prompt activation with hook preservation |
| `90-modern-cli-hints.bash` | Module; once-per-session hints |
| `~/.config/bash/local.bash` | User; created only when absent, loaded last |
| `~/.config/starship.toml` | Module; bracketed ASCII labels and Starship runtime detection |
| `~/.config/mise/conf.d/bash-workstation.toml` | Module; only this module's tool declarations |
| `~/.local/state/workstation/bash-workstation/backups/` | Module; original files replaced in each changed run |

The fixed `~/.config` layout is intentional. Non-default `XDG_CONFIG_HOME`,
`MISE_CONFIG_DIR`, or an explicit `MISE_GLOBAL_CONFIG_FILE` are rejected during
setup to prevent generating one configuration while tools read another.
Other mise configuration files and unrelated shell/profile files are not edited.
The shell loads `.bash` fragments in filename order. Source the entrypoint twice
and its per-shell guard prevents duplicate activation/hooks. Edit user-owned files
for customizations; open a new shell to apply changes.
Before writing managed configuration, setup checks the syntax of `local.bash`
and every existing `rc.d/*.bash`, including personal fragments.

Existing `.bashrc` content is backed up, not automatically executed. Review it and
move wanted customizations into `local.bash`. This avoids activating old competing
prompt/tool stacks twice. Managed files are copied, so moving/deleting the checkout
does not break the installed shell. Rerun setup to deploy repository changes.

## Prompt and hints

The prompt uses home-relative directories, Git branch/counts, and Starship's own
runtime detection. For example:

```text
[~/projects/example] [git:codex/test] [?:1] [python:v3.14.4]
>
```

No Nerd Font is needed. Command duration is disabled. Flyline owns editing,
highlighting, suggestions, completion UI and history UX; Starship owns prompt
rendering. Flyline's install directory is resolved with `mise where` on startup;
no release version is embedded in the shell files.

The hint hook inspects `fc -ln -0`, suggesting eza/bat/fd/tldr for ls/cat/find/man,
and rg only for recursive grep. It preserves existing scalar/array prompt hooks,
returns the incoming status, and suggests each alternative at most once per shell
when installed. It observes simple leading commands, not a full shell grammar;
commands hidden by `HISTCONTROL`, compound commands, sudo prefixes or complex
quoting may not produce a hint. It never rewrites a command or overrides Enter.

## Verification and development

```bash
./setup-bash-workstation --verify
./modules/bash-workstation/tests/test-module
./modules/bash-workstation/tests/test-runtime
```

Tests require the real mise tools already installed. The runtime test also requires
a working `python3` or `python` on PATH to verify Python prompt detection; it stops
with a prerequisite message if neither is available. The module does not install Python.
Tests create temporary homes
and reuse those installations without downloading or reinstalling tools.
Verification checks owned-file content and all generated Bash syntax, Bash version,
bash-completion, mise-managed executables, zoxide initialization, Flyline builtin
and configuration, Starship initialization, and prompt-hook preservation/re-sourcing.
Runtime tests also execute preexisting hooks, render a real Git/Python project
prompt, and prove that a missing fragment fails verification.
Verification also fails and identifies any startup file whose `source` returns
nonzero. Ordinary interactive startup continues through the remaining files;
this check does not enable `errexit` or catch errors a file handles internally.

Without a terminal, interactive Bash may print `no job control in this shell`;
the exit status and PASS/FAIL checks remain authoritative. Starship requires a
non-dumb terminal type; for headless verification use `TERM=xterm-256color ./setup-bash-workstation --verify`. A terminal smoke test is
still needed for the subjective editing/completion/highlighting experience.

## Recovery and limitations

Each changed existing file is saved at its original relative path below a unique
backup directory printed by setup. Identical files are untouched, so a second run
does not create needless backups. Replacements use a temporary file and rename.
Installation is fail-fast, not a transaction over the entire home: if tool download
fails, the mise fragment may already have changed, but shell files are written only
after tool installation. Rerun after resolving the error, or restore the affected
files from the printed backup directory.

To roll back, restore each desired backed-up file to its corresponding home path.
For files created from scratch, remove only the module-owned paths listed above.
Keep `local.bash`, `45-user-aliases.bash`, shared mise installations and unrelated
configuration. No automated uninstall removes shared tools.

First-install downloads and apt operations were not exercised on a fresh OS in
this environment; tests reused the workstation's installed dependencies. Bash
startup/runtime behavior was checked with Bash 5.3.9 and Flyline 1.8.0.
