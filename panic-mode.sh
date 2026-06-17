#!/bin/bash

STATE="$HOME/.cache/panic"

mkdir -p "$HOME/.cache"

if [ -f "$STATE" ]
then

    while IFS= read -r app
    do

        open -a "$app" 2>/dev/null

    done < "$STATE"

    rm "$STATE"

else

    osascript <<EOF > "$STATE"
tell application "System Events"

set appNames to {}

repeat with proc in application processes

    if visible of proc is true then

        set appName to name of proc

        if appName is not "Finder" and appName is not "Dock" then

            copy appName to end of appNames

            set visible of proc to false

        end if

    end if

end repeat

return appNames

end tell
EOF

fi
