import pandas as pd
import os
from datasets import Dataset, Audio
import numpy as np
from huggingface_hub import HfApi, login
import sys

def check_authentication():
    """Verify HuggingFace authentication status"""
    try:
        api = HfApi()
        # This will raise an error if not authenticated
        api.whoami()
        return True
    except Exception as e:
        print("Authentication Error: Please login to Hugging Face first.")
        print("Run: huggingface-cli login")
        print("Or set HUGGINGFACE_TOKEN environment variable")
        print(f"Error details: {str(e)}")
        return False

def prepare_marma_dataset(csv_path, audio_dir, output_file="marma_dataset.json"):
    # First check authentication
    if not check_authentication():
        sys.exit(1)
        
    print("✓ Authentication verified")
    
    # Read the CSV file
    print(f"Reading CSV from {csv_path}")
    df = pd.read_csv(csv_path, sep='|', header=None, names=['audio_file', 'text'])
    
    # Create full path for audio files
    df['audio'] = df['audio_file'].apply(lambda x: os.path.join(audio_dir, f"{x}.wav"))
    
    # Verify all audio files exist
    missing_files = df[~df['audio'].apply(os.path.exists)]['audio'].tolist()
    if missing_files:
        print(f"Warning: {len(missing_files)} audio files not found:")
        for f in missing_files[:5]:
            print(f"  - {f}")
        if len(missing_files) > 5:
            print(f"  ... and {len(missing_files)-5} more")
    
    # Keep only rows where audio files exist
    df = df[df['audio'].apply(os.path.exists)].copy()
    
    if len(df) == 0:
        print("Error: No valid audio files found!")
        sys.exit(1)
        
    print(f"✓ Found {len(df)} valid audio files")
    
    try:
        # Create the dataset
        print("Creating dataset...")
        dataset = Dataset.from_pandas(df)
        
        # Cast the audio column to Audio()
        dataset = dataset.cast_column("audio", Audio())
        
        print("✓ Dataset created successfully")
        return dataset
        
    except Exception as e:
        print(f"Error creating dataset: {str(e)}")
        sys.exit(1)

# Example usage:
if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Prepare and upload Marma speech dataset to HuggingFace')
    parser.add_argument('--csv', required=True, help='Path to CSV file')
    parser.add_argument('--audio-dir', required=True, help='Path to audio files directory')
    parser.add_argument('--repo-id', required=True, help='HuggingFace repository ID (e.g., CLEAR-Global/marma-speech-samples)')
    parser.add_argument('--private', action='store_true', help='Make the repository private')
    
    args = parser.parse_args()
    
    try:
        print(f"Preparing dataset for upload to {args.repo_id}")
        dataset = prepare_marma_dataset(args.csv, args.audio_dir)
        
        # Split into train/test
        print("Splitting into train/test sets...")
        splits = dataset.train_test_split(test_size=0.07, seed=42)
        
        # Push to hub
        print(f"Uploading to HuggingFace Hub ({args.repo_id})...")
        splits.push_to_hub(args.repo_id, private=args.private)
        
        print("\n✓ Dataset successfully uploaded to HuggingFace!")
        print(f"View your dataset at: https://huggingface.co/datasets/{args.repo_id}")
        
    except Exception as e:
        print(f"\nError during upload: {str(e)}")
        sys.exit(1)