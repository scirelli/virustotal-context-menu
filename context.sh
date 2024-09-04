#!/usr/bin/env bash

appName='QuickScan'
icon='dialog-information'
titlePre='Virustotal Scan'
files=("$@")

if [ -z "${VIRUSTOTAL_API_KEY-}" ]; then
    >&2 echo 'No API set'
    exit 1
fi

for file in "${files[@]}"; do
    fileName=$(basename -- "$file")
    results=$(/media/scirelli/Chromebook/scirelli/Projects/scirelli/virustotal-context-menu/test.sh "$file")
    title="$titlePre of $fileName"

    # notify-send \
    #     --app-name="$appName" \
    #     --category='transfer.complete' \
    #     --icon=dialog-information \
    #     "$title" "$results"

    # dbus-send will not work since it can't send variant types
    # Usage: dbus-send [--help] [--system | --session | --bus=ADDRESS | --peer=ADDRESS] [--dest=NAME] [--type=TYPE] [--print-reply[=literal]] [--reply-timeout=MSEC] <destination object path> <message name> [contents ...]

    gdbus call --session \
        --dest=org.freedesktop.Notifications \
        --object-path=/org/freedesktop/Notifications \
        --method=org.freedesktop.Notifications.Notify \
        "$appName" 0 "$icon" "$title" "$results" \
        '[]' '{"urgency": <1>}' 0
done
