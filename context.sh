#!/usr/bin/env bash

appName='QuickScan'
icon='dialog-information'
titlePre='Virustotal Scan'
files=("$@")
scriptDir="$(dirname "$0")"

if [ -z "${VIRUSTOTAL_API_KEY-}" ]; then
    >&2 echo 'No API set'
    exit 1
fi

for file in "${files[@]}"; do
    fileName=$(basename -- "$file")
    title="$titlePre of '$fileName'"
    if results=$("$scriptDir"/scan "$file"); then
        gdbus call --session \
            --dest=org.freedesktop.Notifications \
            --object-path=/org/freedesktop/Notifications \
            --method=org.freedesktop.Notifications.Notify \
            "$appName" 0 "$icon" "$title" "$results" \
            '[]' '{"urgency": <1>}' 0
    else
        gdbus call --session \
            --dest=org.freedesktop.Notifications \
            --object-path=/org/freedesktop/Notifications \
            --method=org.freedesktop.Notifications.Notify \
            "$appName" 0 "$icon" "$title" 'Failed scan' \
            '[]' '{"urgency": <1>}' 0
    fi
done

    # notify-send \
    #     --app-name="$appName" \
    #     --category='transfer.complete' \
    #     --icon=dialog-information \
    #     "$title" "$results"

    # dbus-send will not work since it can't send variant types
    # Usage: dbus-send [--help] [--system | --session | --bus=ADDRESS | --peer=ADDRESS] [--dest=NAME] [--type=TYPE] [--print-reply[=literal]] [--reply-timeout=MSEC] <destination object path> <message name> [contents ...]
