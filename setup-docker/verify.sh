#!/usr/bin/env bash
set -euo pipefail
module=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
case ${1-} in
    ''|--tools-only) (( $# <= 1 )) || exit 2 ;;
    --help) printf 'Usage: setup-docker/verify.sh [--tools-only]\nRead-only checks; no image pulls, container runs or runtime startup.\n'; exit 0 ;;
    *) exit 2 ;;
esac
source "$module/common.bash"
docker_environment
verify_docker_tools
[[ ${1-} != --tools-only ]] || exit 0
verify_docker_runtime
