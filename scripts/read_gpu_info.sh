#!/bin/bash
#
# Script to read all /proc/gpu%d directories and display their contents.
# This bash script scans for GPU information in the /proc filesystem.
#

echo "GPU Information Reader"
echo "====================="
echo "Scanning for GPU information in /proc filesystem..."

# Find all /proc/gpu* directories
gpu_dirs=(/proc/gpu*)

if [ ${#gpu_dirs[@]} -eq 1 ] && [ ! -d "${gpu_dirs[0]}" ]; then
    echo "No /proc/gpu* directories found."
    echo "This may indicate that:"
    echo "1. The nvdebug kernel module is not loaded"
    echo "2. Your system doesn't have NVIDIA GPUs with this feature"
    echo "3. The /proc interface for GPUs is not available on this system"
    exit 0
fi

echo "Found ${#gpu_dirs[@]} GPU directory(ies):"

for gpu_dir in "${gpu_dirs[@]}"; do
    if [ ! -d "$gpu_dir" ]; then
        continue
    fi
    
    gpu_id="${gpu_dir#/proc/gpu}"
    echo ""
    echo "=== GPU $gpu_id ==="
    echo "Directory: $gpu_dir"
    
    # List all files in the GPU directory
    if files=("$gpu_dir"/*) && [ -e "${files[0]}" ]; then
        echo "  Files:"
        for file in "${gpu_dir}"/*; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                echo -n "    $filename: "
                
                # Try to read the file content
                if [ -r "$file" ]; then
                    # Read first line or limited content to avoid huge outputs
                    head_content=$(head -c 200 "$file" 2>/dev/null | tr -d '\000-\011\013-\037' | sed 's/\\/\\\\/g')
                    if [ -n "$head_content" ]; then
                        echo "$head_content"
                    else
                        echo "(binary or empty content)"
                    fi
                else
                    echo "(permission denied)"
                fi
            fi
        done
    else
        echo "  No files found in this directory"
    fi
done

echo ""
echo "Scan completed."
