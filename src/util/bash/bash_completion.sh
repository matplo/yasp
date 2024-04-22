#!/bin/bash

_yasp_bash_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts=$(yasp -h)
    if [[ ${cur} == -* ]] ; then
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    fi
    cmnds=$(yasp -l | sed 's| ||g')
    if [[ ${cur} == * ]] ; then
        COMPREPLY=( $(compgen -W "${cmnds}" -- ${cur}) )
        return 0
    fi
}
complete -F _yasp_bash_completion yasp