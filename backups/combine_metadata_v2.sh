#!/bin/bash
# Fixed Google Photos JSON to EXIF - v2 with debug
# brew install exiftool jq bc

DIR="${1:-.}"
EXIFTOOL="exiftool"

for json_file in "$DIR"/*.{json,JSON}; do
    [[ ! -f "$json_file" ]] && continue
    
    # Extract base name (handles filename.jpg.json → filename.jpg)
    base_name=$(basename "$json_file" .json | sed 's/\.[^.]*$//')
    image_file=$(find "$DIR" -maxdepth 1 -name "$base_name*" ! -name "*.json" ! -name "*.JSON" | head -1)
    [[ ! -f "$image_file" ]] && { echo "No image for $json_file"; continue; }
    
    echo "=== Processing $json_file → $image_file ==="
    
    # Extract ALL fields with null checks
    photo_taken_ts=$(jq -r '.photoTakenTime.timestamp // empty' "$json_file")
    creation_ts=$(jq -r '.creationTime.timestamp // empty' "$json_file")
    modified_ts=$(jq -r '.photoLastModifiedTime.timestamp // empty' "$json_file")
    title=$(jq -r '.title // empty' "$json_file" | sed 's/[^[:print:]]//g')
    description=$(jq -r '.description // empty' "$json_file" | sed 's/[^[:print:]]//g')
    
    # GPS (only if non-zero)
    lat=$(jq -r '.geoData.latitude // .geoDataExif.latitude // 0' "$json_file")
    lon=$(jq -r '.geoData.longitude // .geoDataExif.longitude // 0' "$json_file")
    alt=$(jq -r '.geoData.altitude // .geoDataExif.altitude // 0' "$json_file")
    
    echo "  Timestamps: photo=$photo_taken_ts, create=$creation_ts, mod=$modified_ts"
    echo "  Title: '$title' | Desc: '$description'"
    echo "  GPS: $lat, $lon, $alt"
    
    # Convert primary timestamp (photoTakenTime > creation > modified)
    main_time=""
    for ts in "$photo_taken_ts" "$creation_ts" "$modified_ts"; do
        [[ -n "$ts" && "$ts" != "null" ]] && {
            main_time=$(date -j -f %s "$ts" +%Y:%m:%d\ %H:%M:%S 2>/dev/null)
            [[ -n "$main_time" ]] && break
        }
    done
    
    # Build command
    cmd=("$image_file" "-overwrite_original" "-m")
    
    # Dates (preserve existing if no JSON data)
    if [[ -n "$main_time" ]]; then
        cmd+=(-DateTimeOriginal="$main_time")
        cmd+=(-CreateDate="$main_time")
        cmd+=(-ModifyDate="$main_time")
        echo "  → Setting dates to $main_time"
    fi
    
    # Descriptions (only if non-empty)
    [[ -n "$title" && "$title" != "null" && "$title" != "$base_name" ]] && {
        cmd+=(-ImageDescription="$title")
        cmd+=(-ObjectName="$title")
        echo "  → Title: $title"
    }
    [[ -n "$description" && "$description" != "null" && "$description" != "" ]] && {
        cmd+=(-Description="$description")
        cmd+=(-Caption-Abstract="$description")
        echo "  → Desc: $description"
    }
    
    # GPS (exiftool auto-converts decimal to DMS)
    if [[ $(echo "$lat != 0 || $lon != 0" | bc -l 2>/dev/null) ]]; then
        cmd+=(-GPSLatitude="$lat" -GPSLongitude="$lon")
        cmd+=(-GPSLatitudeRef=$(echo "$lat >= 0" | bc -l | sed 's/1/N/;/0/s//S/'))
        cmd+=(-GPSLongitudeRef=$(echo "$lon >= 0" | bc -l | sed 's/1/E/;/0/s//W/'))
        [[ "$alt" != "0" && "$alt" != "0.0" ]] && cmd+=(-GPSAltitude="$alt")
        echo "  → GPS added"
    fi
    
    # Execute
    if [ ${#cmd[@]} -gt 3 ]; then
        echo "  Running: ${EXIFTOOL} ${cmd[*]:2}"
        "${EXIFTOOL}" "${cmd[@]}"
        mv "${image_file}_original" "${image_file}.bak"
    else
        echo "  → No new metadata to add (existing EXIF preserved)"
    fi
done

echo "Done! Check .bak backups and run 'exiftool -G -a -s file.jpg' to verify."

