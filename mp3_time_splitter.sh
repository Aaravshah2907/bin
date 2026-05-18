#!/bin/bash
# --- HELP UTILITY START ---
show_help() {
    cat << HELP_EOF
Usage: ${0##*/} [FILE...]

Description:
    Splitting MP3 files based on timestamps.

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

# Dependency Check
if ! command -v ffmpeg &> /dev/null || ! command -v ffprobe &> /dev/null; then
    echo -e "${VOID}🌩️ Error: Shardblades (ffmpeg/ffprobe) not found in the Physical Realm.${NC}"
    exit 1
fi

INPUT="$1"
shift 
TIMESTAMPS=("$@")

if [[ -z "$INPUT" || ${#TIMESTAMPS[@]} -eq 0 ]]; then
    echo -e "${HONOR}Usage:${NC} ${0##*/} <file.mp3> <time1> <time2> ..."
    exit 1
fi

# 1. Extract existing metadata
TOTAL_DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT")
ORIG_TITLE=$(ffprobe -v error -show_entries format_tags=title -of default=noprint_wrappers=1:nokey=1 "$INPUT")
ORIG_ALBUM=$(ffprobe -v error -show_entries format_tags=album -of default=noprint_wrappers=1:nokey=1 "$INPUT")
ORIG_ARTIST=$(ffprobe -v error -show_entries format_tags=artist -of default=noprint_wrappers=1:nokey=1 "$INPUT")

# 2. Check for missing metadata
if [ -z "$ORIG_TITLE" ]; then
    echo -e "${STORMLIGHT}󱐌 Bridgeboy, the Title Essence is missing!${NC}"
    read -rp "Enter Title (or Enter to keep original): " ORIG_TITLE
    [ -z "$ORIG_TITLE" ] && ORIG_TITLE="${INPUT%.*}"
fi

if [ -z "$ORIG_ALBUM" ]; then
    read -rp "Album Essence missing. Enter Album: " ORIG_ALBUM
fi

if [ -z "$ORIG_ARTIST" ]; then
    read -rp "Author Essence missing. Enter Author: " ORIG_ARTIST
fi

# 3. Prepare split points
POINTS=("0" "${TIMESTAMPS[@]}" "$TOTAL_DURATION")
NUM_PARTS=$((${#POINTS[@]} - 1))
EXTENSION="${INPUT##*.}"
BASENAME="${INPUT%.*}"

echo -e "${SYL}---------------------------------------${NC}"
echo -e "${STORMLIGHT}󱐌 Examining Essence:${NC} ${SYL}$INPUT${NC}"
echo -e "${SYL}Title: $ORIG_TITLE${NC}"
echo -e "${SYL}---------------------------------------${NC}"

# 4. Perform the split
for (( i=0; i<$NUM_PARTS; i++ ))
do
    START="${POINTS[$i]}"
    END="${POINTS[$((i+1))]}"
    PART_NUM=$((i + 1))
    
    printf -v PAD_PART "%02d" $PART_NUM
    
    OUT_FILE="${BASENAME}_Part${PAD_PART}.${EXTENSION}"
    NEW_TITLE="${ORIG_TITLE} Part ${PART_NUM}"

    echo -e "${STORMLIGHT}⚔️ Cleaving Part $PART_NUM:${NC} ${SYL}[$START to $END] -> $OUT_FILE${NC}"

    ffmpeg -v quiet -stats -i "$INPUT" -ss "$START" -to "$END" \
           -map_metadata 0 \
           -metadata title="$NEW_TITLE" \
           -metadata album="$ORIG_ALBUM" \
           -metadata artist="$ORIG_ARTIST" \
           -c copy "$OUT_FILE"
done

echo -e "${SYL}---------------------------------------${NC}"
echo -e "${HONOR}✨ Journey before destination!${NC} The segments are Soulcast."
