#!/bin/bash
TARGET="$1"

# Get the currently selected file path from Finder using AppleScript
FILE_PATH=$(osascript -e 'tell application "Finder" to get POSIX path of (target of front window as alias)' 2>/dev/null)

if [ -z "$FILE_PATH" ]; then
    # Fallback to checking standard selection if front window target fails
    FILE_PATH=$(osascript -e 'tell application "Finder" to get POSIX path of (selection as alias)' 2>/dev/null)
fi

if [ -z "$FILE_PATH" ]; then
    osascript -e 'display notification "No file selected in Finder" with title "Share Error"'
    exit 1
fi

case "$TARGET" in
    localsend)
        # Write to the temp file that the dashboard expects
        echo "$FILE_PATH" > "/tmp/yazi-localsend-files.txt"
        
        # Open a new terminal window specifically for the interactive dashboard
        osascript -e 'tell application "Terminal" to do script "~/.local/bin/localsend-dashboard.sh send; exit"' -e 'tell application "Terminal" to activate'
        ;;
    neardrop)
        open -a NearDrop "$FILE_PATH"
        ;;
    airdrop)
        osascript -e "set fileAlias to POSIX file \"$FILE_PATH\" as alias" -e 'tell application "Finder" to reveal fileAlias' -e 'tell application "System Events" to keystroke "R" using {command down, shift down}'
        ;;
    *)
        echo "Unknown target: $TARGET"
        exit 1
        ;;
esac
