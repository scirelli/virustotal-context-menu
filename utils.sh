#!/usr/bin/env bash

########################################################################
# ANSI escape sequences
#

ANSI_RESET="$(echo -e '\033[0m')"

# Standard ANSI colors
ANSI_RED="$(echo -e '\033[31m')"
ANSI_GREEN="$(echo -e '\033[32m')"
ANSI_YELLOW="$(echo -e '\033[33m')"

# ANSI bright colors using the bold attribute
# (sequences 90-97 are not part of the standard)

# Invalidate color codes if the terminal doesn't support them
if [ "$(2>/dev/null tput colors || echo '0')" -lt 16 ]; then
    for _color in ANSI_RED ANSI_GREEN ANSI_YELLOW ; do
        eval "${_color}=''"
    done
fi
readonly ANSI_RESET ANSI_RED ANSI_GREEN ANSI_YELLOW

########################################################################
# Error handling
#

# Define an empty _cleanup function if it is not already defined.
# This should be redefined in the script that sources this file.
if [ "$(type -t _cleanup)" != "function" ]; then
    _cleanup() {
        debug "Cleaning up... '$1'"
        code="$1"
        # Check error code for a successful exit
        if [ "$code" -ne 0 ]; then
            true # nothing for now
        fi

        exit "$code"
    }
fi

boolTest() {
    local _value
    [ "$#" -eq 1 ] || err 'boolTest() requires exactly one argument'
    _value="$*"
    _value="${_value,,}"      # Convert to lowercae
    _value="${_value##*( )}"  # Strip leading whitespace
    _value="${_value%%*( )}"  # Strip trailing whitespace
    case "$_value" in
        1 | true | yes | y | on)
            return 0
            ;;
        0 | false | no | n | off | '')
            return 1
            ;;
        *)
            warn "Invalid boolean value in boolTest(${1})"
            return 1
            ;;
    esac
}

_errexit() {
    set +o errexit
    set +o nounset
    set +o pipefail

    local _i

    >&2 printf "${ANSI_RED}ERROR${ANSI_RESET}: %s:%s: %s\n" "${2}" "${3}" "${4:-Uncaught exception}"

    if boolTest "${VT_DEBUG_SHELL:-0}";then
        >&2 info "Entering debug shell"
        bash
    fi

    _cleanup "$1"
    exit "$1"
}

_fail() {
    _errexit 1 "${BASH_SOURCE[1]}" "${BASH_LINENO[0]}" "$*"
}

err() {
    VT_DEBUG=
    _errexit 1 "${BASH_SOURCE[1]}" "${BASH_LINENO[0]}" "$*"
}

warn() {
    >&2 printf "${ANSI_YELLOW}WARNING${ANSI_RESET}: %s %s\n" "$*"
}

info() {
    >&2 printf "${ANSI_GREEN}INFO${ANSI_RESET}: %s %s\n" "$*"
}

debug() {
    if boolTest "${VT_DEBUG:-}"; then
        >&2 printf "${ANSI_RED}DEBUG${ANSI_RESET}: %s\n" "$*"
    fi
}
########################################################################
