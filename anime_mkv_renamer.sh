#!/bin/bash
# --- HELP UTILITY START ---
show_help() {
    cat << HELP_EOF
Usage: ${0##*/} [DIR]

Description:
    Soulcasts anime MKV files by renaming them based on a series name and episode number.
    Original files are moved to an 'unproc' folder (Cognitive Realm).

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

# Check if a directory was provided
TARGET_DIR="${1:-.}"

if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${VOID}🌩️ Error:${NC} I can't find the directory '$TARGET_DIR' in the Physical Realm."
    exit 1
fi

# Ask for the series name
echo -e "${STORMLIGHT}󱐌 Bridgeboy, what should we call this Soulcasted sequence?${NC}"
read -r SERIES_NAME

# Create unproc folder
mkdir -p "$TARGET_DIR/unproc"

# Loop through MKV files
find "$TARGET_DIR" -maxdepth 1 -name "*.mkv" | while read -r f; do
    
    filename=$(basename "$f")
    
    # Extract episode identifier
    ep=$(echo "$filename" | grep -oiE 'e[0-9]{2}' | head -n 1 | tr '[:lower:]' '[:upper:]')
    
    if [ -n "$ep" ]; then
        new_name="${ep}-${SERIES_NAME}"
        
        echo -e "${STORMLIGHT}✨ Lashing:${NC} ${SYL}$filename -> ${new_name}.mkv${NC}"
        
        # 1. Create the edited file
        ffmpeg -i "$f" \
               -map 0 \
               -c copy \
               -map_metadata 0 \
               -metadata title="$new_name" \
               "$TARGET_DIR/${new_name}.mkv" -y -loglevel error
        
        # 2. Move original to unproc
        mv "$f" "$TARGET_DIR/unproc/"
    else
        echo -e "${HONOR}󰊠 Skipping:${NC} '$filename' has no rhythmic pattern (E00). Moving to the unproc realm anyway..."
        mv "$f" "$TARGET_DIR/unproc/"
    fi
done

echo -e "${SYL}--------------------------------------${NC}"
echo -e "${HONOR}󱇊 Journey before destination!${NC} Soulcasting complete."
echo -e "${SYL}Ascended files are in: $TARGET_DIR${NC}"
echo -e "${SYL}Originals hidden in Cognitive Realm: $TARGET_DIR/unproc${NC}"
