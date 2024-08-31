#!/usr/bin/env bash
(return 0 2>/dev/null) && sourced=1 || sourced=0
set -o errexit
set -o nounset
set -o pipefail

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
if [ "$(tput colors)" -lt 16 ]; then
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

        if [ "$sourced" -eq "1" ]; then
            return "$code"
        else
            exit "$code"
        fi
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

    if boolTest "${HAM_DEBUG_SHELL:-0}";then
        >&2 info "Entering debug shell"
        bash
    fi

    _cleanup "$1"
    if [ "$sourced" -eq "1" ]; then
        return "$1"
    else
        exit "$1"
    fi
}

_fail() {
    _errexit 1 "${BASH_SOURCE[1]}" "${BASH_LINENO[0]}" "$*"
}

err() {
    HAM_DEBUG=
    _errexit 1 "${BASH_SOURCE[1]}" "${BASH_LINENO[0]}" "$*"
}

warn() {
    >&2 printf "${ANSI_YELLOW}WARNING${ANSI_RESET}: %s %s\n" "$*"
}

info() {
    >&2 printf "${ANSI_GREEN}INFO${ANSI_RESET}: %s %s\n" "$*"
}

debug() {
    if boolTest "${HAM_DEBUG:-}"; then
        >&2 printf "${ANSI_RED}DEBUG${ANSI_RESET}: %s\n" "$*"
    fi
}
########################################################################

DELAY_SEC=5
FILE="$1"

sha1sumFile() {
    sha1sum "$FILE" | cut -d' ' -f1
}

checkTheHash() {
    local fileHash
    local result
    fileHash="$(sha1sumFile)"
    result=$(curl --request GET \
        --silent \
        --url "https://www.virustotal.com/api/v3/files/${fileHash}" \
        --header "X-Apikey: ${VIRUSTOTAL_API_KEY}" \
        --header 'accept: application/json' \
    | \
    jq -r '.data.attributes.stats')

    if [ "$result" = 'null' ] || [ -z "$result" ]; then
        return 1
    else
        echo "$result"
    fi
}

getFileUploadURL() {
    local result
    result=$(curl --request GET \
        --silent \
        --url https://www.virustotal.com/api/v3/files/upload_url \
        --header "X-Apikey: ${VIRUSTOTAL_API_KEY}" \
        --header 'accept: application/json' \
    | \
    jq -r '.data')

    if [ "$result" = 'null' ] || [ -z "$result" ]; then
        echo ''
        return 1
    else
        echo "$result"
    fi
}

if [ -z "${VIRUSTOTAL_API_KEY-}" ]; then
    err 'No API set'
fi

if h=$(checkTheHash); then
    exit 0
fi
info "h='$h' $(sha1sumFile)"

uploadUrl=$(getFileUploadURL)
if [ "$uploadUrl" = 'null' ] || [ -z "$uploadUrl" ]; then
    err 'Not able to get an upload url.'
fi
analysesData=$(curl --request POST \
    --silent \
    --url "$uploadUrl" \
    --header "X-Apikey: ${VIRUSTOTAL_API_KEY}" \
    --header 'accept: application/json' \
    --header 'content-type: multipart/form-data' \
    --form "file=@${FILE}")

queued=true
while [ "$queued" = true ]; do
    if [ -z "$analysesData" ]; then
        err 'Failed to scan file'
    fi
    resultStatus=$(jq -r '.data.attributes.status' <<< "$analysesData")
    link=$(jq -r '.data.links.self' <<< "$analysesData")
    #item=$(jq -r '.data.links.item' <<< "$analysesData")

    # if [ "$item" != 'null' ] && [ -n "$item" ]; then
    #     info 'Item'
    #     curl --request GET \
    #         --url "$item" \
    #         --header "X-Apikey: ${VIRUSTOTAL_API_KEY}" \
    #         --header 'accept: application/json'
    #     exit 0
    # fi

    if [ "$resultStatus" = 'null' ] || [ "$resultStatus" = 'queued' ] || [ -z "$resultStatus" ]; then
        info "$analysesData"
        info "$resultStatus"
        if [ -z "$link" ]; then
            err 'Response did not contain a analysis link'
        fi
        sleep "$DELAY_SEC"
        analysesData=$(curl --request GET \
            --silent \
            --url "$link" \
            --header "X-Apikey: ${VIRUSTOTAL_API_KEY}" \
            --header 'accept: application/json')
        continue
    fi
    queued=false
    jq '.data.attributes.stats' <<< "$analysesData"
done
