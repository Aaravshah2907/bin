#!/bin/bash
# --- HELP UTILITY START ---
show_help() {
    cat << HELP_EOF
Usage: ${0##*/} [FILE...]

Description:
    Splitting MP3 files based on timestamps.

Options:
    -h, --help    Display this help message and exit.

HELP_EOF
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi
# --- HELP UTILITY END ---

# Dependency Check
if ! command -v ffmpeg &> /dev/null || ! command -v ffprobe &> /dev/null; then
    echo "Error: ffmpeg/ffprobe is required. Please install them."
    exit 1
fi

INPUT="$1"
shift 
TIMESTAMPS=("$@")

if [[ -z "$INPUT" || ${#TIMESTAMPS[@]} -eq 0 ]]; then
    echo "Usage: ./mp3_time_splitter.sh <file.mp3> <time1> <time2> ..."
    exit 1
fi

# 1. Extract existing metadata
TOTAL_DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT")
ORIG_TITLE=$(ffprobe -v error -show_entries format_tags=title -of default=noprint_wrappers=1:nokey=1 "$INPUT")
ORIG_ALBUM=$(ffprobe -v error -show_entries format_tags=album -of default=noprint_wrappers=1:nokey=1 "$INPUT")
ORIG_ARTIST=$(ffprobe -v error -show_entries format_tags=artist -of default=noprint_wrappers=1:nokey=1 "$INPUT")

# 2. Check for missing metadata and prompt user if necessary
if [ -z "$ORIG_TITLE" ]; then
    read -p "Title metadata missing. Enter Title (or press Enter to use filename): " ORIG_TITLE
    [ -z "$ORIG_TITLE" ] && ORIG_TITLE="${INPUT%.*}"
fi

if [ -z "$ORIG_ALBUM" ]; then
    read -p "Album metadata missing. Enter Album name: " ORIG_ALBUM
fi

if [ -z "$ORIG_ARTIST" ]; then
    read -p "Author (Artist) metadata missing. Enter Author name: " ORIG_ARTIST
fi

# 3. Prepare split points
POINTS=("0" "${TIMESTAMPS[@]}" "$TOTAL_DURATION")
NUM_PARTS=$((${#POINTS[@]} - 1))
EXTENSION="${INPUT##*.}"
BASENAME="${INPUT%.*}"

echo "---"
echo "Processing: $INPUT"
echo "Target Title: $ORIG_TITLE"
echo "Target Album: $ORIG_ALBUM"
echo "Target Author: $ORIG_ARTIST"
echo "---"

# 4. Perform the split
for (( i=0; i<$NUM_PARTS; i++ ))
do
    START="${POINTS[$i]}"
    END="${POINTS[$((i+1))]}"
    PART_NUM=$((i + 1))
    
    # Format part number with leading zero if total parts > 9
    printf -v PAD_PART "%02d" $PART_NUM
    
    OUT_FILE="${BASENAME}_Part${PAD_PART}.${EXTENSION}"
    NEW_TITLE="${ORIG_TITLE} Part ${PART_NUM}"

    echo "Creating Part $PART_NUM: [$START to $END] -> $OUT_FILE"

    # -map_metadata 0: Copies all global metadata (including cover art)
    # -metadata: Overwrites specific tags
    ffmpeg -v quiet -stats -i "$INPUT" -ss "$START" -to "$END" \
           -map_metadata 0 \
           -metadata title="$NEW_TITLE" \
           -metadata album="$ORIG_ALBUM" \
           -metadata artist="$ORIG_ARTIST" \
           -c copy "$OUT_FILE"
done

echo "Done! All segments have been exported with updated metadata."
