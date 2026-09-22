#!/usr/bin/env bash
set -euo pipefail
module=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
fail() { printf 'setup-shell: %s\n' "$*" >&2; exit 1; }
operation=install
source "$module/options.bash"
source "$module/../setup-tools/dependencies.bash"
source "$module/../setup-tools/file-operations.bash"
load_tool_environment
export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_UPGRADE=1
if [[ $mode != --configure-only ]]; then
    bash "$module/../setup-tools/verify.sh" || fail "Missing prerequisites. Run: $module/../setup-tools/install.sh"
    case $(uname -s):$shell_name in
        Linux:bash|Darwin:zsh) ;;
        *) fail 'Full installation supports Bash on Ubuntu/WSL2 and Zsh on macOS; cross-shell configuration is offline-only.' ;;
    esac
fi
if [[ $shell_name == bash ]]; then
    interpreter=$(command -v bash)
    bash_capable() { "$1" --noprofile --norc -c '(( BASH_VERSINFO[0] > 5 || (BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] >= 3) ))'; }
    if ! bash_capable "$interpreter"; then
        # Search an already-installed newer Bash before asking brew to install one.
        for candidate in "${HOMEBREW_PREFIX:-/home/linuxbrew/.linuxbrew}/bin/bash" /opt/homebrew/bin/bash /usr/local/bin/bash; do
            if [[ -x $candidate ]] && bash_capable "$candidate"; then interpreter=$candidate; break; fi
        done
    fi
    if ! bash_capable "$interpreter"; then
        [[ $mode != --configure-only ]] || fail 'Bash 5.3+ required; configure-only will not install it.'
        "$BREW" list --versions bash >/dev/null 2>&1 && fail 'Existing brew Bash is too old; upgrade it explicitly, then rerun.'
        "$BREW" install bash
        interpreter=$("$BREW" --prefix bash)/bin/bash
        bash_capable "$interpreter" || fail 'Bash 5.3+ required.'
    fi
else
    interpreter=$(command -v zsh) || fail 'Zsh is required (macOS supplies /bin/zsh).'
    "$interpreter" -d -f -c 'autoload -Uz is-at-least; is-at-least 5.8' || fail 'Zsh 5.8+ required.'
    check_zsh_startup_path
fi
source_dir=$module/files/$shell_name
for file in "$source_dir/${shell_name}rc" "$source_dir/"*.$shell_name "$source_dir/rc.d/"*.$shell_name; do
    [[ -f $file ]] && "$interpreter" -n "$file"
done
for file in "$HOME/.config/$shell_name/local.$shell_name" "$HOME/.config/$shell_name/rc.d/"*.$shell_name; do
    [[ ! -e $file ]] || "$interpreter" -n "$file"
done
if [[ $mode != --configure-only ]]; then
    if [[ $shell_name == bash ]]; then
        # Test actual loading; distro completion is valid even when brew doesn't own it.
        if ! "$interpreter" --noprofile --norc -ic 'source "$1"; declare -F _completion_loader >/dev/null' _ "$source_dir/rc.d/50-completion.bash"; then
            "$BREW" list --versions bash-completion@2 >/dev/null 2>&1 && fail 'Installed brew completion cannot load; repair it before retrying.'
            "$BREW" install bash-completion@2
            "$interpreter" --noprofile --norc -ic 'source "$1"; declare -F _completion_loader >/dev/null' _ "$source_dir/rc.d/50-completion.bash" || fail 'bash-completion failed to load.'
        else
            printf 'REUSE bash-completion (runtime loader available)\n'
        fi
    else
        for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
            found=''
            for directory in /usr/share /usr/share/zsh/plugins "${HOMEBREW_PREFIX}/share" /opt/homebrew/share /usr/local/share /home/linuxbrew/.linuxbrew/share; do
                if [[ -r $directory/$plugin/$plugin.zsh ]]; then
                    "$interpreter" -d -f -n "$directory/$plugin/$plugin.zsh" || fail "Invalid plugin: $directory/$plugin/$plugin.zsh"
                    found=$directory/$plugin/$plugin.zsh; break
                fi
            done
            if [[ -n $found ]]; then printf 'REUSE %s: %s\n' "$plugin" "$found"; else
                "$BREW" list --versions "$plugin" >/dev/null 2>&1 && fail "Installed $plugin is not readable; repair it before retrying."
                "$BREW" install "$plugin"
            fi
        done
    fi
fi
source "$module/manifest.bash"
write_shell_manifest
write_owned "$source_dir/${shell_name}rc" "$HOME/.config/$shell_name/${shell_name}rc" ".config/$shell_name/${shell_name}rc"
for file in "$source_dir/rc.d/"*.$shell_name; do
    name=${file##*/}
    if [[ $name == 45-user-aliases.$shell_name ]]; then
        write_user "$file" "$HOME/.config/$shell_name/rc.d/$name"
    else
        write_owned "$file" "$HOME/.config/$shell_name/rc.d/$name" ".config/$shell_name/rc.d/$name"
    fi
done
write_user "$source_dir/local.$shell_name" "$HOME/.config/$shell_name/local.$shell_name"
if [[ $shell_name == zsh ]]; then
    write_owned "$source_dir/highlighting.zsh" "$HOME/.config/zsh/highlighting.zsh" .config/zsh/highlighting.zsh
fi
write_owned "$module/files/starship.toml" "$HOME/.config/starship.toml" .config/starship.toml
write_owned "$source_dir/bootstrap.$shell_name" "$HOME/.${shell_name}rc" ".${shell_name}rc"
if [[ $mode == --configure-only ]]; then
    printf '%s configuration generated; no dependencies installed.\n' "$shell_name"
else
    bash "$module/verify.sh" --shell "$shell_name"
    printf '%s setup complete. Open a new %s terminal.\n' "$shell_name" "$shell_name"
fi
