#!/usr/bin/env bash
notify-send \
    --app-name='QuickScan' \
    --category='transfer.complete' \
    'Virustotal' "$@ $(/media/scirelli/Chromebook/scirelli/Projects/scirelli/virustotal-context-menu/test.sh "$@")"
