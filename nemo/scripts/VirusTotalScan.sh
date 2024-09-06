#!/usr/bin/env bash
{
    files=("$@")
    scriptDir="$(dirname "$(readlink "$0")")"
    export VIRUSTOTAL_API_KEY
    read -r VIRUSTOTAL_API_KEY < "$HOME"/.vtapikey
    cd "$scriptDir/../../" || exit 1
    echo 'Starting scan...'
    ./context.sh "${files[@]}"
} 1>>/tmp/nemo_virustotal_scan.log 2>&1
