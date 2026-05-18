#!/bin/bash
# --- HELP UTILITY START ---
show_help() {
    cat << HELP_EOF
Usage: ${0##*/}

Description:
    The Herald of Oaths. Binds the Radiant Help Template to all scripts
    in the directory that do not yet carry an Oath.

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

# 1. Path to your permanent template file
MASTER_TEMPLATE="$HOME/.local/bin/help_template.txt"
# 2. Where your scripts live
TARGET_DIR="$HOME/.local/bin"

# Safety check
if [[ ! -f "$MASTER_TEMPLATE" ]]; then
    echo -e "${VOID}🌩️ Error:${NC} The Master Template is missing from the Cognitive Realm."
    exit 1
fi

echo -e "${STORMLIGHT}󱐌 Summoning the Heralds to inspect the scripts...${NC}"

for script in "$TARGET_DIR"/*.sh; do
    [ -e "$script" ] || continue
    [ "$(basename "$script")" == "help_adder.sh" ] && continue

    # Skip if the script already has a help flag
    if grep -qiE "\-h|--help|show_help" "$script"; then
        echo -e "${SYL}󱇊 Skipping:${NC} $script already carries an Oath."
    else
        echo -e "${STORMLIGHT}✨ Binding:${NC} ${SYL}Bringing the Oath to $script...${NC}"
        
        # This inserts the content of MASTER_TEMPLATE after the first line (shebang)
        sed -i '' "1r $MASTER_TEMPLATE" "$script"
    fi
done

echo -e "${SYL}---------------------------------------${NC}"
echo -e "${HONOR}✨ Injection complete.${NC} All scripts are now Radiant."
