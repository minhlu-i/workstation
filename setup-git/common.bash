# Shared setup-git paths and deterministic SSH configuration.
fail() { printf 'setup-git: %s\n' "$*" >&2; exit 1; }
check_environment() {
    [[ ${HOME-} == /* && $HOME != *$'\n'* && $HOME != *'"'* && $HOME != *'$'* && $HOME != *'%'* && $HOME != *'\'* ]] || fail 'HOME must be an absolute literal path without SSH expansion characters.'
    [[ ${XDG_CONFIG_HOME:-$HOME/.config} == "$HOME/.config" ]] || fail 'XDG_CONFIG_HOME must be ~/.config.'
    [[ -z ${GIT_CONFIG_GLOBAL-} && -z ${GIT_CONFIG_SYSTEM-} && -z ${GIT_CONFIG_COUNT-} && -z ${GIT_CONFIG_PARAMETERS-} ]] || fail 'Unset Git config overrides before setup/verification.'
    command -v git >/dev/null && git --version >/dev/null || fail 'Install Git through setup-tools first.'
    command -v ssh >/dev/null && command -v ssh-keygen >/dev/null || fail 'OpenSSH client is required.'
}
select_agent() {
    agent=${WORKSTATION_SSH_AGENT_SOCKET-}
    if [[ -z $agent ]]; then
        if [[ -S $HOME/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock ]]; then
            agent=$HOME/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock
        elif [[ -S $HOME/.var/app/com.bitwarden.desktop/data/.bitwarden-ssh-agent.sock ]]; then
            agent=$HOME/.var/app/com.bitwarden.desktop/data/.bitwarden-ssh-agent.sock
        elif [[ -S $HOME/snap/bitwarden/current/.bitwarden-ssh-agent.sock ]]; then
            agent=$HOME/snap/bitwarden/current/.bitwarden-ssh-agent.sock
        else
            agent=$HOME/.bitwarden-ssh-agent.sock
        fi
    fi
    [[ $agent == /* && $agent != *$'\n'* && $agent != *'"'* && $agent != *'$'* && $agent != *'%'* && $agent != *'\'* ]] || fail 'Agent socket must be an absolute literal path without SSH expansion characters.'
}
render_ssh() {
    local account alias
    for account in personal s5tech; do
        alias=gh-p; [[ $account != s5tech ]] || alias=gh-s5
        printf 'Host %s\n    HostName github.com\n    User git\n    IdentityAgent "%s"\n    IdentitiesOnly yes\n    IdentityFile "%s/.ssh/workstation/%s.pub"\n\n' "$alias" "$agent" "$HOME" "$account"
    done
    # Return Include parsing to global scope for the user's following config.
    printf 'Host *\n'
}
