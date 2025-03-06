#!/bin/bash
# Get the zip filename, dataset name and tsv file from command line arguments
if [ $# -ne 3 ]; then
    echo "Usage: $0 <inputzipfile> <tsvfile> <datasetname>"
    exit 1
fi

ZIP_FILE="$1"
TSV_FILE="$2"
DATASET_NAME="$3"
TEMP_DIR="temp_unzip"
OUTPUT_DIR="${DATASET_NAME}"

# Create temp directory and unzip
echo "Unzipping $ZIP_FILE..."
mkdir -p "$TEMP_DIR"
unzip "$ZIP_FILE" -d "$TEMP_DIR"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Create CSV file
echo "Creating dataset.csv..."
# Skip header line and process TSV into CSV format
tail -n +2 "$TSV_FILE" | while IFS=$'\t' read -r id sentence; do
    echo "session_9_${id}|${sentence}" >> ${DATASET_NAME}.csv
done

# Loop through all mp3 files in the unzipped directory and its subdirectories
find "$TEMP_DIR" -name "*.mp3" -type f | while read file; do
    # Extract just the session_9_XXXX part using regex
    new_name=$(echo "$file" | grep -o 'session_[0-9]\+_[0-9]\+')
    
    # Add .mp3 extension back
    new_name="${new_name}.mp3"
    
    # Copy and rename the file to new directory
    cp "$file" "$OUTPUT_DIR/$new_name"
    echo "Processed: $file -> $OUTPUT_DIR/$new_name"
done

# Create zip file
zip -r "${OUTPUT_DIR}.zip" "$OUTPUT_DIR"
echo "Created zip file: ${OUTPUT_DIR}.zip"

# Cleanup temp directory
rm -rf "$TEMP_DIR"
echo "Cleaned up temporary files"