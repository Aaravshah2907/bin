#!/usr/bin/env bash

# Use fd to find .git directories, strip the /.git from the path, and pipe to fzf
# -H (hidden), -t d (directories), -E (exclude)
TARGET=$(fd -H '^\.git$' ~/ -t d -E Library -x echo {//} | fzf --prompt="🌳 Git Repos > " --border=rounded --height=80%)

# If a selection was made
if [[ -n "$TARGET" ]]; then
    # 1. Tell the parent Yazi instance to jump to this directory
    ya emit cd "$TARGET"
    
    # 2. Launch lazygit in the target directory
    lazygit -p "$TARGET"
fi
