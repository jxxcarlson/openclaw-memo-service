#!/bin/bash

# Audio transcription cron wrapper
# Runs transcribe.sh every 15 minutes, logs output, sends Telegram notification

set -o pipefail

WORKSPACE="/Users/carlson/.openclaw/workspace"
MEMOS_DIR="$WORKSPACE/memos"
INBOX_DIR="$MEMOS_DIR/audio-inbox"
LOG_FILE="$MEMOS_DIR/transcribe.log"
TRANSCRIBE_SCRIPT="$MEMOS_DIR/transcribe.sh"

# Initialize log file if it doesn't exist
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
fi

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') — $1" >> "$LOG_FILE"
}

# Start
log "Processing started"

# Check if transcribe.sh exists
if [ ! -f "$TRANSCRIBE_SCRIPT" ]; then
    log "ERROR: transcribe.sh not found at $TRANSCRIBE_SCRIPT"
    exit 1
fi

# Check if inbox directory exists
if [ ! -d "$INBOX_DIR" ]; then
    log "ERROR: audio-inbox directory not found at $INBOX_DIR"
    exit 1
fi

# Count files in inbox before processing
initial_inbox_count=$(find "$INBOX_DIR" -maxdepth 1 -type f | wc -l)

if [ "$initial_inbox_count" -eq 0 ]; then
    log "No files to process"
    exit 0
fi

log "Found $initial_inbox_count file(s) in inbox"

# Run transcription script and capture output
transcribe_output=$("$TRANSCRIBE_SCRIPT" 2>&1)
transcribe_exit_code=$?

# Log transcription output
while IFS= read -r line; do
    log "  $line"
done <<< "$transcribe_output"

if [ $transcribe_exit_code -ne 0 ]; then
    log "⚠ Transcription completed with errors (exit code: $transcribe_exit_code)"
    exit 0  # Non-fatal: don't stop the cron job
fi

# Count files processed by comparing inbox before and after
final_inbox_count=$(find "$INBOX_DIR" -maxdepth 1 -type f | wc -l)
archive_count=$((initial_inbox_count - final_inbox_count))

log "✓ Success ($archive_count files processed)"

# Send Telegram notification on success
send_telegram_notification() {
    local message="$1"
    local timestamp=$(date '+%H:%M')

    # Read Telegram bot token from environment or config
    # This assumes your existing telegram-bot.js or config has the token
    local telegram_token="${TELEGRAM_BOT_TOKEN}"
    local telegram_chat_id="${TELEGRAM_CHAT_ID}"

    if [ -z "$telegram_token" ] || [ -z "$telegram_chat_id" ]; then
        log "⚠ Telegram credentials not configured, skipping notification"
        return 1
    fi

    # Format message
    local telegram_message="✓ Transcription ($timestamp)%0A${message}"

    # Send via Telegram Bot API
    local curl_output
    curl_output=$(curl -s -X POST \
        "https://api.telegram.org/bot${telegram_token}/sendMessage" \
        -d "chat_id=${telegram_chat_id}&text=${telegram_message}" 2>&1)

    if [ $? -eq 0 ]; then
        log "Telegram notification sent"
    else
        log "⚠ Telegram notification failed: $curl_output"
        return 1
    fi
}

# Send notification
if [ $archive_count -gt 0 ]; then
    notification_msg="${archive_count} files processed and added to memo"
    send_telegram_notification "$notification_msg"
fi
