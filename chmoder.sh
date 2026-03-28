#!/bin/bash

# Function to display usage
show_help() {
    echo "Usage: $0 [FILE_PATH]"
    echo "Sets the execute permission (chmod +x) for the specified file."
    echo ""
    echo "Options:"
    echo "  -h    Show this help message and exit."
}

# Check if no arguments were provided
if [ $# -eq 0 ]; then
    echo "Error: No file specified."
    show_help
    exit 1
fi

# Check for the -h flag
if [ "$1" == "-h" ]; then
    show_help
    exit 0
fi

# Assign argument to a variable for clarity
FILE_PATH=$1

# Check if the file exists
if [ -e "$FILE_PATH" ]; then
    chmod +x "$FILE_PATH"
    echo "Success: Permissions updated for '$FILE_PATH'"
else
    echo "Error: File '$FILE_PATH' not found."
    exit 1
fi
