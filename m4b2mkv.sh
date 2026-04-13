#!/bin/bash
# --- HELP UTILITY START ---
show_help() {
    cat << HELP_EOF
Usage: ${0##*/} [OPTIONS] <file1.m4b> [file2.m4b ...]

Description:
    Converts M4B/M4A audiobooks into MKV containers. 
    Uses lossless remuxing to preserve all audio quality, chapters, 
    cover art, and metadata (author, genre, title, etc.).

Options:
    -h, --help    Display this help message and exit.

HELP_EOF
}
# --- HELP UTILITY END ---

m4b2mkv() {
    # Colors for output
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    NC='\033[0m'

    # Check if ffmpeg is installed
    if ! command -v ffmpeg &> /dev/null; then
        echo -e "${RED}Error: ffmpeg is not installed.${NC} Please install it using 'brew install ffmpeg'."
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
            echo -e "${RED}Error:${NC} File '$input' not found. Skipping."
            continue
        fi

        # Check extension (case insensitive)
        extension="${input##*.}"
        ext_lower=$(echo "$extension" | tr '[:upper:]' '[:lower:]')
        if [[ "$ext_lower" != "m4b" && "$ext_lower" != "m4a" ]]; then
            echo -e "${RED}Warning:${NC} '$input' does not appear to be an M4B/M4A file. Attempting anyway..."
        fi

        output="${input%.*}.mkv"

        # Handle file name collision
        if [[ -f "$output" ]]; then
            echo -e "${RED}Warning:${NC} '$output' already exists. Overwrite? (y/N)"
            read -r response
            if [[ "$response" != "y" ]]; then
                echo -e "${BLUE}Skipping:${NC} $input"
                continue
            fi
        fi

        echo -e "${BLUE}Converting:${NC} $input -> $output"

        # The ffmpeg command:
        # -map 0:a -map 0:v? -map 0:s?: Map only supported streams
        # -c:a aac -b:a 128k: Re-encode audio (streaming through encoder)
        # -c:v copy: Copy cover art as-is
        # -map_metadata 0: Preserve author, genre, title, etc.
        ffmpeg -hide_banner -loglevel error -i "$input" -map 0:a -map 0:v? -map 0:s? -c:a aac -b:a 128k -c:v copy -map_metadata 0 "$output"

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Successfully converted:${NC} $output"
        else
            echo -e "${RED}Failed to convert:${NC} $input"
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
