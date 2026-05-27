#!/bin/bash

# Voice memo transcription service
# Watches audio-inbox/, transcribes with Whisper, adds to daily memo

INBOX="/Users/carlson/.openclaw/workspace/memos/audio-inbox"
ARCHIVE="/Users/carlson/.openclaw/workspace/memos/audio-archive"
MEMOS="/Users/carlson/.openclaw/workspace/memos"

# Get today's date
TODAY=$(date +%Y-%m-%d)
MEMO_FILE="$MEMOS/$TODAY.md"

# Check if memo file exists; create if not
if [ ! -f "$MEMO_FILE" ]; then
    echo "# $TODAY" > "$MEMO_FILE"
fi

# Process all audio files in inbox
for audio_file in "$INBOX"/*; do
    if [ -f "$audio_file" ]; then
        filename=$(basename "$audio_file")
        echo "Transcribing: $filename"
        
        # Transcribe with Whisper to text format
        whisper "$audio_file" --model medium --output_format txt --output_dir "$INBOX" --verbose False
        
        # Get the transcribed text (whisper outputs filename_without_ext.txt)
        base="${audio_file%.*}"
        base_name=$(basename "$base")
        txt_file="$INBOX/${base_name}.txt"
        
        if [ -f "$txt_file" ]; then
            # Get current time
            TIMESTAMP=$(date +%H:%M)
            
            # Read transcript
            transcript=$(cat "$txt_file")
            
            # Add to memo file
            echo "" >> "$MEMO_FILE"
            echo "## $TIMESTAMP — Voice Memo" >> "$MEMO_FILE"
            echo "" >> "$MEMO_FILE"
            echo "$transcript" >> "$MEMO_FILE"
            
            # Clean up
            rm "$txt_file"
            mv "$audio_file" "$ARCHIVE/$filename"
            
            echo "✓ Added to $TODAY.md and archived"
        else
            echo "⚠ Transcription failed for $filename"
        fi
    fi
done

echo "Done."
