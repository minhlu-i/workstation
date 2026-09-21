shopt -s checkwinsize
__workstation_dedupe_path() {
    local remaining=$PATH entry result='' separator='' last=0
    local -A seen=()
    while (( ! last )); do
        if [[ $remaining == *:* ]]; then
            entry=${remaining%%:*}; remaining=${remaining#*:}
        else
            entry=$remaining; last=1
        fi
        # Prefix keys so an empty PATH element remains valid (current directory).
        if [[ ! ${seen["x$entry"]+present} ]]; then
            seen["x$entry"]=1
            result+="$separator$entry"; separator=:
        fi
    done
    export PATH=$result
}
export PATH="$HOME/.local/bin:$PATH"
__workstation_dedupe_path
if command -v lesspipe >/dev/null 2>&1; then
    eval "$(SHELL=/bin/sh lesspipe)"
fi
