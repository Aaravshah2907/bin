#!/bin/bash

## For combing mp3 files in a directory into a m4b file.

# --- HELP UTILITY START ---
show_help() {
    cat << HELP_EOF
Usage: ${0##*/} /path/to/folder

Description:
    Binding multiple rhythms together into a single Soulcast Audiobook (M4B).
    Preserves chapters, cover art, and metadata during the Binding process.

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

# --- 1. SETUP & INPUTS ---
if [ -z "$1" ]; then
    show_help
    exit 1
fi

TARGET_DIR=$(realpath "$1")
cd "$TARGET_DIR" || exit 1

echo -e "${STORMLIGHT}󱐌 Bridgeboy, what should this collective Soul be called?${NC}"
read -rp "Enter Audiobook Title: " TITLE_INPUT
read -rp "Enter Album Name:     " ALBUM_NAME
read -rp "Enter Author (Artist): " AUTHOR_NAME
echo -e "${SYL}---------------------------------------${NC}"

OUTPUT="combined_audiobook.m4b"
LIST_FILE="list.txt"
META_FILE="metadata.txt"

echo -e "${STORMLIGHT}🚀 Starting Binding in:${NC} ${SYL}$TARGET_DIR${NC}"

# --- 2. FILENAME SANITIZATION ---
for f in *.[mM][pP]3; do
    [ -e "$f" ] || continue
    clean_name=$(echo "$f" | sed "s/['()\[\]]//g" | tr ' ' '_')
    if [ "$f" != "$clean_name" ]; then
        mv "$f" "$clean_name"
    fi
done

# --- 3. AUTO-DETECT IMAGE ---
COVER_IMAGE=$(ls | grep -Ei "\.(jpg|jpeg|png)$" | head -n 1)

# --- 4. GENERATE LIST AND CHAPTER METADATA ---
echo -e "${SYL}📝 Distilling the Essence of the chapters...${NC}"
rm -f "$LIST_FILE" "$META_FILE"

# Create metadata header
cat <<EOF > "$META_FILE"
;FFMETADATA1
title=$TITLE_INPUT
album=$ALBUM_NAME
artist=$AUTHOR_NAME
genre=Audiobook
EOF

shopt -s nullglob
files=( *.[mM][pP]3 )
shopt -u nullglob

if [ ${#files[@]} -eq 0 ]; then
    echo -e "${VOID}❌ No rhythm fragments (MP3) found in $TARGET_DIR${NC}"
    exit 1
fi

CURRENT_TIME=0
IFS=$'\n' sorted_files=($(printf "%s\n" "${files[@]}" | sort -V))
unset IFS

for f in "${sorted_files[@]}"; do
    escaped_f=$(echo "$f" | sed "s/'/'\\\\''/g")
    echo "file '$escaped_f'" >> "$LIST_FILE"
    
    DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$f")
    
    START_MS=$(echo "($CURRENT_TIME * 1000) / 1" | bc)
    END_TIME=$(echo "$CURRENT_TIME + $DURATION" | bc)
    END_MS=$(echo "($END_TIME * 1000) / 1" | bc)
    
    CHAP_TITLE=$(basename "$f" | sed 's/\.[^.]*$//' | tr '_' ' ')
    
    cat <<EOF >> "$META_FILE"
[CHAPTER]
TIMEBASE=1/1000
START=$START_MS
END=$END_MS
title=$CHAP_TITLE
EOF
    
    CURRENT_TIME=$END_TIME
done

# --- 5. EXECUTE FFMPEG ---
echo -e "${STORMLIGHT}🏗️  Binding into a single Shard (AAC)...${NC}"

if [ -n "$COVER_IMAGE" ]; then
    ffmpeg -hide_banner -loglevel panic -f concat -safe 0 -i "$LIST_FILE" -i "$COVER_IMAGE" -i "$META_FILE" \
        -map 0:a -map 1:v -map_metadata 2 \
        -c:a aac -b:a 128k -af "aresample=async=1" \
        -c:v copy -disposition:v:0 attached_pic \
        -stats -y "$OUTPUT"
else
    ffmpeg -hide_banner -loglevel panic -f concat -safe 0 -i "$LIST_FILE" -i "$META_FILE" \
        -map 0:a -map_metadata 1 \
        -c:a aac -b:a 128k -af "aresample=async=1" \
        -stats -y "$OUTPUT"
fi

rm "$LIST_FILE" "$META_FILE"
echo -e "${SYL}------------------------------------------------${NC}"
echo -e "${HONOR}✨ Journey before destination!${NC} Your Binding is complete."
echo -e "${SYL}Final Shard:  $OUTPUT${NC}"
echo -e "${SYL}Title:        $TITLE_INPUT${NC}"
echo -e "${SYL}Album:  $ALBUM_NAME${NC}"
echo -e "${SYL}Author: $AUTHOR_NAME${NC}"
echo -e "${SYL}------------------------------------------------${NC}"
