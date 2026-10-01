# Setup Docker

OrbStack on macOS; native Docker Engine on Ubuntu / WSL2 Ubuntu. Both include
Docker CLI, Compose and Buildx.

```bash
./setup-docker/install.sh
./setup-docker/verify.sh --tools-only
./setup-docker/verify.sh
```

Run as your normal user. There is no configure-only mode. Installation checks the
tools; default verification also requires a reachable local Engine.

## macOS

Setup reuses OrbStack in `/Applications` or `~/Applications`, or installs the
Homebrew cask. OrbStack supplies its CLI and plugins.

Open OrbStack once and complete its setup, then rerun the installer. Missing
first-launch tools cause installation to stop with instructions. Setup does not
launch the app. See [OrbStack installation](https://docs.orbstack.dev/install).

## Ubuntu and WSL2

Missing capabilities use Docker's official APT repository. A complete working
provider is reused. Conflicting packages, ambiguous repository configuration or
an APT transaction that would change existing packages stop setup for manual repair.
See [Docker installation](https://docs.docker.com/engine/install/ubuntu/).

Installing packages requires sudo and running systemd. A newly installed Engine
is enabled and started. Start an existing stopped Engine yourself:

```bash
sudo systemctl start docker
```

On WSL2, [enable systemd](https://learn.microsoft.com/en-us/windows/wsl/systemd)
if needed, run `wsl.exe --shutdown` from Windows, and reopen Ubuntu. Setup does not
edit `/etc/wsl.conf` or configure Docker Desktop integration.

After checking tools, setup adds your user to the `docker` group if needed,
preserving other memberships. This grants
[root-equivalent access](https://docs.docker.com/engine/install/linux-postinstall/).
Log out and back in to activate the change; on WSL2, shut down WSL and reopen it.
Then check:

```bash
docker info
./doctor/check.sh
```

Doctor uses your current permissions and fails if the session cannot access the socket.

## Verification

`--tools-only` checks Docker, Compose and Buildx without probing the daemon.
Default verification also runs `docker info` against the selected endpoint.

Endpoint selection follows `DOCKER_CONTEXT`, then `DOCKER_HOST`, then the current
context. It must resolve to the platform's local socket:

| Platform | Socket |
| --- | --- |
| macOS | `~/.orbstack/run/docker.sock` |
| Ubuntu / WSL2 | `/var/run/docker.sock` |

Contexts pointing to the same socket are accepted. Linux's canonical socket must
be an actual socket, rather than a symlink to another runtime. Remote endpoints
and Docker Desktop integration do not satisfy this check. Correct overrides or
select the intended context yourself.

Verification does not pull images, run containers, start services or change contexts.

## Recovery and tests

Installation does not roll back repository files, signing keys or packages if a
later step fails. Fix the reported issue and rerun.

```bash
./setup-docker/tests/test-linux
./setup-docker/tests/test-macos
./setup-docker/tests/test-verify
```

Tests use temporary homes and command doubles. Real installation and container
execution need separate checks.
