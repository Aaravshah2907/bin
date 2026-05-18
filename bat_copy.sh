#!/bin/bash
# --- HELP UTILITY START ---
show_help() {
    cat << HELP_EOF
Usage: ${0##*/} [FILE_PATH]

Description:
    Lashes the Soul (content) of a file directly to the system clipboard.

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
    echo -e "${VOID}🌩️ Error:${NC} No file specified to Lash."
    show_help
    exit 1
fi

FILE_PATH=$1

# Check if the file exists
if [ -f "$FILE_PATH" ]; then
    cat "$FILE_PATH" | pbcopy
    echo -e "${HONOR}✨ Lashing Complete:${NC} ${SYL}The Soul of '$FILE_PATH' is now in your grasp.${NC}"
else
    echo -e "${VOID}🌩️ Error:${NC} I can't find that file in this realm."
    exit 1
fi
