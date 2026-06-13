#!/bin/bash
# --- HELP UTILITY START ---

# For splitting a m4b file into seperate files based on chapter ranges.

show_help() {
    cat << HELP_EOF
Usage: ${0##*/} [M4B FILE]

Description:
    Accepts a M4B file and splits it based on chapter selection by user.
    
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

if [[ -z "$1" ]]; then
    echo -e "${HONOR}Usage:${NC} ${0##*/} /path/to/file.m4b"
    exit 1
fi

INPUT_FILE=$(realpath "$1")
INPUT_DIR=$(dirname "$INPUT_FILE")
FILENAME_BASE=$(basename "${INPUT_FILE%.*}")

# 1. Extract chapter data
METADATA=$(ffprobe -i "$INPUT_FILE" -print_format json -show_chapters -loglevel error)
CHAPTER_COUNT=$(echo "$METADATA" | jq '.chapters | length')

if [[ "$CHAPTER_COUNT" -eq 0 ]]; then
    echo -e "${VOID}🌩️ Error:${NC} No Soul-structure (chapters) found in this Shard."
    exit 1
fi

# 2. Display Chapters
echo -e "${STORMLIGHT}󱐌 Examining the Soul-structure of the Shard...${NC}"
echo -e "${SYL}---------------------------------------${NC}"
echo "$METADATA" | jq -r '.chapters[] | "[\((.id + 1))] \(.tags.title // "Untitled Chapter")"'
echo -e "${SYL}---------------------------------------${NC}"

# 3. Get user selection
echo -e "${STORMLIGHT}⚔️ Bridgeboy, which fragments should I cleave?${NC}"
echo -e "Enter chapter ranges (e.g., '1-3 4-4 5-10'):"
read -rp "> " USER_RANGES

# 4. Process each range
PART_IDX=1
for RANGE in $USER_RANGES; do
    START_ID=$(echo "$RANGE" | cut -d'-' -f1)
    END_ID=$(echo "$RANGE" | cut -d'-' -f2)

    START_IDX=$((START_ID - 1))
    END_IDX=$((END_ID - 1))

    START_TIME=$(echo "$METADATA" | jq -r ".chapters[$START_IDX].start_time")
    END_TIME=$(echo "$METADATA" | jq -r ".chapters[$END_IDX].end_time")

    if [[ "$START_TIME" == "null" || "$END_TIME" == "null" ]]; then
        echo -e "${VOID}Skipping invalid fragment: $RANGE${NC}"
        continue
    fi

    PART_NUM=$(printf "P%02d" $PART_IDX)
    OUTPUT_PATH="${INPUT_DIR}/${FILENAME_BASE}_${PART_NUM}.mp3"

    echo -e "${STORMLIGHT}✨ Cleaving Range [$RANGE] to:${NC} ${SYL}$(basename "$OUTPUT_PATH")${NC}"

    ffmpeg -i "$INPUT_FILE" -ss "$START_TIME" -to "$END_TIME" -vn -c:a libmp3lame -q:a 2 "$OUTPUT_PATH" -loglevel error

    ((PART_IDX++))
done

echo -e "${SYL}---------------------------------------${NC}"
echo -e "${HONOR}✨ Soulcasting complete!${NC} The fragments are ready."
