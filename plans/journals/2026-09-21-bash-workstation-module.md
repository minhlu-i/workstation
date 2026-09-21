# Bash workstation module

Implemented the standalone module, generated templates, backups, preserved personal
files, mise-managed tools, Flyline/Starship initialization and command hints.

Validation used temporary homes and existing real tools. Syntax, repeated generation,
PATH/hints, hook preservation/execution, Flyline builtin, completion, executable
versions, Git/Python prompt rendering and negative verification passed. The prompt
test needed to unset inherited STARSHIP_SHELL and set a terminal type explicitly.

An isolated fresh-download attempt failed due to sandbox DNS. The user directed
reuse of installed tools; no reinstall or real shell replacement was performed.
Setup now installs only missing tools. Fresh-OS apt/download paths remain untested.

The journal CLI could not create its directory (read-only filesystem); this record
was saved directly in the project. AgentWiki publication was skipped.
