set -e
set -o history
HISTFILE=/dev/null
# Real mise-managed replacement executables, supplied by test-module.
PATH="$HOME/bin:/usr/bin:/bin"
PROMPT_COMMAND=$'printf ""\n:'
original=$PROMPT_COMMAND
history -s 'ls previous-session'

source "$MODULE/files/rc.d/90-modern-cli-hints.bash"
__workstation_hint 2> "$HOME/first-prompt-output"
[[ ! -s "$HOME/first-prompt-output" ]]
[[ ${PROMPT_COMMAND[0]} == "$original" && ${PROMPT_COMMAND[1]} == __workstation_hint ]]
source "$MODULE/files/rc.d/90-modern-cli-hints.bash"
[[ ${#PROMPT_COMMAND[@]} == 2 ]]
assert_hint() {
    local command=$1 expected=$2 output
    history -s "$command"
    # Avoid subshell: once-per-session state must survive each invocation.
    __workstation_hint 2> "$HOME/hint-output"
    output=$(cat "$HOME/hint-output")
    [[ $output == "$expected" ]] || { printf 'Hint mismatch for %s: %s\n' "$command" "$output" >&2; exit 1; }
}
assert_hint 'ls -la' 'hint: try eza as an alternative to ls; see eza --help for its syntax.'
assert_hint 'ls /tmp' ''
assert_hint 'grep pattern file' ''
assert_hint 'grep -e -r file' ''
assert_hint 'grep -- -r file' ''
assert_hint 'grep -eR file' ''
assert_hint 'grep -nR pattern .' 'hint: try rg as an alternative to grep; see rg --help for its syntax.'
assert_hint 'grep -r other .' ''
assert_hint 'cat /etc/hostname' 'hint: try bat as an alternative to cat; see bat --help for its syntax.'
assert_hint 'find .' 'hint: try fd as an alternative to find; see fd --help for its syntax.'
assert_hint 'man bash' 'hint: try tldr as an alternative to man; see tldr --help for its syntax.'
# No replacement means no hint and no consumed once-per-session state.
unset '__workstation_hints_seen[ls]'
PATH=/usr/bin:/bin
assert_hint 'ls missing-replacement' ''
[[ ! ${__workstation_hints_seen[ls]+seen} ]]
# The hook returns the incoming command status.
set +e
false
__workstation_hint 2>/dev/null
status=$?
set -e
[[ $status == 1 ]]
for command in ls cat find man grep; do
    [[ $(type -t "$command") != function && $(type -t "$command") != alias ]]
done
PROMPT_COMMAND=(':' 'printf ""')
source "$MODULE/files/rc.d/90-modern-cli-hints.bash"
[[ ${#PROMPT_COMMAND[@]} == 3 && ${PROMPT_COMMAND[0]} == : && ${PROMPT_COMMAND[1]} == 'printf ""' ]]
