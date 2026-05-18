#!/bin/bash
# --- HELP UTILITY START ---
show_help() {
    cat << HELP_EOF
Usage: ${0##*/} [DIR]

Description:
    Accepts a directory as input, then displays combined audio length of files in dir.
    
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
STORMLIGHT='\033[0;36m' # Cyan
HONOR='\033[0;33m'      # Gold
SYL='\033[0;37m'        # White/Silver
VOID='\033[0;35m'       # Purple
NC='\033[0m'            # No Color

# 1. Check for folder input
TARGET_DIR="${1:-.}" # Defaults to current directory if no path provided
cd "$TARGET_DIR" || exit 1

echo -e "${STORMLIGHT}󱐌 Listening to the rhythms of the wind in:${NC} ${SYL}$PWD${NC}"
echo -e "${SYL}---------------------------------------${NC}"

total_seconds=0
file_count=0

# 2. Loop through MP3 files
for f in *.[mM][pP]3; do
    [ -e "$f" ] || continue
    
    # Get duration of individual file in seconds
    duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$f")
    
    # Add to total (using bc for decimal math)
    total_seconds=$(echo "$total_seconds + $duration" | bc)
    ((file_count++))
    
    echo -e "${SYL}   󰎈 Caught a snippet of: $f${NC}"
done

# 3. Convert total seconds to H:M:S
h=$(echo "$total_seconds/3600" | bc)
m=$(echo "($total_seconds%3600)/60" | bc)
s=$(echo "$total_seconds%60" | bc | cut -d. -f1)

echo -e "${SYL}---------------------------------------${NC}"
echo -e "${SYL}Soulcast fragments:${NC} ${HONOR}$file_count${NC}"
printf "${STORMLIGHT}✨ Combined Song of the Highstorm:${NC} ${HONOR}%02d:%02d:%02d${NC}\n" $h $m $s
