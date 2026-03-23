#!/bin/bash

# Check for required tools
if ! command -v ffmpeg &> /dev/null || ! command -v exiftool &> /dev/null; then
    echo "Error: This script requires both 'ffmpeg' and 'exiftool' to be installed."
    exit 1
fi

# Check if a directory was provided
if [ -z "$1" ]; then
    echo "Usage: ./resizeCoverArt.sh /path/to/mp3/directory"
    exit 1
fi

TARGET_DIR="$1"
TEMP_DIR=$(mktemp -d)

find "$TARGET_DIR" -type f -iname "*.mp3" | while read -r file; do
    echo "Processing: $file"

    # 1. Extract the current cover art
    ffmpeg -y -i "$file" -an -vcodec copy "$TEMP_DIR/cover.jpg" -loglevel error

    if [ -f "$TEMP_DIR/cover.jpg" ]; then
        # 2. Crop to center square (max dimensions)
        ffmpeg -y -i "$TEMP_DIR/cover.jpg" -vf "crop='min(iw,ih)':'min(iw,ih)'" "$TEMP_DIR/cover_square.jpg" -loglevel error

        # 3. Create a temporary MP3 with the NEW square art
        # We use -map_metadata -1 here because ExifTool will handle it better in the next step
        ffmpeg -y -i "$file" -i "$TEMP_DIR/cover_square.jpg" \
            -map 0:a -map 1:0 -c copy -disposition:v:0 attached_pic \
            -map_metadata -1 "$TEMP_DIR/temp_output.mp3" -loglevel error

        # 4. Use ExifTool to copy ALL original metadata (tags, ratings, etc.) 
        # EXCEPT the old picture, since we just added the square one.
        exiftool -overwrite_original -tagsFromFile "$file" --attached_pic "$TEMP_DIR/temp_output.mp3" -loglevel error

        # 5. Overwrite the original file
        mv "$TEMP_DIR/temp_output.mp3" "$file"
        
        # Cleanup for next loop
        rm "$TEMP_DIR/cover.jpg" "$TEMP_DIR/cover_square.jpg"
        echo "Successfully squared: $(basename "$file")"
    else
        echo "No cover art found in $(basename "$file"), skipping."
    fi
done

rm -rf "$TEMP_DIR"
echo "--- All processing complete! ---"
