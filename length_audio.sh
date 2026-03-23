#!/bin/bash

# 1. Check for folder input
TARGET_DIR="${1:-.}" # Defaults to current directory if no path provided
cd "$TARGET_DIR" || exit 1

echo "Counting duration for files in: $PWD"
echo "---------------------------------------"

total_seconds=0
file_count=0

# 2. Loop through MP3 files
for f in *.[mM][pP]3; do
    [ -e "$f" ] || continue
    
    # Get duration of individual file in seconds
    duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$f")
    
    # Add to total (using bc for decimal math)
    total_seconds=$(echo "$total_seconds + $duration" | bc)
    ((file_count++))
    
    echo "Processing: $f ($(printf '%02d:%02d:%02d' $(echo "$duration/3600" | bc) $(echo "($duration%3600)/60" | bc) $(echo "$duration%60" | bc | cut -d. -f1)))"
done

# 3. Convert total seconds to H:M:S
h=$(echo "$total_seconds/3600" | bc)
m=$(echo "($total_seconds%3600)/60" | bc)
s=$(echo "$total_seconds%60" | bc | cut -d. -f1)

echo "---------------------------------------"
echo "Files processed: $file_count"
printf "Total Duration: %02d:%02d:%02d\n" $h $m $s
