#!/bin/bash
# --- HELP UTILITY START ---
show_help() {
    cat << HELP_EOF
Usage: ${0##*/} [DIR]

Description:
    Accepts a Directory as input and applies the same metadata to all mp3 files in the directory.
    
Options:
    -h, --help    Display this help message and exit.

HELP_EOF
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi
# --- HELP UTILITY END ---

# 1. Check if a directory was provided
if [ -z "$1" ] || [ ! -d "$1" ]; then
    echo "Usage: ./massMetaData.sh /path/to/music_folder"
    exit 1
fi

TARGET_DIR="$1"
TEMP_DIR=$(mktemp -d)

# 2. Prompt user for metadata
echo "--- MP3 Mass Metadata Entry (FFmpeg Edition) ---"
read -p "Enter Artist Name: " ARTIST
read -p "Enter Album Name:  " ALBUM
read -p "Enter Genre:       " GENRE
read -p "Enter Release Year: " YEAR
echo "-------------------------------"

# 3. Confirmation
echo "Applying to all MP3s in '$TARGET_DIR':"
echo "  Artist: $ARTIST | Album: $ALBUM | Genre: $GENRE | Year: $YEAR"
read -p "Continue? (y/n): " CONFIRM

if [[ $CONFIRM != [yY] ]]; then
    echo "Aborted."
    exit 0
fi

# 4. Loop through files using FFmpeg
# We use -c copy to ensure audio quality is NOT touched.
find "$TARGET_DIR" -maxdepth 1 -type f -iname "*.mp3" | while read -r file; do
    FILENAME=$(basename "$file")
    echo "Tagging: $FILENAME"

    ffmpeg -y -i "$file" \
        -metadata artist="$ARTIST" \
        -metadata album="$ALBUM" \
        -metadata genre="$GENRE" \
        -metadata date="$YEAR" \
        -id3v2_version 3 \
        -c copy \
        "$TEMP_DIR/$FILENAME" -loglevel error

    # Move the tagged file back to the original location
    mv "$TEMP_DIR/$FILENAME" "$file"
done

# Cleanup
rm -rf "$TEMP_DIR"
echo "-------------------------------"
echo "Success! All tracks from 'Kaladin' (or your chosen folder) are updated."
