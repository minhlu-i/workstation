# Setup Docker

Implemented: OrbStack on macOS; native Docker Engine on Ubuntu/WSL2 Ubuntu;
Docker CLI, Compose and Buildx on both platforms.

```bash
./setup-docker/install.sh
./setup-docker/verify.sh --tools-only  # installation/capabilities; no daemon probe
./setup-docker/verify.sh               # also checks selected local Engine
```

Run setup as your normal user. Installation checks tools before returning success;
it does not claim the Engine is reachable. There is no configure-only mode.

## macOS

The installer reuses OrbStack in `/Applications` or `~/Applications`, or installs
the missing Homebrew `orbstack` cask. OrbStack supplies its Docker CLI and plugins;
setup does not install separate Homebrew Docker formulas or launch the app.

**First launch is a manual boundary:** open OrbStack and complete its setup, then
rerun the installer. Before first launch, missing CLI/plugins make installation
fail with instructions, even when the app was successfully installed. Existing
CLI providers are reused if working; broken providers require manual repair.
OrbStack's own first launch can install CLI links and update its compatibility
socket; see [OrbStack installation](https://docs.orbstack.dev/install).

## Ubuntu and WSL2 Ubuntu

[linux.bash](linux.bash) adds the official Docker APT repository when needed and
installs only missing capabilities. A complete working provider is reused. An
incomplete conflicting or unmanaged provider, ambiguous repository configuration,
or an APT transaction that would change existing packages stops with a repair
message. Setup does not remove packages, upgrade existing packages or migrate data.
See [Docker's Ubuntu installation guide](https://docs.docker.com/engine/install/ubuntu/).

Installation is not transactional: added repository files, signing keys and
successfully installed packages may remain after a later failure. Read the error,
repair the reported condition and rerun; setup does not automatically roll back
those additions.

Installing missing packages requires running systemd and sudo authorization. Only
a freshly installed Engine is explicitly enabled and started; setup leaves an
existing stopped Engine alone. Start it yourself when ready with
`sudo systemctl start docker`.

On WSL2, enable systemd if needed using
[Microsoft's instructions](https://learn.microsoft.com/en-us/windows/wsl/systemd),
then run `wsl.exe --shutdown` from Windows and reopen Ubuntu before retrying.
Setup does not edit `/etc/wsl.conf` or configure Docker Desktop integration.

Socket access is a separate user choice. Use `sudo docker info` to check privileged
access, or explicitly configure membership in the `docker` group using
[Docker's post-installation steps](https://docs.docker.com/engine/install/linux-postinstall/).
That group grants root-equivalent privileges; setup never adds users to it. Log
out and back in after changing membership. Doctor runs as your current user and
fails if that user cannot access the socket; do not run the entire setup as root.

## Verification and scope

[verify.sh](verify.sh) checks the platform runtime installation and working
`docker`, `docker compose`, and `docker buildx` commands. Default verification also
resolves the selected endpoint using Docker precedence: `DOCKER_CONTEXT`, then
`DOCKER_HOST`, then the current context. It must identify the OrbStack socket
`~/.orbstack/run/docker.sock` on macOS or `/var/run/docker.sock` on Linux. Selected
aliases to the same socket are accepted, but Linux's canonical `docker.sock` must
itself be a socket, not a leaf symlink forwarding to another runtime such as Docker
Desktop's WSL integration. Remote endpoints and other local runtimes do not
count as readiness for this domain. Correct overrides or select the intended
context yourself; the scripts never switch it.

Runtime verification uses `docker info` to require a reachable Linux Engine. It
does not pull images, run containers, start services, alter contexts or repair
configuration. Consequently a stopped runtime, stale context or missing socket
permission makes doctor fail even after tools installation succeeds.

One setup command can install dependencies, but OrbStack first launch, WSL restart
and optional group membership/relogin remain manual steps. Tests use isolated
homes and command doubles; they do not provision the host or prove clean-machine
installation or real container execution.
