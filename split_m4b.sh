#!/bin/bash

# Check if input file is provided
if [[ -z "$1" ]]; then
    echo "Usage: ./split_m4b.sh /path/to/file.m4b"
    exit 1
fi

# Get the absolute path and directory of the input file
INPUT_FILE=$(realpath "$1")
INPUT_DIR=$(dirname "$INPUT_FILE")
# Get filename without extension
FILENAME_BASE=$(basename "${INPUT_FILE%.*}")

echo "Processing file in: $INPUT_DIR"

# 1. Extract chapter data
METADATA=$(ffprobe -i "$INPUT_FILE" -print_format json -show_chapters -loglevel error)

# 2. Count total chapters
CHAPTER_COUNT=$(echo "$METADATA" | jq '.chapters | length')

if [[ "$CHAPTER_COUNT" -eq 0 ]]; then
    echo "No chapters found."
    exit 1
fi

# 3. Loop through chapters
for (( i=0; i<$CHAPTER_COUNT; i++ )); do
    START=$(echo "$METADATA" | jq -r ".chapters[$i].start_time")
    END=$(echo "$METADATA" | jq -r ".chapters[$i].end_time")
    
    # Format: P01, P02...
    PART_NUM=$(printf "P%02d" $((i + 1)))
    
    # Define output path in the same directory as input
    OUTPUT_PATH="${INPUT_DIR}/${FILENAME_BASE}${PART_NUM}.mp3"

    echo "Exporting to: $OUTPUT_PATH"

    ffmpeg -i "$INPUT_FILE" -ss "$START" -to "$END" -vn -c:a libmp3lame -q:a 2 "$OUTPUT_PATH" -loglevel error
done

echo "Done! Files are located in $INPUT_DIR"
