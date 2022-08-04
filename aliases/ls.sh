{ # try
    ls -F --color=auto --show-control-chars 2>/dev/null
} || { #catch
    ls -F -G 2>/dev/null
}