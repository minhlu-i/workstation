# Managed by setup-shell. Personal changes belong in ~/.config/bash/local.bash.
[[ $- == *i* ]] || return
# Keep the account's login shell unchanged. Older distro Bash hands interactive
# editing to an already-installed Bash 5.3+, without touching /bin/bash or profiles.
if (( BASH_VERSINFO[0] < 5 || (BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] < 3) )); then
    for __workstation_bash in "${HOMEBREW_PREFIX:-/home/linuxbrew/.linuxbrew}/bin/bash" /opt/homebrew/bin/bash /usr/local/bin/bash; do
        if [[ -x $__workstation_bash ]] && "$__workstation_bash" --noprofile --norc -c '(( BASH_VERSINFO[0] > 5 || (BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] >= 3) ))'; then
            # Never discard the command body of an explicit bash -ic invocation.
            if [[ ! ${BASH_EXECUTION_STRING+x} ]]; then
                exec "$__workstation_bash" --noprofile --rcfile "$HOME/.bashrc" -i
            fi
            break
        fi
    done
    unset __workstation_bash
fi
source "$HOME/.config/bash/bashrc"
