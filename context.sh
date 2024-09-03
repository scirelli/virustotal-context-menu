#!/usr/bin/env bash

appName='QuickScan'
title='Virustotal Scan'
files=("$@")

for file in "${files[@]}"; do
    fileName=$(basename -- "$file")
    results=$(/media/scirelli/Chromebook/scirelli/Projects/scirelli/virustotal-context-menu/test.sh "$file")

    notify-send \
        --app-name="$appName" \
        --category='transfer.complete' \
        --icon=dialog-information \
        "$title of $fileName" "$results"
done
