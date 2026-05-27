#!/usr/bin/env python3

import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

# =========================================================
# CONFIG
# =========================================================

UPLOAD_DIR = Path.home() / "Documents/Temp/GP-Upload"
MATCHED_DIR = Path.home() / "Documents/Temp/GP-Matched"
FAILED_DIR = Path.home() / "Documents/Temp/GP-Failed"

SUPPORTED_EXTENSIONS = {
    "jpg", "jpeg", "png", "heic", "heif",
    "tif", "tiff", "gif"
}

UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
MATCHED_DIR.mkdir(parents=True, exist_ok=True)
FAILED_DIR.mkdir(parents=True, exist_ok=True)

# =========================================================
# FILENAME DATE PARSING
# =========================================================

DATE_PATTERNS = [

    # 20150729_215344
    re.compile(
        r'(20\d{2})([01]\d)([0-3]\d)[ _-]?([0-2]\d)([0-5]\d)([0-5]\d)'
    ),

    # 2024-01-25 14.30.00
    re.compile(
        r'(20\d{2})[-_]?([01]\d)[-_]?([0-3]\d)[ _-]?([0-2]\d)[.:_-]?([0-5]\d)[.:_-]?([0-5]\d)'
    ),

    # IMG-20210503-WA0001
    re.compile(
        r'(20\d{2})([01]\d)([0-3]\d)'
    )
]


def extract_date_from_filename(filename):

    stem = Path(filename).stem

    for pattern in DATE_PATTERNS:

        match = pattern.search(stem)

        if match:

            groups = match.groups()

            if len(groups) == 6:
                y, mo, d, h, mi, s = groups
            else:
                y, mo, d = groups
                h, mi, s = "00", "00", "00"

            return f"{y}:{mo}:{d} {h}:{mi}:{s}"

    return None

# =========================================================
# EXIF HELPERS
# =========================================================


def run_command(cmd):

    try:

        result = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )

        return result.stdout.strip()

    except Exception:
        return ""


def get_existing_exif_date(file_path):

    date = run_command([
        "exiftool",
        "-s",
        "-s",
        "-s",
        "-DateTimeOriginal",
        str(file_path)
    ])

    # STRICT validation
    # Reject empty/malformed values

    if not date:
        return None

    if ":" not in date:
        return None

    if len(date) < 19:
        return None

    return date[:19]


def write_exif_date(file_path, date_string):

    result = subprocess.run(
        [
            "exiftool",
            f"-AllDates={date_string}",
            "-overwrite_original",
            str(file_path)
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )

    return result.returncode == 0

# =========================================================
# FILE PROCESSING
# =========================================================


def process_file(file_path):

    extension = file_path.suffix.lower().replace(".", "")

    if extension not in SUPPORTED_EXTENSIONS:
        print(f"[SKIPPED] Unsupported: {file_path}")
        return

    filename_date = extract_date_from_filename(file_path.name)

    # -----------------------------------------------------
    # FAILED: No parsable filename date
    # -----------------------------------------------------

    if not filename_date:

        print(f"[FAILED] No parsable filename date:")
        print(f"         {file_path.name}")

        shutil.move(
            str(file_path),
            FAILED_DIR / file_path.name
        )

        return

    existing_date = get_existing_exif_date(file_path)

    # -----------------------------------------------------
    # MATCHED: Existing EXIF already correct
    # -----------------------------------------------------

    if existing_date:

        if existing_date == filename_date:

            print(f"[MATCHED] {file_path.name}")
            print(f"          EXIF already correct")

            shutil.move(
                str(file_path),
                MATCHED_DIR / file_path.name
            )

            return

    # -----------------------------------------------------
    # UPDATE EXIF
    # -----------------------------------------------------

    success = write_exif_date(
        file_path,
        filename_date
    )

    if success:

        # Verify actual write
        verified_date = get_existing_exif_date(file_path)

        if verified_date == filename_date:

            print(f"[UPDATED] {file_path.name}")
            print(f"          -> {filename_date}")

            shutil.move(
                str(file_path),
                UPLOAD_DIR / file_path.name
            )

            return

    # -----------------------------------------------------
    # FAILED
    # -----------------------------------------------------

    print(f"[FAILED] Could not write EXIF:")
    print(f"         {file_path.name}")

    shutil.move(
        str(file_path),
        FAILED_DIR / file_path.name
    )

# =========================================================
# MAIN
# =========================================================


def main():

    if len(sys.argv) < 2:

        print(
            "Usage: python3 media_metadata_sorter.py "
            "<dir1> [dir2 ...]"
        )

        sys.exit(1)

    for directory in sys.argv[1:]:

        directory_path = Path(directory)

        if not directory_path.exists():

            print(f"[ERROR] Directory not found:")
            print(f"        {directory}")

            continue

        print("\n========================================")
        print(f"Processing: {directory}")
        print("========================================")

        for root, _, files in os.walk(directory):

            for file in files:

                if file.endswith("_original"):
                    continue

                full_path = Path(root) / file

                try:
                    process_file(full_path)

                except Exception as e:

                    print(f"[ERROR] {full_path}")
                    print(f"        {e}")

# =========================================================

if __name__ == "__main__":
    main()
