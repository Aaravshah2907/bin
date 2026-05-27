#!/usr/bin/env bash

# =========================================================
# OCR Timestamp Recovery Script
# =========================================================
#
# Requirements:
#   brew install tesseract imagemagick exiftool
#   pip install easyocr opencv-python
#
# Usage:
#   ./ocr_recover.sh ~/Documents/Temp/GP-Failed
#
# =========================================================

set -euo pipefail

FAILED_DIR="${1:-$HOME/Documents/Temp/GP-Failed}"
UPLOAD_DIR="$HOME/Documents/Temp/GP-Upload"

mkdir -p "$UPLOAD_DIR"

# ---------------------------------------------------------
# Temporary Python OCR helper
# ---------------------------------------------------------

OCR_SCRIPT="$(mktemp).py"

cat > "$OCR_SCRIPT" << 'PYTHON'
import os
os.environ["KMP_DUPLICATE_LIB_OK"] = "TRUE"

import sys
import cv2
import easyocr
import re

reader = easyocr.Reader(['en'], gpu=False)

image_path = sys.argv[1]

img = cv2.imread(image_path)

if img is None:
    sys.exit(1)

h, w = img.shape[:2]

# Bottom-right crop
crop = img[int(h*0.82):h, int(w*0.65):w]

# Upscale heavily
crop = cv2.resize(
    crop,
    None,
    fx=6,
    fy=6,
    interpolation=cv2.INTER_CUBIC
)

results = reader.readtext(
    crop,
    detail=0,
    paragraph=False
)

text = " ".join(results)

# ---------------------------------------------------------
# Date extraction
# ---------------------------------------------------------

patterns = [

    # 04 05 2012
    r'(\d{2})\D+(\d{2})\D+(20\d{2})',

    # 2012 05 04
    r'(20\d{2})\D+(\d{2})\D+(\d{2})'
]

for p in patterns:

    m = re.search(p, text)

    if m:

        g = m.groups()

        # DD MM YYYY
        if len(g[0]) == 2:
            d, mo, y = g
        else:
            y, mo, d = g

        try:

            d = int(d)
            mo = int(mo)
            y = int(y)

            if (
                1 <= d <= 31 and
                1 <= mo <= 12 and
                1990 <= y <= 2035
            ):

                print(f"{y:04d}:{mo:02d}:{d:02d} 00:00:00")
                sys.exit(0)

        except:
            pass

sys.exit(1)
PYTHON

# =========================================================
# MAIN LOOP
# =========================================================

find "$FAILED_DIR" -type f | while read -r file; do

    ext="${file##*.}"
    ext_lower="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"

    case "$ext_lower" in
        jpg|jpeg|png|heic|heif|tif|tiff)
            ;;
        *)
            continue
            ;;
    esac

    echo "--------------------------------------------------"
    echo "Processing: $(basename "$file")"

    OCR_DATE=$(python3 "$OCR_SCRIPT" "$file" 2>/dev/null || true)

    if [[ -n "$OCR_DATE" ]]; then

        echo "[OCR FOUND] $OCR_DATE"

        exiftool \
            "-AllDates=$OCR_DATE" \
            "-overwrite_original" \
            "$file" > /dev/null

        VERIFY=$(exiftool -s -s -s -DateTimeOriginal "$file")

        if [[ "$VERIFY" == "$OCR_DATE" ]]; then

            echo "[UPDATED] EXIF written"

            mv "$file" "$UPLOAD_DIR"/

            echo "[MOVED] -> GP-Upload"

        else

            echo "[FAILED] EXIF verification failed"

        fi

    else

        echo "[NO TEXT FOUND]"

    fi

done

rm -f "$OCR_SCRIPT"

echo
echo "========================================"
echo "OCR recovery complete."
echo "========================================"
