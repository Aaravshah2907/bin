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

# --- Radiant Theme Colors ---
STORMLIGHT='\033[0;36m' 
HONOR='\033[0;33m'      
SYL='\033[0;37m'        
VOID='\033[0;35m'       
NC='\033[0m'            

# 1. Check if a directory was provided
if [ -z "$1" ] || [ ! -d "$1" ]; then
    echo -e "${VOID}🌩️ Error:${NC} I can't find that directory in the Physical Realm. Usage: ${0##*/} /path/to/folder"
    exit 1
fi

TARGET_DIR="$1"
TEMP_DIR=$(mktemp -d)

# 2. Prompt user for metadata
echo -e "${STORMLIGHT}󱐌 Bridgeboy, what Essence should I weave into these songs?${NC}"
read -rp "Enter Artist Name: " ARTIST
read -rp "Enter Album Name:  " ALBUM
read -rp "Enter Genre:       " GENRE
read -rp "Enter Release Year: " YEAR
echo -e "${SYL}-------------------------------${NC}"

# 3. Confirmation
echo -e "${STORMLIGHT}✨ Preparing to bind metadata for all MP3s in '$TARGET_DIR':${NC}"
echo -e "${SYL}  Artist: $ARTIST | Album: $ALBUM | Genre: $GENRE | Year: $YEAR${NC}"
read -rp "Journey before destination! Begin the Binding? (y/n): " CONFIRM

if [[ $CONFIRM != [yY] ]]; then
    echo -e "${VOID}Aborted.${NC} The storms have passed."
    exit 0
fi

# 4. Loop through files using FFmpeg
find "$TARGET_DIR" -maxdepth 1 -type f -iname "*.mp3" | while read -r file; do
    FILENAME=$(basename "$file")
    echo -e "${STORMLIGHT}󱐌 Soulcasting:${NC} ${SYL}$FILENAME${NC}"

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
echo -e "${SYL}-------------------------------${NC}"
echo -e "${HONOR}✨ Success!${NC} All tracks have been ascended and updated!"
