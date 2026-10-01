# Phase 1: Bash module

Completed · Priority P2 · Original estimate: 8 hours.

Historical implementation plan for the standalone module. Its `modules/bash-workstation`
layout and APT-only Bash policy have since been replaced. See the
[current module conventions](../../docs/module-conventions.md).

## Installation and startup

Use APT for Bash and stop if version 5.3+ is unavailable. Preflight inputs, back up
changed files and replace managed paths atomically. Seed `local.bash` and
`45-user-aliases.bash` only when absent.

Install a guarded `.bashrc` loader. Load numbered fragments, then `local.bash`.
Use native history with a once-per-session `fc -ln -0` hint. Locate Flyline through
mise. Initialize Starship with `PROMPT_COMMAND` unset, then merge its hooks with
prior scalar/array hooks exactly once.

## Original files

| Path | Purpose |
| --- | --- |
| `setup-bash-workstation` | Root launcher |
| `modules/bash-workstation/{install,verify}` | Entry points |
| `modules/bash-workstation/files/bashrc` | Fragment loader |
| `modules/bash-workstation/files/rc.d/*.bash` | Ordered configuration |
| `modules/bash-workstation/files/local.bash` | User configuration seed |
| `modules/bash-workstation/files/mise.toml` | Tool declarations |
| `modules/bash-workstation/tests/` | Module, runtime and hint tests |
| `modules/bash-workstation/README.md` | Usage and recovery |

Root README and module conventions were read-only inputs during this phase.

## Work completed

1. Added platform detection, managed-path checks, content comparison, backups,
   syntax checks and atomic writes.
2. Added mise configuration before missing-tool installation; preserved shell files
   when downloads failed.
3. Added copied templates, ordered loading and user-file preservation.
4. Added completion, mise, zoxide, Flyline, Starship and history hints.
5. Added verification and temporary-home tests with real installed dependencies.

## Checks and limits

| Check | Result |
| --- | --- |
| Shell syntax and helper fixtures | Passed |
| First and repeated installation | Passed; user files preserved |
| Empty, scalar and array prompt hooks | Passed; prior hooks ran once |
| Starship prompt and session hint | Passed |
| Installed Bash 5.3+ and real dependencies | Passed |
| Deliberately broken configuration | Diagnosed by verifier |
| Fresh-OS APT/network installation | Untested |

Backups, syntax preflight and atomic writes protect startup during updates.
Runtime tests cover plugin hook changes; copied files keep startup independent
of checkout location.

Recovery restores affected backups and removes only newly created managed files
and the module's mise fragment. Preserve user files and shared mise installations.
