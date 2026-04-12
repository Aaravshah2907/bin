import subprocess
import os
import sys

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

    # Find the start of the [Events] section in the second file
    event_start_index = 0
    for i, line in enumerate(lines2):
        if line.strip() == '[Events]':
            event_start_index = i + 2 
            break

    # Keep headers/styles from File 1, append only events from File 2
    merged_content = lines1 + ["\n; --- Merged Tracks ---\n"] + lines2[event_start_index:]

    with open(final_output, 'w', encoding='utf-8') as f:
        f.writelines(merged_content)

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 merge_subs.py /path/to/file.mkv")
        return

    # Use the absolute path from the command line argument
    mkv_path = os.path.abspath(sys.argv[1])
    
    if not os.path.exists(mkv_path):
        print(f"Error: File not found at {mkv_path}")
        return

    # Indices for your specific file
    idx1, idx2 = 3, 4 
    
    # Create output path in the same directory as the input
    base_path = os.path.splitext(mkv_path)[0]
    final_output = f"{base_path}.merged.ass"
    
    tmp1 = f"{base_path}.tmp1.ass"
    tmp2 = f"{base_path}.tmp2.ass"

    try:
        print(f"Processing: {os.path.basename(mkv_path)}")
        
        print("Extracting track 3 (Signs)...")
        extract_sub(mkv_path, idx1, tmp1)
        
        print("Extracting track 4 (Dialogue)...")
        extract_sub(mkv_path, idx2, tmp2)

        print("Merging into single .ass file...")
        merge_ass(tmp1, tmp2, final_output)

        print(f"Success! Created: {final_output}")

    except Exception as e:
        print(f"An error occurred: {e}")

    finally:
        # Cleanup temp files if they exist
        for tmp in [tmp1, tmp2]:
            if os.path.exists(tmp):
                os.remove(tmp)

if __name__ == "__main__":
    main()
