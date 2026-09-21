# Bash workstation audit fixes

Setup now validates every existing Bash fragment before writing managed files.
Startup records files whose source returns nonzero, and verification reports them
without enabling errexit in interactive shells. Runtime tests check Python before
setup and document it as a test prerequisite, not a module-installed tool.

Both test suites passed, including invalid-fragment preservation, failed local and
extra fragment sources, and recovery. An isolated PATH check confirmed missing
Python fails before HOME mutation. All 21 Bash files passed syntax checks; TOML and
local documentation links validated. Fresh apt/download provisioning and terminal
UX remain untested. No real-home configuration was installed.

The journal CLI returned a generic error, including with verbose diagnostics;
this entry was written directly to the repository. AgentWiki publish skipped.
