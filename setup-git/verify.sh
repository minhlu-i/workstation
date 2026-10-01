#!/usr/bin/env bash
set -euo pipefail
module=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
case ${1-} in
    ''|--config-only) (( $# <= 1 )) || exit 2 ;;
    --help) printf 'Usage: setup-git/verify.sh [--config-only]\nChecks Git and default branch; identity and SSH are not assessed.\n'; exit 0 ;;
    *) printf 'Usage: setup-git/verify.sh [--config-only]\n' >&2; exit 2 ;;
esac
source "$module/common.bash"
check_git_environment
branch=$(git config --global --includes --get init.defaultBranch) || fail 'Git default branch missing; run setup-git/install.sh.'
git check-ref-format --branch "$branch" >/dev/null 2>&1 || fail 'Invalid init.defaultBranch; repair your Git configuration.'
printf 'PASS Git executable and default branch (%s). Identity/SSH authentication not checked.\n' "$branch"
