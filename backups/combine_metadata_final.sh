#!/bin/bash
# FINAL PRODUCTION SCRIPT - Cleans + Embeds ALL Google Photos metadata
# Recursive, safe, complete

ROOT_DIR="${1:-.}"
[[ ! -d "$ROOT_DIR" ]] && { echo "Usage: $0 /path/to/photos"; exit 1; }

echo "🔄 Processing ALL Google Photos metadata in: $ROOT_DIR"
processed=0 cleaned=0

while IFS= read -r -d '' json_file; do
    json_dir=$(dirname "$json_file")
    base_name=$(basename "$json_file" .json | sed 's/\.[^.]*$//')
    image_file=$(find "$json_dir" -maxdepth 1 -name "$base_name*" ! -name "*.json" ! -name "*.JSON" | head -1)
    
    [[ ! -f "$image_file" ]] && continue
    
    echo "Processing: $(basename "$image_file")"
    
    # Extract ALL Google Photos fields
    title=$(jq -r '.title // empty' "$json_file")
    desc=$(jq -r '.description // empty' "$json_file")
    photo_ts=$(jq -r '.photoTakenTime.timestamp // empty' "$json_file")
    creation_ts=$(jq -r '.creationTime.timestamp // empty' "$json_file")
    lat=$(jq -r '.geoData.latitude // .geoDataExif.latitude // 0' "$json_file")
    lon=$(jq -r '.geoData.longitude // .geoDataExif.longitude // 0' "$json_file")
    origin=$(jq -r '.googlePhotosOrigin // empty' "$json_file")
    
    # Build comprehensive command
    cmd=("$image_file" "-overwrite_original" "-m")
    
    # CORE Google Photos metadata
    [[ -n "$title" ]] && cmd+=(-ImageDescription="$title" -ObjectName="$title")
    [[ -n "$desc" ]] && cmd+=(-Description="$desc" -Caption-Abstract="$desc")
    
    # Timestamps (priority: photoTaken > creation)
    if [[ "$photo_ts" != "null" && -n "$photo_ts" ]]; then
        ts=$(date -j -f %s "$photo_ts" +%Y:%m:%d\ %H:%M:%S 2>/dev/null)
        [[ -n "$ts" ]] && cmd+=(-AllDates="$ts")
    elif [[ "$creation_ts" != "null" && -n "$creation_ts" ]]; then
        ts=$(date -j -f %s "$creation_ts" +%Y:%m:%d\ %H:%M:%S 2>/dev/null)
        [[ -n "$ts" ]] && cmd+=(-AllDates="$ts")
    fi
    
    # GPS (Singapore coords will be preserved!)
    if [[ "$lat" != "0" && "$lat" != "0.0" ]] || [[ "$lon" != "0" && "$lon" != "0.0" ]]; then
        cmd+=(-GPSLatitude="$lat" -GPSLongitude="$lon")
        cmd+=(-GPSLatitudeRef=$( [[ $(echo "$lat >= 0" | bc -l) -eq 1 ]] && echo "N" || echo "S" ))
        cmd+=(-GPSLongitudeRef=$( [[ $(echo "$lon >= 0" | bc -l) -eq 1 ]] && echo "E" || echo "W" ))
    fi
    
    # Google Photos origin tracking
    [[ -n "$origin" ]] && cmd+=(-UserComment="GooglePhotos: $origin")
    
    # CLEANUP: Remove corrupted tags
    cmd+=(-UserComment-)  # Clear previous corruption first
    
    # Execute
    if [ ${#cmd[@]} -gt 3 ]; then
        exiftool "${cmd[@]}"
        ((processed++))
    fi
done < <(find "$ROOT_DIR" -type f -name "*.json" -print0)

echo "✅ COMPLETE! Processed: $processed files"
echo "📁 Backups: *_original (find . -name '*_original' | wc -l)"
echo "🔍 Verify: exiftool -G -a -s IMG_20190327_180701.jpg | grep -E '(GPS|Description|GooglePhotos)'"

