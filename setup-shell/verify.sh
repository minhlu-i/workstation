#!/usr/bin/env bash
set -euo pipefail
module=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
fail() { printf 'FAIL setup-shell: %s\n' "$*" >&2; exit 1; }
operation=verify
source "$module/options.bash"
source "$module/../setup-tools/dependencies.bash"
load_tool_environment
interpreter=$(command -v "$shell_name") || fail "Missing $shell_name"
if [[ $shell_name == bash ]]; then
    if ! "$interpreter" --noprofile --norc -c '(( BASH_VERSINFO[0] > 5 || (BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] >= 3) ))'; then
        interpreter=${HOMEBREW_PREFIX:-/home/linuxbrew/.linuxbrew}/bin/bash
        [[ -x $interpreter ]] || fail 'Bash 5.3+ unavailable; run setup-shell/install.sh.'
    fi
fi
[[ $shell_name != zsh ]] || check_zsh_startup_path
source_dir=$module/files/$shell_name
for file in "$HOME/.${shell_name}rc" "$HOME/.config/$shell_name/${shell_name}rc" "$HOME/.config/$shell_name/local.$shell_name" "$HOME/.config/$shell_name/rc.d/45-user-aliases.$shell_name" "$HOME/.config/$shell_name/rc.d/"*.$shell_name; do
    [[ -f $file ]] || fail "Missing: $file"
    "$interpreter" -n "$file"
done
cmp "$source_dir/bootstrap.$shell_name" "$HOME/.${shell_name}rc"
cmp "$source_dir/${shell_name}rc" "$HOME/.config/$shell_name/${shell_name}rc"
cmp "$module/files/starship.toml" "$HOME/.config/starship.toml"
for file in "$source_dir/rc.d/"*.$shell_name; do
    [[ ${file##*/} == 45-user-aliases.$shell_name ]] && continue
    cmp "$file" "$HOME/.config/$shell_name/rc.d/${file##*/}"
done
verify_mise_tools "$source_dir/mise.toml" "$HOME/.config/mise/conf.d/setup-shell.toml"
cd "$HOME"
export WORKSTATION_VERIFY_MODULE=$module
if [[ $shell_name == bash ]]; then
    "$interpreter" --noprofile --rcfile "$module/verify-rc.bash" -ic 'source "$WORKSTATION_VERIFY_MODULE/verify-runtime.bash"'
else
    cmp "$source_dir/highlighting.zsh" "$HOME/.config/zsh/highlighting.zsh"
    "$interpreter" -n "$HOME/.config/zsh/highlighting.zsh"
    # Check ordinary startup too; manually sourcing .zshrc alone can conceal a
    # user .zshenv that redirects or disables startup only when interactive.
    "$interpreter" -d -ic '[[ ${ZDOTDIR:-$HOME} == "$HOME" && ${__workstation_zsh_loaded-} == 1 && ${#__workstation_startup_failures} == 0 ]]' || fail 'Native Zsh startup did not load the managed configuration cleanly.'
    export MODULE=$module
    "$interpreter" -d -f -ic 'source "$MODULE/verify-rc.zsh"; source "$MODULE/verify-runtime.zsh"'
fi
