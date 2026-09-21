# Phase 1: Build, test, and document the Bash module

## Contract
**Status:** Complete · **Priority:** P2 · **Estimate:** 8h. Use apt for Bash; stop with upgrade instructions if 5.3+ remains unavailable. Install is fail-fast, idempotent, atomically replaces allowlisted managed paths after backups, and never overwrites `~/.config/bash/local.bash` or `rc.d/45-user-aliases.bash` after create-if-absent seeding.

`~/.bashrc` receives only one guarded bootstrap. Generated `bashrc` sources numbered files deterministically then `local.bash`. History remains native; the session hint directly calls `fc -ln -0` once. The separate mise fragment declares every requested global latest tool. Flyline is discovered from the active mise installation at runtime. Starship initializes with `PROMPT_COMMAND` unset, then merges its result with every prior scalar/array hook exactly once.

## File ownership
| Files | Action and owner |
|---|---|
| `setup-bash-workstation` | Create root launcher |
| `modules/bash-workstation/{install,verify}` | Create module entrypoints |
| `modules/bash-workstation/files/bashrc` | Create installed entrypoint |
| `modules/bash-workstation/files/rc.d/*.bash` | Create ordered configuration; installed `45-*` becomes user-owned |
| `modules/bash-workstation/files/local.bash` | Create seed; installed copy becomes user-owned |
| `modules/bash-workstation/files/mise.toml` | Create independent tool fragment |
| `modules/bash-workstation/tests/{test-module,test-runtime,test-hints.bash}` | Create isolated integration/runtime tests |
| `modules/bash-workstation/README.md` | Create module ownership, usage, update, verify, rollback docs |
| `README.md`, `docs/module-conventions.md` | Existing foundation; read only in this phase |

## Implementation steps
1. Add launcher and installer helpers for resolved paths, Ubuntu/WSL2/Bash detection, destination allowlisting, content comparison, timestamped backups, syntax checks, and atomic rename. Keep an explicit unimplemented macOS dispatch boundary.
2. Add mise fragment/install handling; preflight platform before home mutation; write mise fragment before missing-tool installation and retain shell files on download failure.
3. Add templates, deterministic source order, create-if-absent user files, and a bootstrap-only `.bashrc`, preserving previous content in backups.
4. Add runtime init: guarded completion/mise/zoxide, dynamic Flyline path lookup, and Starship snapshot-unset-init-merge for scalar/array `PROMPT_COMMAND`; add one session variable for the history hint.
5. Add read-only verify checks and tests in temporary homes, reusing installed tools through `MISE_DATA_DIR`; document ownership, copy-based updates, apt-only Bash policy, and recovery.

## Test matrix and success gate
| Layer | Cases and pass condition |
|---|---|
| Syntax/unit | Every shell file passes `bash -n`; copy/backup/source helpers pass fixtures |
| Install | Clean and second run converge; backups exist; user files are byte-identical; failed tool install is recoverable |
| Runtime | Interactive/noninteractive plus empty/scalar/array hooks load expected features; each prior hook runs once |
| Prompt/hint | Bracketed Starship remains; `fc -ln -0` occurs once; no command/history/prompt wrapper appears |
| System | On available Ubuntu/WSL2 Bash 5.3+, configure and verify with real installed dependencies succeed; fresh-OS install is unvalidated |

## Risks and rollback
| Risk (likelihood/impact) | Mitigation |
|---|---|
| Starship changes hook shape (M/H) | Test three shapes; snapshot/unset/init/merge with deduplication |
| Partial write breaks startup (L/H) | Preflight, temp write, syntax check, atomic rename, backup |
| Reinstall loses user edits (M/H) | Create-if-absent semantics plus two-run byte checks |
| mise/network/Flyline fails (M/M) | Fail intact, discover dynamically, return focused verification error |
| Checkout moves (M/L) | Copy files and require rerun; keep runtime independent of repository |

Rollback restores latest per-file backups and removes only created managed files plus this module's mise fragment. It preserves user files and original `.bashrc` backups, shared mise data, or tools other workflows may use. Implementation checks passed; verify diagnoses an intentionally broken fixture. Fresh-OS apt/network provisioning remains unvalidated, explicitly documented in the module README.
