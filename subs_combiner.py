import subprocess
import os
import sys
import json

def get_mkv_metadata(mkv_path):
    cmd = [
        'ffprobe', '-v', 'quiet', '-print_format', 'json', 
        '-show_streams', mkv_path
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    return json.loads(result.stdout)

def extract_sub(input_mkv, index, output_name):
    subprocess.run([
        'ffmpeg', '-i', input_mkv, '-map', f'0:{index}', 
        output_name, '-y', '-loglevel', 'error'
    ], check=True)

def merge_ass(file1, file2, final_output):
    with open(file1, 'r', encoding='utf-8') as f:
        lines1 = f.readlines()
    with open(file2, 'r', encoding='utf-8') as f:
        lines2 = f.readlines()

    event_start_index = 0
    for i, line in enumerate(lines2):
        if line.strip() == '[Events]':
            event_start_index = i + 2 
            break

    merged_content = lines1 + ["\n; --- Merged Tracks ---\n"] + lines2[event_start_index:]
    with open(final_output, 'w', encoding='utf-8') as f:
        f.writelines(merged_content)

def main():
    if len(sys.argv) < 2:
        print("Usage: subs /path/to/file.mkv")
        return

    mkv_path = os.path.abspath(sys.argv[1])
    if not os.path.exists(mkv_path):
        print(f"Error: File not found at {mkv_path}")
        return

    # 1. List the tracks first
    metadata = get_mkv_metadata(mkv_path)
    sub_streams = [s for s in metadata['streams'] if s['codec_type'] == 'subtitle']
    
    print(f"\n--- Subtitle Tracks in {os.path.basename(mkv_path)} ---")
    for s in sub_streams:
        idx = s['index']
        codec = s.get('codec_name', 'unknown')
        lang = s.get('tags', {}).get('language', 'und')
        title = s.get('tags', {}).get('title', 'No Title')
        print(f"[{idx}] {lang} | {codec} | {title}")

    # 2. Ask user for selection
    try:
        idx1 = int(input("\nEnter the first index to merge (usually Signs): "))
        idx2 = int(input("Enter the second index to merge (usually Dialogue): "))
    except ValueError:
        print("Please enter valid numerical indices.")
        return

    base_path = os.path.splitext(mkv_path)[0]
    final_output = f"{base_path}.ass"
    tmp1, tmp2 = f"{base_path}.t1.ass", f"{base_path}.t2.ass"

    try:
        print("\nExtracting and merging...")
        extract_sub(mkv_path, idx1, tmp1)
        extract_sub(mkv_path, idx2, tmp2)
        merge_ass(tmp1, tmp2, final_output)
        print(f"Success! Created: {final_output}")
    finally:
        for tmp in [tmp1, tmp2]:
            if os.path.exists(tmp): os.remove(tmp)

if __name__ == "__main__":
    main()
