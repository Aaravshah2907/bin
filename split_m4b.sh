#!/bin/bash

if [[ -z "$1" ]]; then
    echo "Usage: ./split_m4b.sh /path/to/file.m4b"
    exit 1
fi

INPUT_FILE=$(realpath "$1")
INPUT_DIR=$(dirname "$INPUT_FILE")
FILENAME_BASE=$(basename "${INPUT_FILE%.*}")

# 1. Extract chapter data
METADATA=$(ffprobe -i "$INPUT_FILE" -print_format json -show_chapters -loglevel error)
CHAPTER_COUNT=$(echo "$METADATA" | jq '.chapters | length')

if [[ "$CHAPTER_COUNT" -eq 0 ]]; then
    echo "No chapters found."
    exit 1
fi

# 2. Display Chapters to the user
echo "--- CHAPTER LIST ---"
echo "$METADATA" | jq -r '.chapters[] | "[\((.id + 1))] \(.tags.title // "Untitled Chapter")"'
echo "--------------------"

# 3. Get user selection
echo "Enter the chapter ranges you want to group (e.g., '1-3 4-4 5-10'):"
read -r USER_RANGES

# 4. Process each range
PART_IDX=1
for RANGE in $USER_RANGES; do
    # Parse the range (e.g., 1-3 becomes START_ID=1 and END_ID=3)
    START_ID=$(echo "$RANGE" | cut -d'-' -f1)
    END_ID=$(echo "$RANGE" | cut -d'-' -f2)

    # Convert to 0-based index for jq
    START_IDX=$((START_ID - 1))
    END_IDX=$((END_ID - 1))

    # Fetch timestamps
    START_TIME=$(echo "$METADATA" | jq -r ".chapters[$START_IDX].start_time")
    END_TIME=$(echo "$METADATA" | jq -r ".chapters[$END_IDX].end_time")

    # Safety check for invalid input
    if [[ "$START_TIME" == "null" || "$END_TIME" == "null" ]]; then
        echo "Skipping invalid range: $RANGE"
        continue
    fi

    PART_NUM=$(printf "P%02d" $PART_IDX)
    OUTPUT_PATH="${INPUT_DIR}/${FILENAME_BASE}_${PART_NUM}.mp3"

    echo "Exporting Range [$RANGE] to: $(basename "$OUTPUT_PATH")"

    ffmpeg -i "$INPUT_FILE" -ss "$START_TIME" -to "$END_TIME" -vn -c:a libmp3lame -q:a 2 "$OUTPUT_PATH" -loglevel error

    ((PART_IDX++))
done

echo "Done! Files are in $INPUT_DIR"
