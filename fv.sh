#!/bin/bash

osascript <<EOF
tell application "iTerm"
    activate

    if (count windows) = 0 then
        create window with default profile
    end if

    tell current session of current window
        write text "fv ~"
    end tell
end tell
EOF
