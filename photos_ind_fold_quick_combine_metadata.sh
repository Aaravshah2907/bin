#!/bin/bash
# --- HELP UTILITY START ---
show_help() {
    cat << HELP_EOF
Usage: ${0##*/} [DIR]

Description:
    Google Photos Takeout json and image/vid file combiner to match metadata.

Options:
    -h, --help    Display this help message and exit.

HELP_EOF
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi
# --- HELP UTILITY END ---
# Enhanced Google Photos JSON to EXIF merger for macOS
# Requires: brew install exiftool jq

DIR="${1:-.}"
EXIFTOOL="exiftool"

for json_file in "$DIR"/*.{json,json}; do
    [[ ! -f "$json_file" ]] && continue
    
    # Handle both filename.json and filename.ext.json patterns
    base_name="${json_file%.json}"
    base_name="${base_name%.*}"  # Remove extension for matching
    image_file="$DIR/$base_name*"
    
    # Find matching image (first match)
    image_file=$(find "$DIR" -maxdepth 1 -name "$base_name*" ! -name "*.json" | head -1)
    [[ ! -f "$image_file" ]] && continue
    
    echo "Processing $json_file → $image_file"
    
    # Extract all metadata with fallbacks using jq
    photo_taken=$(jq -r '.photoTakenTime.timestamp // empty' "$json_file")
    creation_time=$(jq -r '.creationTime.timestamp // empty' "$json_file")
    modified_time=$(jq -r '.photoLastModifiedTime.timestamp // empty' "$json_file")
    title=$(jq -r '.title // empty' "$json_file")
    description=$(jq -r '.description // empty' "$json_file")
    
    # GPS data (prefer geoData, fallback to geoDataExif)
    lat=$(jq -r '.geoData.latitude // .geoDataExif.latitude // 0' "$json_file")
    lon=$(jq -r '.geoData.longitude // .geoDataExif.longitude // 0' "$json_file")
    alt=$(jq -r '.geoData.altitude // .geoDataExif.altitude // 0' "$json_file")
    lat_span=$(jq -r '.geoData.latitudeSpan // .geoDataExif.latitudeSpan // 0' "$json_file")
    lon_span=$(jq -r '.geoData.longitudeSpan // .geoDataExif.longitudeSpan // 0' "$json_file")
    
    # Prioritize photoTakenTime, fallback to creation/modified
    if [[ -n "$photo_taken" ]]; then
        main_time=$(date -j -f %s "$photo_taken" +%Y:%m:%d\ %H:%M:%S 2>/dev/null)
    elif [[ -n "$creation_time" ]]; then
        main_time=$(date -j -f %s "$creation_time" +%Y:%m:%d\ %H:%M:%S 2>/dev/null)
    elif [[ -n "$modified_time" ]]; then
        main_time=$(date -j -f %s "$modified_time" +%Y:%m:%d\ %H:%M:%S 2>/dev/null)
    fi
    
    # Build exiftool args
    cmd=("$image_file" "-overwrite_original_in_place" "-m")
    
    # Timestamps (AllDates for JPEG, specific for others)
    [[ -n "$main_time" ]] && cmd+=(-AllDates="$main_time")
    [[ -n "$creation_time" ]] && {
        create_time=$(date -j -f %s "$creation_time" +%Y:%m:%d\ %H:%M:%S 2>/dev/null)
        cmd+=(-CreateDate="$create_time")
    }
    [[ -n "$modified_time" ]] && {
        mod_time=$(date -j -f %s "$modified_time" +%Y:%m:%d\ %H:%M:%S 2>/dev/null)
        cmd+=(-ModifyDate="$mod_time")
    }
    
    # Descriptions/Titles
    [[ -n "$title" && "$title" != "null" ]] && cmd+=(-ImageDescription="$title" -ObjectName="$title")
    [[ -n "$description" && "$description" != "null" && -n "$description" ]] && {
        cmd+=(-Description="$description")
        cmd+=(-Caption-Abstract="$description")
    }
    
    # GPS (exiftool handles decimal→DMS conversion automatically)
    if (( $(echo "$lat != 0 || $lon != 0" | bc -l 2>/dev/null) )); then
        cmd+=(-GPSLatitude="$lat")
        cmd+=(-GPSLongitude="$lon")
        [[ "$lat" != "0" && "$lat" != "0.0" ]] && cmd+=(-GPSLatitudeRef="$([[ $(echo "$lat >= 0" | bc -l) -eq 1 ]] && echo N || echo S)")
        [[ "$lon" != "0" && "$lon" != "0.0" ]] && cmd+=(-GPSLongitudeRef="$([[ $(echo "$lon >= 0" | bc -l) -eq 1 ]] && echo E || echo W)")
        [[ "$alt" != "0" && "$alt" != "0.0" ]] && {
            cmd+=(-GPSAltitude="$alt")
            cmd+=(-GPSAltitudeRef="$([[ $(echo "$alt >= 0" | bc -l) -eq 1 ]] && echo 0 || echo 1)")  # 0=above,1=below sea
        }
        [[ "$lat_span" != "0" ]] && cmd+=(-GPSLatitudeSpan="$lat_span")
        [[ "$lon_span" != "0" ]] && cmd+=(-GPSLongitudeSpan="$lon_span")
    fi
    
    # Execute if metadata available
    if [ ${#cmd[@]} -gt 3 ]; then
        "${EXIFTOOL}" "${cmd[@]}"
    else
        echo "  → No metadata to embed"
    fi
done

echo "Processing complete! Originals saved as .bak files."

