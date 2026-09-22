# Ubuntu Engine installation. Caller has already validated the operating system.
linux_package_installed() {
    [[ $(dpkg-query -W -f='${Status}' "$1" 2>/dev/null || :) == 'install ok installed' ]]
}
linux_capability_works() {
    case $1 in
        compose) working_command docker && docker compose version >/dev/null 2>&1 ;;
        buildx) working_command docker && docker buildx version >/dev/null 2>&1 ;;
        *) working_command "$1" ;;
    esac
}
linux_require_systemd() {
    if [[ ! -d /run/systemd/system ]] || ! systemctl show --property=Version --value >/dev/null 2>&1; then
        fail 'Docker installation requires running systemd. On WSL2, enable systemd in /etc/wsl.conf ([boot], systemd=true), then run wsl.exe --shutdown from Windows and reopen Ubuntu. Setup does not edit WSL configuration.'
    fi
}
# Directory argument keeps source inspection independently testable.
linux_inspect_sources() {
    local directory=$1 suite=$2 file count=0 matches content
    LINUX_DOCKER_SOURCE_PRESENT=0
    for file in "$directory/sources.list" "$directory"/sources.list.d/*.list "$directory"/sources.list.d/*.sources; do
        [[ -f $file ]] || continue
        content=$(sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' "$file")
        [[ $content == *download.docker.com* ]] || continue
        matches=$(printf '%s\n' "$content" | grep -c 'download.docker.com' || :)
        count=$((count + matches))
        # Reuse only unambiguous official Ubuntu stable entries; never rewrite
        # unfamiliar source configurations or their signing keys.
        if [[ $content != *https://download.docker.com/linux/ubuntu* ]] ||
           [[ $content == *download.docker.com/linux/debian* ]]; then
            fail "Conflicting Docker APT source: $file. Resolve the source manually before retrying."
        fi
        case $file in
            *.sources)
                printf '%s\n' "$content" | grep -Eq "^Suites: +$suite[[:space:]]*$" &&
                printf '%s\n' "$content" | grep -Eq '^Components: +stable[[:space:]]*$' &&
                [[ $content == *'Signed-By:'* && $content != *'Enabled: no'* ]] ||
                    fail "Unrecognized Docker APT source: $file. Review suite, stable component and signing key manually."
                ;;
            *)
                printf '%s\n' "$content" | grep -Eq "^deb +\\[[^]]*signed-by=[^]]+\\] +https://download\\.docker\\.com/linux/ubuntu/? +$suite +stable[[:space:]]*$" ||
                    fail "Unrecognized Docker APT source: $file. Review suite, stable component and signing key manually."
                ;;
        esac
    done
    (( count <= 1 )) || fail 'Multiple Docker APT entries found; resolve duplicates manually before retrying.'
    (( count == 0 )) || LINUX_DOCKER_SOURCE_PRESENT=1
    if (( ! LINUX_DOCKER_SOURCE_PRESENT )) && [[ -e $directory/sources.list.d/docker.sources || -L $directory/sources.list.d/docker.sources ]]; then
        fail 'Existing docker.sources is not a reusable Docker source; review it manually before retrying.'
    fi
}
linux_install_packages() {
    local simulation
    simulation=$(LC_ALL=C apt-get --simulate --no-upgrade install "$@" 2>&1) || fail "APT simulation failed: $simulation"
    # An Inst line with [old-version] is an upgrade/downgrade/reinstall.
    # --no-upgrade alone does not protect transitive dependencies.
    if printf '%s\n' "$simulation" | grep -Eq '^(Remv|Purg) |^Inst [^ ]+ \['; then
        fail "APT would change existing packages; refusing installation: $simulation"
    fi
    sudo apt-get install --no-upgrade --no-remove -y "$@" || fail 'Docker package installation failed; inspect the APT error and rerun setup.'
}
linux_prepare_repository() {
    local suite=$1 architecture=$2 directory=${3:-/etc/apt} temporary
    if (( LINUX_DOCKER_SOURCE_PRESENT )); then return; fi
    [[ ! -e "$directory/sources.list.d"/docker.sources && ! -L "$directory/sources.list.d"/docker.sources ]] || fail 'Docker source destination appeared during setup; inspect it before retrying.'
    [[ ! -L "$directory/keyrings/docker.asc" && ( ! -e "$directory/keyrings/docker.asc" || -f "$directory/keyrings/docker.asc" ) ]] || fail 'Docker signing key must be a regular file, not a symlink.'
    sudo install -m 0755 -d "$directory/keyrings" "$directory/sources.list.d" || fail 'Could not prepare Docker APT directories.'
    if [[ ! -e "$directory/keyrings/docker.asc" ]]; then
        temporary=$(mktemp) || fail 'Could not create temporary Docker key file.'
        if ! curl --proto '=https' --tlsv1.2 -fsSL https://download.docker.com/linux/ubuntu/gpg -o "$temporary"; then
            rm -f -- "$temporary"; fail 'Could not download Docker signing key.'
        fi
        sudo install -m 0644 "$temporary" "$directory/keyrings/docker.asc" || { rm -f -- "$temporary"; fail 'Could not install Docker signing key.'; }
        rm -f -- "$temporary"
    fi
    [[ -r "$directory/keyrings/docker.asc" ]] || fail 'Existing Docker signing key is unreadable; repair it manually.'
    printf 'Types: deb\nURIs: https://download.docker.com/linux/ubuntu\nSuites: %s\nComponents: stable\nArchitectures: %s\nSigned-By: %s/keyrings/docker.asc\n' "$suite" "$architecture" "$directory" |
        sudo tee "$directory/sources.list.d"/docker.sources >/dev/null || fail 'Could not add Docker APT source.'
}
linux_ubuntu_suite() {
    (. /etc/os-release; printf '%s' "${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}")
}
install_linux_docker() {
    local entry capability package conflict fresh_engine=0 suite architecture
    local packages=() prerequisites=()
    for entry in dockerd:docker-ce docker:docker-ce-cli compose:docker-compose-plugin buildx:docker-buildx-plugin containerd:containerd.io; do
        capability=${entry%%:*}; package=${entry#*:}
        linux_capability_works "$capability" && continue
        linux_package_installed "$package" && fail "$package is installed but $capability is unavailable/broken. Repair the installation or PATH before retrying."
        packages+=("$package")
        [[ $capability != dockerd ]] || fresh_engine=1
    done
    if (( ${#packages[@]} == 0 )); then
        printf 'Reuse existing Docker Engine, CLI, Compose, Buildx and containerd.\n'
        return
    fi
    for conflict in docker.io docker-compose docker-compose-v2 docker-buildx docker-doc podman-docker containerd runc; do
        linux_package_installed "$conflict" && fail "Incomplete Docker toolchain with conflicting package $conflict. Repair that provider manually; setup will not remove or replace it."
    done
    # A working unmanaged binary must not be silently combined with another
    # provider. Official package capabilities can safely be completed.
    for entry in dockerd:docker-ce docker:docker-ce-cli containerd:containerd.io; do
        capability=${entry%%:*}; package=${entry#*:}
        if linux_capability_works "$capability" && ! linux_package_installed "$package"; then
            fail "Existing $capability is not owned by the expected Docker package. Complete its provider manually before retrying."
        fi
    done
    linux_require_systemd
    suite=$(linux_ubuntu_suite)
    [[ $suite =~ ^[a-z][a-z0-9-]*$ ]] || fail 'Could not determine Ubuntu release codename.'
    architecture=$(dpkg --print-architecture) || fail 'Could not determine APT architecture.'
    [[ $architecture =~ ^[a-z0-9]+$ ]] || fail 'Unexpected APT architecture.'
    linux_inspect_sources /etc/apt "$suite"
    working_command curl || { linux_package_installed curl && fail 'curl is installed but unavailable/broken.'; prerequisites+=(curl); }
    linux_package_installed ca-certificates || prerequisites+=(ca-certificates)
    source "$module/../setup-tools/bootstrap.bash"
    require_bootstrap_sudo
    if (( ${#prerequisites[@]} )); then
        sudo apt-get update || fail 'APT update failed.'
        linux_install_packages "${prerequisites[@]}"
    fi
    linux_prepare_repository "$suite" "$architecture"
    sudo apt-get update || fail 'Docker APT update failed; inspect repository configuration.'
    linux_install_packages "${packages[@]}"
    hash -r
    linux_capability_works containerd || fail 'Docker packages installed but containerd is unavailable/broken.'
    if (( fresh_engine )); then
        sudo systemctl enable --now docker || fail 'Docker installed, but service startup failed; inspect systemctl status docker.'
    fi
}
