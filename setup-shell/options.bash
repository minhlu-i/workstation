# Sourced by install/verify; Bash 3.2 compatible for macOS bootstrap.
mode=''
shell_name=''
while (( $# )); do
    case $1 in
        --configure-only) [[ ${operation-} == install ]] || exit 2; mode=$1; shift ;;
        --shell) (( $# >= 2 )) || { printf 'Missing --shell argument\n' >&2; exit 2; }; shell_name=$2; shift 2 ;;
        --help) printf 'Usage: setup-shell/%s.sh [--shell bash|zsh]\n' "$operation"; [[ $operation != install ]] || printf '  --configure-only: generate configuration without installation\n'; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
    esac
done
if [[ -z $shell_name ]]; then
    case $(uname -s) in
        Linux) shell_name=bash ;;
        Darwin) shell_name=zsh ;;
        *) printf 'Supported targets: Ubuntu/WSL2 and macOS\n' >&2; exit 1 ;;
    esac
fi
case $shell_name in bash|zsh) ;; *) printf 'Unsupported shell: %s\n' "$shell_name" >&2; exit 2 ;; esac
[[ ${XDG_CONFIG_HOME:-$HOME/.config} == "$HOME/.config" ]] || fail 'XDG_CONFIG_HOME must be ~/.config.'
[[ ${MISE_CONFIG_DIR:-$HOME/.config/mise} == "$HOME/.config/mise" ]] || fail 'MISE_CONFIG_DIR must be ~/.config/mise.'
[[ -z ${MISE_GLOBAL_CONFIG_FILE-} ]] || fail 'Unset MISE_GLOBAL_CONFIG_FILE.'
if [[ $shell_name == zsh ]]; then
    [[ ${ZDOTDIR:-$HOME} == "$HOME" ]] || fail 'ZDOTDIR must be unset or HOME; no alternate startup paths are modified.'
fi
check_zsh_startup_path() {
    # Zsh reads .zshenv even for noninteractive shells. Do not load/execute an
    # existing interactive .zshrc just to inspect its startup location.
    if [[ -f $HOME/.zshenv ]]; then "$interpreter" -n "$HOME/.zshenv" || fail 'Invalid ~/.zshenv; no shell configuration written.'; fi
    "$interpreter" -c '[[ ${ZDOTDIR:-$HOME} == "$HOME" && -o rcs ]]' >/dev/null 2>&1 ||
        fail 'Zsh startup redirects ZDOTDIR or disables RCS; adjust ~/.zshenv before setup. The file is not modified.'
}
