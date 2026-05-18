#!/bin/bash
# --- HELP UTILITY START ---
show_help() {
    cat << HELP_EOF
Usage: ${0##*/} [DIR]

Description:
    Combines M4B files into a single file. Not preffered. Split into mp3 files and then combining is a better option.

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
if [ -z "$1" ]; then
    echo -e "${HONOR}Usage:${NC} ${0##*/} /path/to/audiobook_folder"
    exit 1
fi

TARGET_DIR="$1"

# Check if the directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${VOID}🌩️ Error:${NC} Directory $TARGET_DIR does not exist in the Physical Realm."
    exit 1
fi

# Change to the target directory
cd "$TARGET_DIR" || exit

# 1. Get User Input
echo -e "${STORMLIGHT}󱐌 Bridgeboy, what should this unified Shard be called?${NC}"
read -rp "Enter Album/Book Name: " ALBUM
read -rp "Enter Author/Artist:    " AUTHOR
read -rp "Enter Title:            " TITLE
echo -e "${SYL}---------------------------------------${NC}"

# 2. Find the first image (jpg or png)
COVER=$(ls *.jpg *.jpeg *.png 2>/dev/null | head -n 1)

if [ -z "$COVER" ]; then
    echo -e "${HONOR}󱐋 Warning:${NC} No cover image found. Proceeding without art."
fi

# 3. Create a list of m4b files in alphabetical order
files=( *.m4b )
if [ ${#files[@]} -eq 0 ]; then
    echo -e "${VOID}🌩️ Storms!${NC} No .m4b files found in $TARGET_DIR"
    exit 1
fi

# 4. Prepare temporary concat list
CONCAT_FILE="files_to_merge.txt"
rm -f "$CONCAT_FILE"
for f in "${files[@]}"; do
    echo "file '$f'" >> "$CONCAT_FILE"
done

echo -e "${STORMLIGHT}🚀 Unifying Shards in:${NC} ${SYL}$TARGET_DIR${NC}"
echo -e "${SYL}Re-encoding and merging... This may take a few minutes.${NC}"

# 5. Run ffmpeg
ffmpeg -hide_banner -loglevel panic -f concat -safe 0 -i "$CONCAT_FILE" -i "$COVER" \
    -map 0:a -map 1:v \
    -c:a aac -b:a 128k \
    -c:v copy -disposition:v:0 attached_pic \
    -metadata album="$ALBUM" \
    -metadata artist="$AUTHOR" \
    -metadata title="$TITLE" \
    "merged_audiobook.m4b"

# 6. Cleanup
rm "$CONCAT_FILE"

echo -e "${SYL}------------------------------------------------${NC}"
echo -e "${HONOR}✨ Journey before destination!${NC} The Shards have been unified."
echo -e "${SYL}Saved in: $TARGET_DIR/merged_audiobook.m4b${NC}"
