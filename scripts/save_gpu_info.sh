#!/bin/bash
#
# Script to save all /proc/gpu%d directory contents to files.
# This avoids conflicts with existing symlinks by creating a separate directory.
#

set -e

# Default output directory with timestamp
DEFAULT_OUTPUT_DIR="gpu_snapshots_$(date +%Y%m%d_%H%M%S)"

# Function to display usage
usage() {
    echo "Usage: $0 [output_directory]"
    echo ""
    echo "Saves contents of /proc/gpu* directories to the specified output directory."
    echo "If no directory is specified, uses: $DEFAULT_OUTPUT_DIR"
    echo ""
    echo "Examples:"
    echo "  $0                          # Save to timestamped directory"
    echo "  $0 my_gpu_snapshots         # Save to specific directory"
    exit 1
}

# Parse command line arguments
if [ $# -gt 1 ]; then
    usage
fi

OUTPUT_DIR="${1:-$DEFAULT_OUTPUT_DIR}"

# Check if output directory already exists
if [ -e "$OUTPUT_DIR" ]; then
    echo "Error: Output directory '$OUTPUT_DIR' already exists!"
    echo "Please specify a different directory or remove the existing one."
    exit 1
fi

echo "GPU Information Saver"
echo "====================="
echo "Output directory: $OUTPUT_DIR"
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

echo "Found ${#gpu_dirs[@]} GPU directory(ies)"

# Create output directory
mkdir -p "$OUTPUT_DIR"
echo "Created output directory: $OUTPUT_DIR"

total_files_saved=0

for gpu_dir in "${gpu_dirs[@]}"; do
    if [ ! -d "$gpu_dir" ]; then
        continue
    fi
    
    gpu_id="${gpu_dir#/proc/gpu}"
    gpu_output_dir="$OUTPUT_DIR/gpu$gpu_id"
    
    echo ""
    echo "=== Processing GPU $gpu_id ==="
    echo "Source: $gpu_dir"
    echo "Destination: $gpu_output_dir"
    
    # Create GPU-specific output directory
    mkdir -p "$gpu_output_dir"
    
    # List all files in the GPU directory
    files_saved=0
    for file in "$gpu_dir"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            output_file="$gpu_output_dir/$filename"
            
            # Try to read and save the file content
            if [ -r "$file" ]; then
                # Copy the file content
                if cp "$file" "$output_file" 2>/dev/null; then
                    echo "  Saved: $filename"
                    files_saved=$((files_saved + 1))
                    total_files_saved=$((total_files_saved + 1))
                else
                    echo "  Failed to save: $filename (copy error)"
                fi
            else
                echo "  Skipped: $filename (permission denied)"
                # Create a placeholder file with permission info
                echo "# Permission denied to read source file" > "$output_file"
            fi
        fi
    done
    
    if [ $files_saved -eq 0 ]; then
        echo "  No files could be saved from this GPU directory"
        # Remove empty directory
        rmdir "$gpu_output_dir" 2>/dev/null || true
    else
        echo "  Saved $files_saved file(s) for GPU $gpu_id"
    fi
done

echo ""
echo "=== Summary ==="
echo "Total files saved: $total_files_saved"
echo "Output directory: $OUTPUT_DIR"
echo ""
echo "All GPU information has been saved successfully!"
echo "Note: This avoids conflicts with any existing symlinks in the current directory."
