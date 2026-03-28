#!/usr/bin/env bash
# --- HELP UTILITY START ---
show_help() {
    cat << HELP_EOF
Usage: ${0##*/} [DIR]

Description:
    Google Photos Takeout Meta data combiner.

Options:
    -h, --help    Display this help message and exit.

HELP_EOF
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi
# --- HELP UTILITY END ---
# Embed Google Photos Takeout JSON metadata into media files (recursive)

set -euo pipefail

ROOT_DIR="${1:-.}"
KB_EXTS='jpg|jpeg|png|heic|heif|tif|tiff|gif|mp4|mov|m4v|avi|mkv|webp'

usage() {
  echo "Usage: $(basename "$0") /path/to/takeout/photos"
}

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 2; }
}

[[ -d "$ROOT_DIR" ]] || { usage; exit 1; }

need jq
need exiftool
need find
need awk
need sed
need date

echo "Processing Google Photos metadata in: $ROOT_DIR"

processed=0
skipped_no_media=0
skipped_no_data=0
errors=0

# Find a media file that matches the json base (Google Takeout patterns vary)
find_media_for_json() {
  local json_file="$1"
  local dir stem candidate

  dir="$(dirname "$json_file")"
  stem="$(basename "${json_file%.json}")"   # e.g., IMG_1234.jpg or IMG_1234

  # 1) If JSON is "IMG_1234.jpg.json" then media is "IMG_1234.jpg"
  candidate="$dir/$stem"
  if [[ -f "$candidate" && ! "$candidate" =~ \.json$ ]]; then
    printf '%s\n' "$candidate"
    return 0
  fi

  # 2) Otherwise: find any non-json file whose name starts with stem
  find "$dir" -maxdepth 1 -type f \
    ! -iname '*.json' \
    -iname "${stem}*" \
    | head -n 1
}

epoch_to_exif() {
  local ep="$1"
  [[ -n "$ep" && "$ep" != "null" ]] || return 1
  # macOS/BSD date supports -r <epoch>
  date -r "$ep" "+%Y:%m:%d %H:%M:%S" 2>/dev/null
}

abs_and_ref() {
  # prints: "<abs_value> <ref>" where ref depends on sign and axis
  # $1 = value, $2 = axis ("lat" or "lon")
  awk -v v="$1" -v axis="$2" '
    BEGIN {
      if (v == "" || v == "null") { exit 1 }
      ref = (axis=="lat" ? (v<0 ? "S":"N") : (v<0 ? "W":"E"))
      if (v < 0) v = -v
      printf "%.8f %s\n", v, ref
    }'
}

while IFS= read -r -d '' json_file; do
  media_file="$(find_media_for_json "$json_file" || true)"
  if [[ -z "${media_file:-}" || ! -f "$media_file" ]]; then
    ((skipped_no_media++)) || true
    continue
  fi

  # Extract fields (empty if missing)
  title="$(jq -r '.title // empty' "$json_file" 2>/dev/null || true)"
  desc="$(jq -r '.description // empty' "$json_file" 2>/dev/null || true)"
  photo_ts="$(jq -r '.photoTakenTime.timestamp // empty' "$json_file" 2>/dev/null || true)"
  creation_ts="$(jq -r '.creationTime.timestamp // empty' "$json_file" 2>/dev/null || true)"
  lat="$(jq -r '.geoData.latitude // .geoDataExif.latitude // empty' "$json_file" 2>/dev/null || true)"
  lon="$(jq -r '.geoData.longitude // .geoDataExif.longitude // empty' "$json_file" 2>/dev/null || true)"
  origin="$(jq -r '.googlePhotosOrigin // empty' "$json_file" 2>/dev/null || true)"

  # If nothing useful exists, skip
  if [[ -z "$title" && -z "$desc" && -z "$photo_ts" && -z "$creation_ts" && -z "$lat" && -z "$lon" && -z "$origin" ]]; then
    ((skipped_no_data++)) || true
    continue
  fi

  echo "Processing: $(basename "$media_file")"

  # Build exiftool args (options first, then tags, then file)
  args=(-overwrite_original -m)

  # Clean then set (order matters)
  args+=(-UserComment=)
  [[ -n "$origin" ]] && args+=(-UserComment="GooglePhotos: $origin")

  [[ -n "$title" ]] && args+=(-ImageDescription="$title" -ObjectName="$title")
  [[ -n "$desc"  ]] && args+=(-Description="$desc" -Caption-Abstract="$desc")

  ts=""
  if ts="$(epoch_to_exif "$photo_ts" || true)"; [[ -n "$ts" ]]; then
    args+=(-AllDates="$ts")
  else
    ts="$(epoch_to_exif "$creation_ts" || true)"
    [[ -n "$ts" ]] && args+=(-AllDates="$ts")
  fi

  # GPS (only if present and not zero-ish)
  if [[ -n "${lat:-}" && -n "${lon:-}" ]] && \
     ! awk -v a="$lat" -v b="$lon" 'BEGIN{exit !((a+0)==0 && (b+0)==0)}'; then
    # abs values + refs
    read -r lat_abs lat_ref < <(abs_and_ref "$lat" "lat" || echo "")
    read -r lon_abs lon_ref < <(abs_and_ref "$lon" "lon" || echo "")

    if [[ -n "${lat_abs:-}" && -n "${lon_abs:-}" && -n "${lat_ref:-}" && -n "${lon_ref:-}" ]]; then
      args+=(-GPSLatitude="$lat_abs" -GPSLatitudeRef="$lat_ref")
      args+=(-GPSLongitude="$lon_abs" -GPSLongitudeRef="$lon_ref")
    fi
  fi

  # Execute
  if ! exiftool "${args[@]}" "$media_file"; then
    ((errors++)) || true
    continue
  fi

  ((processed++)) || true
done < <(find "$ROOT_DIR" -type f -iname "*.json" -print0)

echo "DONE"
echo "Processed: $processed"
echo "Skipped (no media): $skipped_no_media"
echo "Skipped (no metadata): $skipped_no_data"
echo "Errors: $errors"
