#!/bin/bash

osascript <<'EOF'
tell application "System Events"
    key code 49 using {command down}
    delay 0.3
    key code 21 using {command down}
end tell
EOF
