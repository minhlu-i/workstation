# Workstation

Small, independently runnable modules for provisioning a development workstation.
The first module configures interactive Bash on Ubuntu / WSL2 with Bash 5.3+.

```bash
./setup-bash-workstation
./setup-bash-workstation --verify
```

Read the [Bash module](modules/bash-workstation/README.md) for prerequisites,
ownership, backups, verification and customization. Read the
[module conventions](docs/module-conventions.md) before adding a module.

There is no workstation-wide orchestrator yet. Future modules get separate
`setup-*` entrypoints; platform differences stay inside their owning module.

## GitHub maintenance

Manage GitHub CLI as a personal mise tool, separately from the Bash module:

```bash
mise use --global gh@latest
mise exec gh -- gh auth login --hostname github.com --git-protocol https --web
mise exec gh -- gh repo view
```
