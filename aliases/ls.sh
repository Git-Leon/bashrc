{ # linux and cygwin environment
    ls -F --color=auto --show-control-chars 2>/dev/null $*
} || { # mac and unix environment
    ls -F -G 2>/dev/null $*
}