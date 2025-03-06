#!/bin/bash
# Get the zip filenames, their corresponding tsv files, and dataset name
if [ $# -lt 4 ]; then
    echo "Usage: $0 <zip1> <tsv1> <zip2> <tsv2> <datasetname>"
    exit 1
fi

ZIP_FILE1="$1"
TSV_FILE1="$2"
ZIP_FILE2="$3"
TSV_FILE2="$4"
DATASET_NAME="$5"
TEMP_DIR="temp_unzip"
OUTPUT_DIR="${DATASET_NAME}"

# Create temp and output directories
echo "Creating directories..."
mkdir -p "$TEMP_DIR/session1"
mkdir -p "$TEMP_DIR/session2"
mkdir -p "$OUTPUT_DIR"

# Unzip both files into separate temp directories
echo "Unzipping $ZIP_FILE1..."
unzip "$ZIP_FILE1" -d "$TEMP_DIR/session1"
echo "Unzipping $ZIP_FILE2..."
unzip "$ZIP_FILE2" -d "$TEMP_DIR/session2"

# Create CSV file
echo "Creating combined dataset.csv..."
# Process first TSV file
tail -n +2 "$TSV_FILE1" | while IFS=$'\t' read -r id sentence; do
    echo "session_9_${id}|${sentence}" >> ${DATASET_NAME}.csv
done

# Process second TSV file
tail -n +2 "$TSV_FILE2" | while IFS=$'\t' read -r id sentence; do
    echo "session_10_${id}|${sentence}" >> ${DATASET_NAME}.csv
done

# Process files from first session
find "$TEMP_DIR/session1" -name "*.mp3" -type f | while read file; do
    new_name=$(echo "$file" | grep -o 'session_[0-9]\+_[0-9]\+')
    new_name="${new_name}.mp3"
    cp "$file" "$OUTPUT_DIR/$new_name"
    echo "Processed session 9: $file -> $OUTPUT_DIR/$new_name"
done

# Process files from second session
find "$TEMP_DIR/session2" -name "*.mp3" -type f | while read file; do
    new_name=$(echo "$file" | grep -o 'session_[0-9]\+_[0-9]\+')
    new_name="${new_name}.mp3"
    cp "$file" "$OUTPUT_DIR/$new_name"
    echo "Processed session 10: $file -> $OUTPUT_DIR/$new_name"
done

# Create zip file
zip -r "${OUTPUT_DIR}.zip" "$OUTPUT_DIR"
echo "Created combined zip file: ${OUTPUT_DIR}.zip"

# Cleanup temp directory
rm -rf "$TEMP_DIR"
echo "Cleaned up temporary files"