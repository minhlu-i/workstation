# Bash workstation audit fixes — 2026-09-21

Added syntax checks for existing Bash fragments before managed writes. Startup
records failed fragment sources, and verification reports them without enabling
`errexit` in interactive shells.

Runtime tests now check Python before setup; Python is a test prerequisite.
Both suites passed, covering invalid fragments, failed local/extra sources and
recovery. A restricted-PATH check confirmed missing Python fails before home writes.
All 21 Bash files passed syntax checks; TOML and local documentation links validated.

Fresh APT/download installation and terminal UX remained untested. No real-home
configuration was installed.

The journal CLI failed, including with verbose diagnostics, so this record was
saved in the repo. AgentWiki publication was skipped.
