# Add Homebrew without taking precedence over an existing provider on PATH.
__workstation_brew=$(command -v brew 2>/dev/null) || __workstation_brew=''
if [[ -z $__workstation_brew ]]; then
    for __workstation_candidate in /home/linuxbrew/.linuxbrew/bin/brew /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [[ -x $__workstation_candidate ]]; then __workstation_brew=$__workstation_candidate; break; fi
    done
fi
if [[ -n $__workstation_brew ]]; then
    export HOMEBREW_PREFIX=${__workstation_brew%/bin/brew}
    for __workstation_directory in "$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin"; do
        case :$PATH: in *:"$__workstation_directory":*) ;; *) PATH="$PATH:$__workstation_directory" ;; esac
    done
    export PATH
fi
unset __workstation_brew __workstation_candidate __workstation_directory
