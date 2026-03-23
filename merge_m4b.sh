#!/bin/bash

# Check if a directory was provided
if [ -z "$1" ]; then
    echo "Usage: ./merge_m4b.sh /path/to/audiobook_folder"
    exit 1
fi

TARGET_DIR="$1"

# Check if the directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory $TARGET_DIR does not exist."
    exit 1
fi

# Change to the target directory
cd "$TARGET_DIR" || exit

# 1. Get User Input
read -p "Enter Album/Book Name: " ALBUM
read -p "Enter Author/Artist: " AUTHOR
read -p "Enter Title: " TITLE

# 2. Find the first image (jpg or png)
COVER=$(ls *.jpg *.jpeg *.png 2>/dev/null | head -n 1)

if [ -z "$COVER" ]; then
    echo "Warning: No cover image found. Proceeding without art."
fi

# 3. Create a list of m4b files in alphabetical order
files=( *.m4b )
if [ ${#files[@]} -eq 0 ]; then
    echo "No .m4b files found in $TARGET_DIR"
    exit 1
fi

# 4. Prepare temporary concat list
CONCAT_FILE="files_to_merge.txt"
rm -f "$CONCAT_FILE"
for f in "${files[@]}"; do
    echo "file '$f'" >> "$CONCAT_FILE"
done

echo "Processing files in: $TARGET_DIR"
echo "Re-encoding and merging... this may take a few minutes."

# 5. Run ffmpeg
# -f concat: joins files
# -i "$COVER": adds the image
# -map_metadata 0: tells ffmpeg to attempt to carry over global metadata
ffmpeg -f concat -safe 0 -i "$CONCAT_FILE" -i "$COVER" \
    -map 0:a -map 1:v \
    -c:a aac -b:a 128k \
    -c:v copy -disposition:v:0 attached_pic \
    -metadata album="$ALBUM" \
    -metadata artist="$AUTHOR" \
    -metadata title="$TITLE" \
    "merged_audiobook.m4b"

# 6. Cleanup
rm "$CONCAT_FILE"

echo "------------------------------------------------"
echo "Done! File saved in: $TARGET_DIR/merged_audiobook.m4b"
