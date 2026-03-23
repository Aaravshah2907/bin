#!/bin/bash

# --- 1. SETUP ---
if [ -z "$1" ]; then
    echo "Usage: $0 /path/to/folder"
    exit 1
fi

TARGET_DIR=$(realpath "$1")
cd "$TARGET_DIR" || exit 1
OUTPUT="combined_audiobook.mp3"
LIST_FILE="list.txt"

echo "🚀 Starting process in: $TARGET_DIR"

# --- 2. FILENAME SANITIZATION ---
echo "🧹 Cleaning filenames..."
for f in *.[mM][pP]3; do
    [ -e "$f" ] || continue
    # Removes ', (, ), [, ], and spaces to make FFmpeg processing bulletproof
    clean_name=$(echo "$f" | sed "s/['()\[\]]//g" | tr ' ' '_')
    if [ "$f" != "$clean_name" ]; then
        mv "$f" "$clean_name"
        echo "   Renamed: $f -> $clean_name"
    fi
done

# --- 3. AUTO-DETECT ANY IMAGE ---
# Finds the first jpg, jpeg, or png to use as cover art
COVER_IMAGE=$(ls | grep -Ei "\.(jpg|jpeg|png)$" | head -n 1)

if [ -n "$COVER_IMAGE" ]; then
    echo "🖼️  Detected cover art: $COVER_IMAGE"
else
    echo "⚠️  No image found in folder. Proceeding with audio only."
fi

# --- 4. CREATE CONCAT LIST ---
rm -f "$LIST_FILE"
# We use the cleaned names here
for f in *.[mM][pP]3; do
    echo "file '$f'" >> "$LIST_FILE"
done

# --- 5. DYNAMIC FFMPEG COMMAND ---
if [ -f "$LIST_FILE" ]; then
    echo "🏗️  Merging and attaching metadata..."

    if [ -n "$COVER_IMAGE" ]; then
        # Map 0 is the audio list, Map 1 is the detected image
        ffmpeg -f concat -safe 0 -i "$LIST_FILE" -i "$COVER_IMAGE" \
            -map 0:0 -map 1:0 \
            -c copy \
            -id3v2_version 3 \
            -metadata:s:v title="Album cover" \
            -metadata:s:v comment="Cover (front)" \
            -fflags +genpts -y -loglevel error "$OUTPUT"
    else
        ffmpeg -f concat -safe 0 -i "$LIST_FILE" -c copy -fflags +genpts -y -loglevel error "$OUTPUT"
    fi

    rm "$LIST_FILE"
    echo "------------------------------------------------"
    echo "✅ SUCCESS! Created: $OUTPUT"
    
    # --- 6. VERIFICATION ---
    echo -n "Final Duration: "
    ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 -sexagesimal "$OUTPUT"
    echo "------------------------------------------------"
else
    echo "❌ Error: No MP3 files found."
fi
