# Docker checks shared by installation and read-only verification (Bash 3+).
fail() { printf 'setup-docker: %s\n' "$*" >&2; exit 1; }
source "$module/../setup-tools/dependencies.bash"

docker_environment() {
    load_tool_environment
    append_tool_path "$HOME/.orbstack/bin"
    export PATH
    platform=$(uname -s)
    case $platform in
        Darwin) ;;
        Linux)
            source /etc/os-release
            [[ ${ID-} == ubuntu ]] || fail 'Supported Linux platform: Ubuntu/WSL2 Ubuntu.'
            ;;
        *) fail 'Supported platforms: macOS and Ubuntu/WSL2 Ubuntu.' ;;
    esac
}

orbstack_app() {
    local app
    for app in /Applications/OrbStack.app "$HOME/Applications/OrbStack.app"; do
        if [[ -x $app/Contents/MacOS/OrbStack ]]; then printf '%s\n' "$app"; return 0; fi
    done
    return 1
}

verify_docker_tools() {
    if [[ $platform == Darwin ]]; then
        orbstack_app >/dev/null || fail 'OrbStack app missing; run setup-docker/install.sh.'
    else
        working_command dockerd || fail 'Native Docker Engine missing/broken; run setup-docker/install.sh.'
    fi
    working_command docker || fail 'Docker CLI missing/broken. On macOS open OrbStack once to install its CLI, then rerun setup.'
    docker compose version >/dev/null 2>&1 || fail 'Docker Compose plugin missing/broken. On macOS complete OrbStack first launch and check existing CLI providers.'
    docker buildx version >/dev/null 2>&1 || fail 'Docker Buildx plugin missing/broken. On macOS complete OrbStack first launch and check existing CLI providers.'
    printf 'PASS Docker CLI, Compose, Buildx and platform runtime installation.\n'
}

native_docker_socket() { printf '/var/run/docker.sock\n'; }

verify_docker_runtime() {
    local endpoint context result native_socket
    # Match Docker CLI precedence without rewriting context or environment. Never
    # treat a remote server as evidence that this workstation is ready locally.
    if [[ -n ${DOCKER_CONTEXT-} ]]; then
        context=$DOCKER_CONTEXT
        endpoint=$(docker context inspect "$context" --format '{{.Endpoints.docker.Host}}') || fail 'Cannot inspect DOCKER_CONTEXT.'
    elif [[ -n ${DOCKER_HOST-} ]]; then
        endpoint=$DOCKER_HOST
    else
        context=$(docker context show) || fail 'Cannot read Docker context.'
        endpoint=$(docker context inspect "$context" --format '{{.Endpoints.docker.Host}}') || fail 'Cannot inspect Docker context.'
    fi
    case $endpoint in
        unix:///*) ;;
        *) fail "Selected Docker endpoint is not a local Unix socket: $endpoint. Select the local runtime explicitly; no context was changed." ;;
    esac
    if [[ $platform == Darwin ]]; then
        # Both the direct OrbStack socket and its compatibility symlink are valid.
        [[ -S $HOME/.orbstack/run/docker.sock && ${endpoint#unix://} -ef $HOME/.orbstack/run/docker.sock ]] ||
            fail 'Selected socket is not the running OrbStack socket. Start OrbStack and select its context; check DOCKER_HOST/DOCKER_CONTEXT overrides.'
    else
        native_socket=$(native_docker_socket)
        # Desktop WSL integration can redirect the canonical socket to its VM.
        # Native rootful dockerd creates a socket here, not a leaf symlink.
        [[ ! -L $native_socket && -S $native_socket && ${endpoint#unix://} -ef $native_socket ]] ||
            fail 'Native Docker socket missing or another runtime is selected. Check systemctl status docker and Docker context/environment; WSL needs systemd.'
    fi
    result=$(docker info --format '{{.OSType}}' 2>&1) ||
        fail "Cannot access Docker Engine at $endpoint: $result. Check runtime status and socket permissions; Ubuntu users may need sudo or docker-group access (see README)."
    [[ $result == linux ]] || fail 'Selected Engine is not a Linux container engine.'
    printf 'PASS local Linux Docker Engine: %s (no container run or image download).\n' "$endpoint"
}
