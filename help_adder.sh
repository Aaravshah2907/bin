#!/bin/bash

# 1. Path to your permanent template file
MASTER_TEMPLATE="$HOME/.local/bin/help_template.txt"
# 2. Where your scripts live
TARGET_DIR="$HOME/.local/bin"

# Safety check: make sure the template actually exists
if [[ ! -f "$MASTER_TEMPLATE" ]]; then
    echo "Error: Template file not found at $MASTER_TEMPLATE"
    exit 1
fi

for script in "$TARGET_DIR"/*.sh; do
    [ -e "$script" ] || continue

    # Skip if the script already has a help flag
    if grep -qiE "\-h|--help|show_help" "$script"; then
        echo "Skipping: $script (Already has help)"
    else
        echo "Injecting help into: $script"
        
        # This inserts the content of MASTER_TEMPLATE after the first line (shebang)
        # Note: On macOS, sed -i '' is required for in-place editing.
        sed -i '' "1r $MASTER_TEMPLATE" "$script"
    fi
done

echo "Injection complete."
