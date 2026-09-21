# Module conventions

- A root executable `setup-<area>` resolves its own location and dispatches to
  `modules/<area>/install` or `--verify`. It works from any current directory.
- Each module has a README declaring requirements, owned files, user-owned files,
  side effects, verification, recovery and supported platforms.
- Keep install, verify, templates (`files/`) and tests together in the module.
  Introduce shared libraries only after multiple modules need the same behavior.
- Installation is explicit, fails on errors and installs missing prerequisites.
  System packages belong to the platform package manager; development tools to mise.
- Generate owned files deterministically. Do not append startup blocks. Back up
  changed existing files before replacement. Never overwrite user-owned files.
- Verification returns nonzero for incomplete state; it does not install anything.
- Tests use temporary homes. Never provision the developer's real home as a test.
- Keep platform branches inside the module. macOS support must be tested before
  advertising it; recognizing Homebrew completion locations alone is not support.
- Plans live in `plans/<timestamp>-<slug>/`; they record execution state, while
  the module README is the current product documentation.
