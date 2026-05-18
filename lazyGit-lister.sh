#!/bin/bash
# --- HELP UTILITY START ---
show_help() {
    cat << HELP_EOF
Usage: ${0##*/}

Description:
    Locates all Git Shard-records (repositories) in your home realm.
    Identifies Broken Oaths (uncommitted changes) and allows for quick Lashing (CD + LazyGit).

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

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
CURRENT_DIR=$(pwd)

find_repos() {
    # Find all .git folders
    fd -H '^\.git$' "$HOME" -t d -E Library -E .Trash -E node_modules --max-depth 5 | while read -r git_dir; do
        repo_path=$(dirname "$git_dir")
        
        if [[ -d "$repo_path" ]]; then
            status=$(git -C "$repo_path" status --porcelain 2>/dev/null)
            display_path="${repo_path/#$HOME/\~}"
            
            # 1. PENDING CHANGES (DIRTY) - Broken Oaths
            if [[ -n "$status" ]]; then
                if [[ "$repo_path" == "$CURRENT_DIR" ]]; then
                    echo -e "${HONOR}➤ 🌩️ $display_path (Broken Oath/Current)${NC}|$repo_path"
                else
                    echo -e "${VOID}* 🌩️ $display_path${NC}|$repo_path"
                fi
            
            # 2. NO CHANGES (CLEAN) - Steady Rhythm
            else
                if [[ "$repo_path" == "$CURRENT_DIR" ]]; then
                    echo -e "${STORMLIGHT}➤ ✨ $display_path (Steady Rhythm/Current)${NC}|$repo_path"
                else
                    echo -e "${SYL}  ⚪ $display_path${NC}|$repo_path"
                fi
            fi
        fi
    done
}

# Run the function and pipe to fzf
SELECTED=$(find_repos | fzf --ansi \
    --prompt="󱐌 Consult Shard-records > " \
    --header="🌩️ = Broken Oath (Changes) | ✨ = Steady Rhythm" \
    --border=rounded \
    --height=80% \
    --delimiter='|' \
    --with-nth=1)

# Extract the actual path
TARGET=$(echo "$SELECTED" | cut -d'|' -f2)

if [[ -n "$TARGET" ]]; then
    ya emit cd "$TARGET"
    lazygit -p "$TARGET"
fi
