if ! declare -F _completion_loader >/dev/null; then
    for __workstation_completion in \
        /usr/share/bash-completion/bash_completion \
        /etc/bash_completion \
        "${HOMEBREW_PREFIX:-/opt/homebrew}/etc/profile.d/bash_completion.sh" \
        /usr/local/etc/profile.d/bash_completion.sh \
        /home/linuxbrew/.linuxbrew/etc/profile.d/bash_completion.sh; do
        if [[ -r $__workstation_completion ]]; then
            source "$__workstation_completion"
            break
        fi
    done
    unset __workstation_completion
fi
