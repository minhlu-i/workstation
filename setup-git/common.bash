# Shared Git environment checks and file permissions.
fail() { printf 'setup-git: %s\n' "$*" >&2; exit 1; }
check_git_prerequisites() {
    [[ ${HOME-} == /* && $HOME != *$'\n'* && $HOME != *'"'* && $HOME != *'$'* && $HOME != *'%'* && $HOME != *'\'* ]] || fail 'HOME must be an absolute literal path without SSH expansion characters.'
    [[ ${XDG_CONFIG_HOME:-$HOME/.config} == "$HOME/.config" ]] || fail 'XDG_CONFIG_HOME must be ~/.config.'
    [[ -z ${GIT_CONFIG_GLOBAL-} && -z ${GIT_CONFIG_SYSTEM-} && -z ${GIT_CONFIG_COUNT-} && -z ${GIT_CONFIG_PARAMETERS-} ]] || fail 'Unset Git config overrides before setup/verification.'
    command -v git >/dev/null || fail 'Install Git through setup-tools first.'
}
check_git_environment() {
    check_git_prerequisites
    validate_global_git_config
    git --version >/dev/null || fail 'Install Git through setup-tools first.'
}
validate_global_git_config() {
    if [[ -e $HOME/.gitconfig || -L $HOME/.gitconfig || -e ${XDG_CONFIG_HOME:-$HOME/.config}/git/config || -L ${XDG_CONFIG_HOME:-$HOME/.config}/git/config ]]; then
        git config --global --includes --list >/dev/null || fail 'Invalid global Git configuration.'
    fi
}
file_mode() {
    if stat -f '%Lp' "$1" >/dev/null 2>&1; then stat -f '%Lp' "$1"; else stat -c '%a' "$1"; fi
}
