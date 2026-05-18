#!/bin/bash
# --- HELP UTILITY START ---
show_help() {
    cat << HELP_EOF
Usage: ${0##*/} [FILE_PATH]

Description:
    Grants authority to a file, allowing it to act in the physical realm (chmod +x).

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

# Check if no arguments were provided
if [ $# -eq 0 ]; then
    echo -e "${VOID}🌩️ Error:${NC} No file specified to grant authority."
    show_help
    exit 1
fi

FILE_PATH=$1

# Check if the file exists
if [ -e "$FILE_PATH" ]; then
    chmod +x "$FILE_PATH"
    echo -e "${HONOR}✨ Authority Granted:${NC} ${SYL}'$FILE_PATH' can now fly!${NC}"
else
    echo -e "${VOID}🌩️ Error:${NC} I can't find '$FILE_PATH' in this realm."
    exit 1
fi
