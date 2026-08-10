#!/bin/bash

MODE="$1"

if [ "$MODE" = "receive" ]; then
    mkdir -p ~/Documents/LocalSend
    echo "Waiting for incoming files..."
    echo "Files will be saved to: ~/Documents/LocalSend"
    echo "(Will auto-close after transfer completes, or press Ctrl+C to stop)"
    echo ""

    # Kill GUI if running to free port 53317
    GUI_WAS_RUNNING=0
    if pgrep -il "localsend" | grep -v "localsend-cli" > /dev/null; then
        GUI_WAS_RUNNING=1
        osascript -e 'quit app "LocalSend"' >/dev/null 2>&1
        pkill -ix "localsend" >/dev/null 2>&1
        sleep 1
    fi

    LOG="/tmp/localsend-receive.log"
    > "$LOG"

    # Run localsend-cli in background, output to log
    /usr/local/bin/localsend-cli receive -y --save-dir ~/Documents/LocalSend > "$LOG" 2>&1 &
    RECV_PID=$!

    # Display the log output in real time
    tail -f "$LOG" &
    TAIL_PID=$!

    # Clean up everything on exit (Ctrl+C or normal)
    trap 'kill $RECV_PID $TAIL_PID 2>/dev/null; wait $RECV_PID $TAIL_PID 2>/dev/null; rm -f "$LOG"; [ "$GUI_WAS_RUNNING" -eq 1 ] && open -j -a "LocalSend" >/dev/null 2>&1; exit 0' INT TERM

    # Watch the log for the completion message
    while kill -0 "$RECV_PID" 2>/dev/null; do
        if grep -q "file(s) received\|Address already in use" "$LOG" 2>/dev/null; then
            sleep 1
            break
        fi
        sleep 0.5
    done

    kill "$RECV_PID" 2>/dev/null
    kill "$TAIL_PID" 2>/dev/null
    wait "$RECV_PID" 2>/dev/null
    wait "$TAIL_PID" 2>/dev/null
    rm -f "$LOG"
    
    if [ "$GUI_WAS_RUNNING" -eq 1 ]; then
        open -j -a "LocalSend" >/dev/null 2>&1
    fi
    exit 0
fi

# --- Send mode ---
# Read file paths from temp file
FILELIST="/tmp/yazi-localsend-files.txt"
if [ ! -f "$FILELIST" ]; then
    echo "No files to send."
    sleep 1
    exit 1
fi

FILES=()
while IFS= read -r line; do
    [ -n "$line" ] && FILES+=("$line")
done < "$FILELIST"
rm -f "$FILELIST"

if [ ${#FILES[@]} -eq 0 ]; then
    echo "No files to send."
    sleep 1
    exit 1
fi

# Prepare: zip any directories
SEND_FILES=()
TEMP_ZIPS=()
for f in "${FILES[@]}"; do
    if [ -d "$f" ]; then
        DIR_NAME=$(basename "$f")
        ZIP_PATH="/tmp/${DIR_NAME}.zip"
        echo "Zipping folder: $DIR_NAME"
        (cd "$(dirname "$f")" && zip -rq "$ZIP_PATH" "$DIR_NAME")
        SEND_FILES+=("$ZIP_PATH")
        TEMP_ZIPS+=("$ZIP_PATH")
    elif [ -f "$f" ]; then
        SEND_FILES+=("$f")
    fi
done

echo ""
echo "Sending:"
for f in "${SEND_FILES[@]}"; do
    echo "  $(basename "$f")"
done

# Discover devices
echo ""
echo "Discovering devices (please wait)..."
DEVICES_RAW=$(/usr/local/bin/localsend-cli discover -t 8 --json 2>/dev/null)
DEVICES_JSON=$(echo "$DEVICES_RAW" | sed -n '/^\[/,/^\]/p')

if [ -z "$DEVICES_JSON" ] || [ "$DEVICES_JSON" = "[]" ]; then
    echo ""
    echo "No devices found. Make sure LocalSend is open on the target device."
    sleep 2
    [ ${#TEMP_ZIPS[@]} -gt 0 ] && rm -f "${TEMP_ZIPS[@]}"
    exit 1
fi

# Parse device names
ALIASES=()
while IFS= read -r alias; do
    ALIASES+=("$alias")
done < <(echo "$DEVICES_JSON" | python3 -c "import sys,json; [print(d.get('alias','Unknown')) for d in json.load(sys.stdin)]" 2>/dev/null)

if [ ${#ALIASES[@]} -eq 0 ]; then
    echo "Failed to parse devices."
    sleep 1
    [ ${#TEMP_ZIPS[@]} -gt 0 ] && rm -f "${TEMP_ZIPS[@]}"
    exit 1
fi

# Show device menu
echo ""
echo "Select device:"
for i in "${!ALIASES[@]}"; do
    echo "  $((i+1))) ${ALIASES[$i]}"
done
echo ""
read -p "Device [1]: " CHOICE
CHOICE=${CHOICE:-1}

IDX=$((CHOICE - 1))
if [ "$IDX" -lt 0 ] || [ "$IDX" -ge "${#ALIASES[@]}" ]; then
    echo "Invalid choice."
    sleep 1
    [ ${#TEMP_ZIPS[@]} -gt 0 ] && rm -f "${TEMP_ZIPS[@]}"
    exit 1
fi

TARGET="${ALIASES[$IDX]}"
echo ""
echo "Sending to ${TARGET}..."
/usr/local/bin/localsend-cli send --to "$TARGET" "${SEND_FILES[@]}"

# Cleanup temp zips
[ ${#TEMP_ZIPS[@]} -gt 0 ] && rm -f "${TEMP_ZIPS[@]}"

