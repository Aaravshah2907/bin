#!/bin/bash

# Check if a directory was provided
TARGET_DIR="${1:-.}"

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' not found."
    exit 1
fi

# Ask for the series name to use in the title/filename
echo "Enter the Series Name (e.g., Shangrila-Frontier):"
read -r SERIES_NAME

# Create unproc folder inside the target directory
mkdir -p "$TARGET_DIR/unproc"

# Loop through MKV files in the specified folder
# We use find to avoid the loop breaking if the directory content changes during movement
find "$TARGET_DIR" -maxdepth 1 -name "*.mkv" | while read -r f; do
    
    filename=$(basename "$f")
    
    # Extract episode identifier (e.g., e01 -> E01)
    ep=$(echo "$filename" | grep -oiE 'e[0-9]{2}' | head -n 1 | tr '[:lower:]' '[:upper:]')
    
    if [ -n "$ep" ]; then
        new_name="${ep}-${SERIES_NAME}"
        
        echo "Processing: $filename -> ${new_name}.mkv"
        
        # 1. Create the edited file in the target (parent) directory
        ffmpeg -i "$f" \
               -map 0 \
               -c copy \
               -map_metadata 0 \
               -metadata title="$new_name" \
               "$TARGET_DIR/${new_name}.mkv" -y -loglevel error
        
        # 2. Move the original unedited file to unproc
        mv "$f" "$TARGET_DIR/unproc/"
    else
        echo "Skipping '$filename' (No E00 pattern found). Moving to unproc anyway..."
        mv "$f" "$TARGET_DIR/unproc/"
    fi
done

echo "--------------------------------------"
echo "Batch processing complete."
echo "Edited files are in: $TARGET_DIR"
echo "Originals moved to: $TARGET_DIR/unproc"
