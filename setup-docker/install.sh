#!/usr/bin/env bash
set -euo pipefail
module=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
case ${1-} in
    '') (( $# == 0 )) || exit 2 ;;
    --help) printf 'Usage: setup-docker/install.sh\nmacOS: OrbStack. Ubuntu/WSL2: native Docker via official APT repository.\n'; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
esac
source "$module/common.bash"
docker_environment
case $platform in
    Darwin) source "$module/macos.bash"; install_macos_docker ;;
    Linux) source "$module/linux.bash"; install_linux_docker ;;
esac
verify_docker_tools
[[ $platform != Linux ]] || linux_configure_docker_access
printf 'Installation checked. Run setup-docker/verify.sh for local Engine readiness.\n'
