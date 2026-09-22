#!/usr/bin/env bash
set -euo pipefail
module=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
(( $# == 0 )) || { printf 'Usage: setup-tools/verify.sh\n' >&2; exit 2; }
source "$module/dependencies.bash"
load_tool_environment
failures=0
fail() { printf 'FAIL setup-tools: %s\n' "$*" >&2; failures=$((failures+1)); }
[[ ${XDG_CONFIG_HOME:-$HOME/.config} == "$HOME/.config" &&
   ${MISE_CONFIG_DIR:-$HOME/.config/mise} == "$HOME/.config/mise" &&
   -z ${MISE_GLOBAL_CONFIG_FILE-} ]] || fail 'Non-default mise/config paths are unsupported.'
[[ -n $BREW ]] && "$BREW" --version >/dev/null 2>&1 || fail 'Missing/broken Homebrew; run setup-tools/install.sh.'
for command in curl git less xz mise; do
    working_command "$command" || fail "Missing/broken prerequisite: $command; run setup-tools/install.sh."
done
verify_mise_tools "$module/files/mise.toml" "$HOME/.config/mise/conf.d/bash-workstation.toml" || fail 'Common CLI dependencies/configuration missing or changed; run setup-tools/install.sh.'
(( failures == 0 )) || exit 1
printf 'PASS setup-tools\n'
