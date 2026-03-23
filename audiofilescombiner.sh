#!/bin/bash

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
echo ";FFMETADATA1" > "$META_FILE"
echo "title=$TITLE_INPUT" >> "$META_FILE"
echo "album=$ALBUM_NAME" >> "$META_FILE"
echo "artist=$AUTHOR_NAME" >> "$META_FILE"
# Adding Genre for better Apple Books sorting
echo "genre=Audiobook" >> "$META_FILE"

CURRENT_TIME=0
for f in $(ls *.[mM][pP]3 | sort -V); do
    echo "file '$f'" >> "$LIST_FILE"
    
    DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$f")
    
    START_MS=$(echo "($CURRENT_TIME * 1000) / 1" | bc)
    END_TIME=$(echo "$CURRENT_TIME + $DURATION" | bc)
    END_MS=$(echo "($END_TIME * 1000) / 1" | bc)
    
    # Format chapter title nicely (no underscores)
    CHAP_TITLE=$(basename "$f" .mp3 | tr '_' ' ')
    echo "[CHAPTER]" >> "$META_FILE"
    echo "TIMEBASE=1/1000" >> "$META_FILE"
    echo "START=$START_MS" >> "$META_FILE"
    echo "END=$END_MS" >> "$META_FILE"
    echo "title=$CHAP_TITLE" >> "$META_FILE"
    
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
