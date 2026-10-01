# Bash workstation module — 2026-09-21

Completed the original standalone Bash module: installer, verifier, templates,
backups, user-file preservation, mise tools, Flyline, Starship and command hints.
The layout has since moved to the root-level setup modules.

Temporary-home checks passed for syntax, repeated generation, PATH, hints, prompt
hooks, completion, Flyline, executable versions and Git/Python prompt rendering.
Negative verification detected broken configuration. Prompt tests required clearing
inherited `STARSHIP_SHELL` and setting a terminal type.

A fresh-download attempt failed on sandbox DNS. The user requested reuse of
installed tools, so fresh-OS APT/download installation remained untested.
No real-home shell configuration was replaced.

This record was saved in the repo because the journal CLI could not write to its
read-only directory. AgentWiki publication was skipped.
