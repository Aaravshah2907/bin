#!/bin/bash
# --- HELP UTILITY START ---
show_help() {
    cat << HELP_EOF
Usage: ${0##*/} [OPTIONS] <file1.m4b> [file2.m4b ...]

Description:
    Infuses M4B/M4A audiobooks with Stormlight and ascends them into MKV containers.
    Preserves all Soulcast chapters, cover art, and metadata (author, genre, title, etc.).

Options:
    -h, --help    Display this help message and exit.

HELP_EOF
}
# --- HELP UTILITY END ---

m4b2mkv() {
    # --- Radiant Theme Colors ---
    STORMLIGHT='\033[0;36m' # Cyan
    HONOR='\033[0;33m'      # Gold
    SYL='\033[0;37m'        # White/Silver
    VOID='\033[0;35m'       # Purple
    NC='\033[0m'            # No Color

    # Check if ffmpeg is installed
    if ! command -v ffmpeg &> /dev/null; then
        echo -e "${VOID}🌩️ Error: ffmpeg is not present in the Physical Realm.${NC} Please install it using 'brew install ffmpeg'."
        return 1
    fi

    # Show help if no arguments provided
    if [ $# -eq 0 ]; then
        show_help
        return 1
    fi

    # Process each file provided
    for input in "$@"; do
        if [[ ! -f "$input" ]]; then
            echo -e "${VOID}🌩️ Storms!${NC} I can't find '$input' anywhere in the Cognitive Realm. Skipping."
            continue
        fi

        # Check extension (case insensitive)
        extension="${input##*.}"
        ext_lower=$(echo "$extension" | tr '[:upper:]' '[:lower:]')
        if [[ "$ext_lower" != "m4b" && "$ext_lower" != "m4a" ]]; then
            echo -e "${HONOR}󱐋 Warning:${NC} '$input' doesn't look like an audiobook to me, Bridgeboy. Attempting anyway!"
        fi

        output="${input%.*}.mkv"

        # Handle file name collision
        if [[ -f "$output" ]]; then
            echo -e "${HONOR}󱐋 Storms!${NC} A Shard named '$output' already exists. Should I Lash over it? (y/N)"
            read -r response
            if [[ "$response" != "y" ]]; then
                echo -e "${SYL}󰊠 Skipping:${NC} Keeping the old Shard. $input"
                continue
            fi
        fi

        filename=$(basename "$input")
        echo -e "${STORMLIGHT}󱐌 Infusing:${NC} ${SYL}Journey before destination! Transforming '$filename'...${NC}"

        # The ffmpeg command:
        # -map 0:a -map 0:v? -map 0:s?: Map only supported streams
        # -c:a aac -b:a 128k: Re-encode audio (streaming through encoder)
        # -c:v copy: Copy cover art as-is
        # -map_metadata 0: Preserve author, genre, title, etc.
        ffmpeg -hide_banner -loglevel error -i "$input" -map 0:a -map 0:v? -map 0:s? -c:a aac -b:a 128k -c:v copy -map_metadata 0 "$output"

        if [ $? -eq 0 ]; then
            echo -e "${HONOR}✨ Life before death!${NC} ${SYL}'$filename' has been successfully ascended to MKV.${NC}"
        else
            echo -e "${VOID}🌩️ Odium reigns...${NC} I failed to convert '$input'. Maybe try again later?"
        fi
    done
}

# --- HELP CALL ---
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# --- CALL FUNCTION WITH ALL PARAMS ---
m4b2mkv "$@"
