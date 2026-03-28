#!/bin/bash

# Function to display usage
show_help() {
    echo "Usage: $0 [FILE_PATH]"
    echo "Copies the contents of the specified file to the system clipboard."
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

FILE_PATH=$1

# Check if the file exists and is a regular file
if [ -f "$FILE_PATH" ]; then
    # Cat the file and pipe it to pbcopy
    cat "$FILE_PATH" | pbcopy
    echo "Success: Contents of '$FILE_PATH' copied to clipboard."
else
    echo "Error: File '$FILE_PATH' not found or is not a valid file."
    exit 1
fi
