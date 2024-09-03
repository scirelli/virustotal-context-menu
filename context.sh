#!/usr/bin/env bash

appName='QuickScan'
title='Virustotal Scan'
files=("$@")

if [ -z "${VIRUSTOTAL_API_KEY-}" ]; then
    >&2 echo 'No API set'
    exit 1
fi

for file in "${files[@]}"; do
    fileName=$(basename -- "$file")
    results=$(/media/scirelli/Chromebook/scirelli/Projects/scirelli/virustotal-context-menu/test.sh "$file")

    notify-send \
        --app-name="$appName" \
        --category='transfer.complete' \
        --icon=dialog-information \
        "$title of $fileName" "$results"
done
