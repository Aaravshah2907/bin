#!/usr/bin/env bash

# Hardcoded PATH for macOS Homebrew
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

CURRENT_DIR=$(pwd)

find_repos() {
    # Find all .git folders, excluding heavy/irrelevant folders
    fd -H '^\.git$' "$HOME" -t d -E Library -E .Trash -E node_modules --max-depth 5 | while read -r git_dir; do
        
        # Get the project root folder (parent of .git)
        repo_path=$(dirname "$git_dir")
        
        if [[ -d "$repo_path" ]]; then
            # Check for uncommitted changes
            status=$(git -C "$repo_path" status --porcelain 2>/dev/null)
            display_path="${repo_path/#$HOME/\~}"
            
            # 1. PENDING CHANGES (DIRTY)
            if [[ -n "$status" ]]; then
                # Bold Yellow with a Tool Emoji for dirty repos
                if [[ "$repo_path" == "$CURRENT_DIR" ]]; then
                    echo -e "\033[1;32m➤ 🛠️  $display_path (Current/Dirty)\033[0m|$repo_path"
                else
                    echo -e "\033[1;33m* 🛠️  $display_path\033[0m|$repo_path"
                fi
            
            # 2. NO CHANGES (CLEAN)
            else
                # Cyan with a Checkmark for the current folder if it's clean
                if [[ "$repo_path" == "$CURRENT_DIR" ]]; then
                    echo -e "\033[1;36m➤ ✅ $display_path (Current/Clean)\033[0m|$repo_path"
                else
                    # Subtle grey/plain for other clean repos
                    echo -e "  ⚪ $display_path|$repo_path"
                fi
            fi
        fi
    done
}

# Run the function and pipe to fzf
SELECTED=$(find_repos | fzf --ansi \
    --prompt="🌳 Git Repos > " \
    --header="🛠️ = Pending Changes | ✅ = Current Folder" \
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
