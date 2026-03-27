#!/bin/bash

# --- 0. Handle Help Flag ---
if [[ "$1" == "-h" ]]; then
    echo "Usage: $0 /path/to/folder"
    exit 0
fi

# --- 1. SETUP & INPUTS ---
if [ -z "$1" ]; then
    echo "Usage: $0 /path/to/folder"
    exit 1
fi

TARGET_DIR=$(realpath "$1")
cd "$TARGET_DIR" || exit 1

echo "--- Audiobook Metadata ---"
read -p "Enter Audiobook Title: " TITLE_INPUT
read -p "Enter Album Name: " ALBUM_NAME
read -p "Enter Author (Artist): " AUTHOR_NAME
echo "--------------------------"

OUTPUT="combined_audiobook.m4b"
LIST_FILE="list.txt"
META_FILE="metadata.txt"

echo "🚀 Starting process in: $TARGET_DIR"

# --- 2. FILENAME SANITIZATION ---
for f in *.[mM][pP]3; do
    [ -e "$f" ] || continue
    clean_name=$(echo "$f" | sed "s/['()\[\]]//g" | tr ' ' '_')
    if [ "$f" != "$clean_name" ]; then
        mv "$f" "$clean_name"
    fi
done

# --- 3. AUTO-DETECT IMAGE ---
COVER_IMAGE=$(ls | grep -Ei "\.(jpg|jpeg|png)$" | head -n 1)

# --- 4. GENERATE LIST AND CHAPTER METADATA ---
echo "📝 Calculating chapter timings..."
rm -f "$LIST_FILE" "$META_FILE"

# Create metadata header
cat <<EOF > "$META_FILE"
;FFMETADATA1
title=$TITLE_INPUT
album=$ALBUM_NAME
artist=$AUTHOR_NAME
genre=Audiobook
EOF

# Use a standard Bash glob. 
# We nullglob manually to avoid the loop running on a literal "*.mp3" string
shopt -s nullglob
files=( *.[mM][pP]3 )
shopt -u nullglob

if [ ${#files[@]} -eq 0 ]; then
    echo "❌ No MP3 files found in $TARGET_DIR"
    exit 1
fi

CURRENT_TIME=0

# Sort the array numerically/version-style
# We pipe the null-terminated list to sort -z to handle spaces/special chars
IFS=$'\n' sorted_files=($(printf "%s\n" "${files[@]}" | sort -V))
unset IFS

for f in "${sorted_files[@]}"; do
    # Escape single quotes for ffmpeg's concat list.txt
    # Example: Shallan's Theme -> Shallan'\''s Theme
    escaped_f=$(echo "$f" | sed "s/'/'\\\\''/g")
    echo "file '$escaped_f'" >> "$LIST_FILE"
    
    # Get duration - quotes around "$f" are critical for those pipes | and spaces
    DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$f")
    
    START_MS=$(echo "($CURRENT_TIME * 1000) / 1" | bc)
    END_TIME=$(echo "$CURRENT_TIME + $DURATION" | bc)
    END_MS=$(echo "($END_TIME * 1000) / 1" | bc)
    
    # Chapter title: remove extension and swap underscores for spaces
    CHAP_TITLE=$(basename "$f" | sed 's/\.[^.]*$//' | tr '_' ' ')
    
    cat <<EOF >> "$META_FILE"
[CHAPTER]
TIMEBASE=1/1000
START=$START_MS
END=$END_MS
title=$CHAP_TITLE
EOF
    
    CURRENT_TIME=$END_TIME
done

# --- 5. EXECUTE FFMPEG ---
echo "🏗️  Encoding to M4B (AAC)..."

if [ -n "$COVER_IMAGE" ]; then
    # -map 0:a and -map 1:v ensures we only take audio and the image, ignoring bad data streams
    ffmpeg -f concat -safe 0 -i "$LIST_FILE" -i "$COVER_IMAGE" -i "$META_FILE" \
        -map 0:a -map 1:v -map_metadata 2 \
        -c:a aac -b:a 128k -af "aresample=async=1" \
        -c:v copy -disposition:v:0 attached_pic \
        -stats -y "$OUTPUT"
else
    ffmpeg -f concat -safe 0 -i "$LIST_FILE" -i "$META_FILE" \
        -map 0:a -map_metadata 1 \
        -c:a aac -b:a 128k -af "aresample=async=1" \
        -stats -y "$OUTPUT"
fi

rm "$LIST_FILE" "$META_FILE"
echo "------------------------------------------------"
echo "✅ SUCCESS! Created: $OUTPUT"
echo "Title:  $TITLE_INPUT"
echo "Album:  $ALBUM_NAME"
echo "Author: $AUTHOR_NAME"
echo "------------------------------------------------"
