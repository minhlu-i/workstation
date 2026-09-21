---
title: "Idempotent Bash workstation setup"
description: "Create an independently runnable Ubuntu/WSL2 Bash 5.3+ workstation installer with durable customization and verification."
status: completed
priority: P2
effort: 8h
branch: ""
tags: [feature, infra, shell]
blockedBy: []
blocks: []
created: 2026-09-21
---
# Idempotent Bash Workstation Setup

## Outcome, constraints, and non-goals
`./setup-bash-workstation` installs and verifies the Bash module without an orchestrator or another module. Runs converge safely, back up replacements, and preserve user files. Support Ubuntu/WSL2 with Bash 5.3+; keep a platform seam for future macOS but do not implement it. Install globally through mise: latest `bat`, `delta`, `eza`, `fd`, `jq`, `ripgrep`, `starship`, `tealdeer`, `yq`, `zoxide`, and `github:HalFrgrd/flyline`. Follow the established ownership and temporary-home rules in [module conventions](../../docs/module-conventions.md); do not write unrelated project/home paths.

## Architecture and data flow
The root launcher resolves its repository path and delegates to `install` or `verify`. Install detects platform/Bash, preflights inputs, backs up changed files, copies deterministic templates into `~/.config/bash`, writes a separate mise `conf.d` fragment, installs tools, and places only a guarded bootstrap in `~/.bashrc`. Startup sources numbered rc files then user `local.bash`; tool rc dynamically locates Flyline. Verify reads installed state and exercises an interactive subprocess. Tests redirect `HOME` and may reuse a read-only host `MISE_DATA_DIR`.

## Phase and dependency
| Phase | Status | Blocker | Deliverable |
|---|---|---|---|
| [Build, test, and document the module](./phase-01-module.md) | Complete | None | Installer, verifier, templates, tests, module docs |

## Acceptance
- `bash -n` passes; isolated install succeeds twice without duplicate sources or needless second-run backups.
- Existing replaced files are backed up; `local.bash` and `45-user-aliases.bash` remain byte-identical.
- Fresh interactive Bash loads completion, mise/zoxide, dynamic Flyline, plain bracketed Starship, and every prior `PROMPT_COMMAND` hook.
- `fc -ln -0` supplies a once-per-session history hint without wrappers; focused tests prove hook/hint behavior.
- Verify succeeds on intact state and pinpoints broken files, tools, sources, or hooks; real Bash 5.3 runs where available.

## Decision, trade-off, and rollback
**Default decision:** Bash older than 5.3 fails with upgrade guidance after apt; this preserves the requested package-manager ownership. No source-build fallback was authorized. Managed files use copies: they survive checkout moves, but updates require rerunning install; symlinks update immediately but break when the checkout moves. Better approaches: none — the requested modular design fits independent installation and verification. Rollback restores latest backups, removes only module-created managed files and its mise fragment, and preserves user files/shared mise data.

## Verification evidence
Completed isolated-home repeated generation, backups/user preservation, PATH and hint
tests; real installed mise tools, Bash 5.3.9, Flyline 1.8.0, completion and Starship
checks; scalar/array hook retention and execution; Git/Python prompt rendering;
negative verification for a missing fragment. Fresh-OS apt/download paths remain
unvalidated: user directed reuse of installed tools, with no reinstall.
