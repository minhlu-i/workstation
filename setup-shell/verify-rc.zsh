# Prove initialization preserves preexisting prompt hooks.
__workstation_verify_first() { __workstation_verify_first_ran=1; }
__workstation_verify_second() { __workstation_verify_second_ran=1; }
precmd_functions+=(__workstation_verify_first __workstation_verify_second)
source "$HOME/.zshrc"
