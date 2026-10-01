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

# Bash workstation setup

Completed on 2026-09-21. This records the original standalone Bash module;
the repo now uses separate tools, shell, Git and Docker modules. See the
[current README](../../README.md) for installation.

## Scope

Build `setup-bash-workstation` for Ubuntu / WSL2 with Bash 5.3+, repeatable
installation, backups and preserved user customizations. macOS was deferred.

The original global mise inventory was bat, delta, eza, fd, jq, ripgrep, Starship,
tealdeer, yq, zoxide and Flyline. Bash used APT; versions below 5.3 stopped setup
with upgrade instructions. No source-build fallback was included.

## Design

The launcher resolved its repo path and delegated to install or verify. Install
preflighted platform and input, backed up changed files, copied templates into
`~/.config/bash`, wrote a mise fragment and installed missing tools.
`~/.bashrc` contained a guarded loader; numbered fragments loaded before `local.bash`.

Flyline was located through mise at runtime. Verification exercised an interactive
shell. Tests used temporary homes and could reuse read-only host `MISE_DATA_DIR`.

Copied configuration survives checkout moves; updating it requires rerunning setup.
Recovery restores backups and removes only newly created managed files, preserving
user files and shared tools.

## Delivery and verification

[Phase 1](phase-01-module.md) completed installer, verifier, templates, tests and docs.

Checks passed for syntax, repeated installation, backup creation, user-file
preservation, PATH, session hints, completion, Flyline and Starship. Existing scalar
and array `PROMPT_COMMAND` hooks ran once. Verification identified a deliberately
missing fragment. Git/Python prompt rendering also passed.

Real dependency checks used Bash 5.3.9 and Flyline 1.8.0. Fresh-OS APT/download
installation remained untested; the user requested reuse of installed tools.
