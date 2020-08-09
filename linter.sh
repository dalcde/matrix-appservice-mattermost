#!/bin/sh

set +e

forbid() {
    # grep returns 1 if there is no match, 0 otherwise
    grep --color=always -n -E -r $1 src
    if [[ $? -eq 0 ]]; then
        exit 1
    fi
}
forbid '!=([^=]|$)'
forbid '[^!=]==([^=]|$)'
forbid '^\s*var'
