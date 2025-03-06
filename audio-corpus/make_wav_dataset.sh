#!/bin/bash

# Get the zip filename from command line arguments
if [ $# -ne 1 ]; then
    echo "Usage: $0 <inputzipfile>"
    exit 1
fi

ZIP_FILE="$1"
DATASET_NAME=$(basename "$ZIP_FILE" .zip)
TEMP_DIR="temp_unzip"

# Clean up any existing temp directory first
rm -rf "$TEMP_DIR"

# Create directories
echo "Creating directories..."
mkdir -p "$DATASET_NAME"
mkdir -p "$TEMP_DIR"

# Unzip with full paths
echo "Unzipping $ZIP_FILE..."
unzip -j "$ZIP_FILE" -d "$TEMP_DIR"  # -j junk paths, puts all files in temp_dir

# Convert all MP3s to WAV
echo "Converting MP3 files to 16kHz WAV..."
for mp3_file in "$TEMP_DIR"/*.mp3; do
    if [ -f "$mp3_file" ]; then  # check if file exists
        filename=$(basename "$mp3_file" .mp3)
        echo "Converting: $mp3_file"
        ffmpeg -i "$mp3_file" -ar 16000 "$DATASET_NAME/${filename}.wav" -y
    fi
done

# Cleanup temp directory
rm -rf "$TEMP_DIR"
echo "Cleaned up temporary files"

echo "Processing complete! WAV files are in $DATASET_NAME/"