# Audio Transcription Automation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Set up a LaunchAgent that runs a wrapper script every 15 minutes to automatically transcribe audio files and send Telegram notifications.

**Architecture:** A wrapper script (`transcribe-cron.sh`) calls the existing `transcribe.sh`, captures output, logs results, and sends Telegram notifications. macOS LaunchAgent schedules this to run every 15 minutes.

**Tech Stack:** Bash, macOS LaunchAgent (launchd), Whisper (existing), Telegram Bot API (existing integration)

---

## File Structure

```
memos/
  transcribe-cron.sh              # New: Wrapper script for cron execution
  install-transcription-cron.sh   # New: Setup helper
  transcribe.sh                   # Existing: Unchanged
  transcribe.log                  # Created automatically on first run
  audio-inbox/                    # Existing: Input directory
  audio-archive/                  # Existing: Processed files archive

~/Library/LaunchAgents/
  com.carlson.memo-transcribe.plist  # New: System scheduler configuration
```

---

## Task 1: Create Wrapper Script

**Files:**
- Create: `memos/transcribe-cron.sh`

This script orchestrates the transcription workflow, handles logging, and sends Telegram notifications.

- [ ] **Step 1: Create the wrapper script with setup and validation**

```bash
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

# Count files in inbox
file_count=$(find "$INBOX_DIR" -maxdepth 1 -type f | wc -l)

if [ "$file_count" -eq 0 ]; then
    log "No files to process"
    exit 0
fi

log "Found $file_count file(s) in inbox"
```

- [ ] **Step 2: Add transcription execution and error handling**

```bash
# Run transcription script and capture output
transcribe_output=$("$TRANSCRIBE_SCRIPT" 2>&1)
transcribe_exit_code=$?

# Log transcription output
echo "$transcribe_output" | while IFS= read -r line; do
    log "  $line"
done

if [ $transcribe_exit_code -ne 0 ]; then
    log "⚠ Transcription completed with errors (exit code: $transcribe_exit_code)"
    exit 0  # Non-fatal: don't stop the cron job
fi

# Count files processed (files that moved to archive)
archive_count=$(find "$MEMOS_DIR/audio-archive" -mmin -1 -type f | wc -l)

log "✓ Success ($archive_count files processed)"
```

- [ ] **Step 3: Add Telegram notification logic**

```bash
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
    curl -s -X POST \
        "https://api.telegram.org/bot${telegram_token}/sendMessage" \
        -d "chat_id=${telegram_chat_id}&text=${telegram_message}" \
        > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        log "Telegram notification sent"
    else
        log "⚠ Failed to send Telegram notification"
    fi
}

# Send notification
if [ $archive_count -gt 0 ]; then
    notification_msg="${archive_count} files processed and added to memo"
    send_telegram_notification "$notification_msg"
fi
```

- [ ] **Step 4: Make script executable and verify structure**

Run:
```bash
chmod +x /Users/carlson/.openclaw/workspace/memos/transcribe-cron.sh
```

Verify the script is readable:
```bash
head -20 /Users/carlson/.openclaw/workspace/memos/transcribe-cron.sh
```

Expected: Script header and setup logic visible.

- [ ] **Step 5: Test wrapper script directly**

First, ensure you have a test audio file. Drop a small audio file in `memos/audio-inbox/`:
```bash
# If you have a test file, copy it:
cp /path/to/test-audio.m4a /Users/carlson/.openclaw/workspace/memos/audio-inbox/test-audio.m4a
```

Run the wrapper manually:
```bash
/Users/carlson/.openclaw/workspace/memos/transcribe-cron.sh
```

Check the log file:
```bash
tail -10 /Users/carlson/.openclaw/workspace/memos/transcribe.log
```

Expected: Log entries showing the processing, transcription result, and notification attempt.

- [ ] **Step 6: Commit the wrapper script**

```bash
cd /Users/carlson/.openclaw/workspace
git add memos/transcribe-cron.sh
git commit -m "feat: add transcription cron wrapper script with logging and Telegram notifications"
```

---

## Task 2: Create LaunchAgent Plist Configuration

**Files:**
- Create: `~/Library/LaunchAgents/com.carlson.memo-transcribe.plist`

This file configures macOS to run the wrapper script every 15 minutes.

- [ ] **Step 1: Create the LaunchAgent plist file**

```bash
mkdir -p ~/Library/LaunchAgents
```

- [ ] **Step 2: Write the plist configuration**

Create `~/Library/LaunchAgents/com.carlson.memo-transcribe.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.carlson.memo-transcribe</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>/Users/carlson/.openclaw/workspace/memos/transcribe-cron.sh</string>
    </array>
    
    <key>StartInterval</key>
    <integer>900</integer>
    
    <key>StandardOutPath</key>
    <string>/Users/carlson/.openclaw/workspace/memos/transcribe-cron.log</string>
    
    <key>StandardErrorPath</key>
    <string>/Users/carlson/.openclaw/workspace/memos/transcribe-cron.log</string>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>KeepAlive</key>
    <false/>
    
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
</dict>
</plist>
```

**Note:** The `EnvironmentVariables` section includes PATH so that the script can find `whisper` and `curl`. If needed, add Telegram credentials here:
```xml
<key>TELEGRAM_BOT_TOKEN</key>
<string>YOUR_BOT_TOKEN</string>

<key>TELEGRAM_CHAT_ID</key>
<string>YOUR_CHAT_ID</string>
```

- [ ] **Step 3: Verify plist syntax**

```bash
plutil -lint ~/Library/LaunchAgents/com.carlson.memo-transcribe.plist
```

Expected: Output should say "OK".

- [ ] **Step 4: Load the LaunchAgent**

```bash
launchctl load ~/Library/LaunchAgents/com.carlson.memo-transcribe.plist
```

If you get an error about the plist already being loaded, that's fine — it means it's already active.

- [ ] **Step 5: Verify LaunchAgent is loaded**

```bash
launchctl list | grep memo-transcribe
```

Expected: Output shows `com.carlson.memo-transcribe` with a PID (if currently running) or "-" if not yet triggered.

- [ ] **Step 6: Commit the LaunchAgent configuration**

Since `~/Library/LaunchAgents/` is outside the workspace, create a reference file in the repo for documentation:

```bash
cd /Users/carlson/.openclaw/workspace
cat > memos/TRANSCRIPTION-LAUNCHAGENT.md << 'EOF'
# LaunchAgent Configuration

The transcription cron job is configured via macOS LaunchAgent.

**Location:** `~/Library/LaunchAgents/com.carlson.memo-transcribe.plist`

**Installed:** Yes (loaded via `launchctl load`)

**Schedule:** Every 15 minutes (900 seconds)

**Script:** `/Users/carlson/.openclaw/workspace/memos/transcribe-cron.sh`

## Manage the Agent

**Check status:**
```bash
launchctl list | grep memo-transcribe
```

**Unload (stop running):**
```bash
launchctl unload ~/Library/LaunchAgents/com.carlson.memo-transcribe.plist
```

**Reload (restart):**
```bash
launchctl unload ~/Library/LaunchAgents/com.carlson.memo-transcribe.plist
launchctl load ~/Library/LaunchAgents/com.carlson.memo-transcribe.plist
```

**View logs:**
```bash
tail -f /Users/carlson/.openclaw/workspace/memos/transcribe-cron.log
```

EOF

git add memos/TRANSCRIPTION-LAUNCHAGENT.md
git commit -m "docs: add LaunchAgent configuration reference"
```

---

## Task 3: Create Installation Script (Optional)

**Files:**
- Create: `memos/install-transcription-cron.sh`

This script automates the setup for future reference or reinstalls.

- [ ] **Step 1: Create the installation script**

```bash
#!/bin/bash

# Transcription cron job installer

set -e

WORKSPACE="/Users/carlson/.openclaw/workspace"
MEMOS_DIR="$WORKSPACE/memos"
WRAPPER_SCRIPT="$MEMOS_DIR/transcribe-cron.sh"
LAUNCH_AGENT_SRC="$MEMOS_DIR/com.carlson.memo-transcribe.plist"
LAUNCH_AGENT_DST="$HOME/Library/LaunchAgents/com.carlson.memo-transcribe.plist"

echo "Installing transcription cron job..."

# Verify wrapper script exists and is executable
if [ ! -f "$WRAPPER_SCRIPT" ]; then
    echo "ERROR: Wrapper script not found at $WRAPPER_SCRIPT"
    exit 1
fi

if [ ! -x "$WRAPPER_SCRIPT" ]; then
    echo "Making wrapper script executable..."
    chmod +x "$WRAPPER_SCRIPT"
fi

# Verify LaunchAgent config exists
if [ ! -f "$LAUNCH_AGENT_SRC" ]; then
    echo "ERROR: LaunchAgent config not found at $LAUNCH_AGENT_SRC"
    echo "Please create $LAUNCH_AGENT_SRC first"
    exit 1
fi

# Create LaunchAgents directory if needed
mkdir -p "$HOME/Library/LaunchAgents"

# Check if already installed
if launchctl list | grep -q "com.carlson.memo-transcribe"; then
    echo "LaunchAgent already loaded. Reloading..."
    launchctl unload "$LAUNCH_AGENT_DST" 2>/dev/null || true
fi

# Copy plist to LaunchAgents
cp "$LAUNCH_AGENT_SRC" "$LAUNCH_AGENT_DST"
echo "Installed LaunchAgent to $LAUNCH_AGENT_DST"

# Verify plist syntax
if ! plutil -lint "$LAUNCH_AGENT_DST" > /dev/null; then
    echo "ERROR: Invalid plist syntax"
    exit 1
fi

# Load the LaunchAgent
launchctl load "$LAUNCH_AGENT_DST"
echo "LaunchAgent loaded"

# Verify it's running
if launchctl list | grep -q "com.carlson.memo-transcribe"; then
    echo "✓ Installation successful"
    echo ""
    echo "Status: $(launchctl list | grep memo-transcribe)"
    echo ""
    echo "Check logs with: tail -f $MEMOS_DIR/transcribe-cron.log"
else
    echo "ERROR: LaunchAgent failed to load"
    exit 1
fi
```

- [ ] **Step 2: Make installation script executable**

```bash
chmod +x /Users/carlson/.openclaw/workspace/memos/install-transcription-cron.sh
```

- [ ] **Step 3: Test the installation script**

First, unload the existing LaunchAgent to test a fresh install:
```bash
launchctl unload ~/Library/LaunchAgents/com.carlson.memo-transcribe.plist 2>/dev/null || true
```

Now run the installer:
```bash
/Users/carlson/.openclaw/workspace/memos/install-transcription-cron.sh
```

Expected output:
```
Installing transcription cron job...
Installed LaunchAgent to ~/Library/LaunchAgents/com.carlson.memo-transcribe.plist
LaunchAgent loaded
✓ Installation successful

Status: com.carlson.memo-transcribe ...
```

Verify it loaded:
```bash
launchctl list | grep memo-transcribe
```

Expected: Shows the LaunchAgent entry.

- [ ] **Step 4: Commit the installation script**

```bash
cd /Users/carlson/.openclaw/workspace
git add memos/install-transcription-cron.sh
git commit -m "feat: add transcription cron installation script"
```

---

## Task 4: End-to-End Testing

**Files:**
- No new files; testing existing setup

Test the full system: manual audio file → automatic transcription → Telegram notification → log entry.

- [ ] **Step 1: Prepare a test audio file**

Create a small test audio file (15-30 seconds) or use an existing one. Save it to:
```bash
/Users/carlson/.openclaw/workspace/memos/audio-inbox/test-message.m4a
```

If you don't have an audio file, you can record one using the macOS Voice Memos app or the `openai-whisper` skill.

- [ ] **Step 2: Monitor the log file in real-time**

In a separate terminal, start tailing the log:
```bash
tail -f /Users/carlson/.openclaw/workspace/memos/transcribe-cron.log
```

Also tail the LaunchAgent output log:
```bash
tail -f /Users/carlson/.openclaw/workspace/memos/transcribe-cron.log
```

- [ ] **Step 3: Wait for the next 15-minute interval**

The LaunchAgent runs on a 15-minute schedule. You can trigger it manually for testing:

```bash
/Users/carlson/.openclaw/workspace/memos/transcribe-cron.sh
```

Or wait up to 15 minutes for the scheduled run.

- [ ] **Step 4: Verify transcription completed**

Check the log output:
```bash
tail -20 /Users/carlson/.openclaw/workspace/memos/transcribe.log
```

Expected:
```
2026-05-27 09:30:15 — Processing started
2026-05-27 09:30:15 — Found 1 file(s) in inbox
2026-05-27 09:30:25 — ✓ Transcription completed (exit code: 0)
2026-05-27 09:30:27 — Telegram notification sent
2026-05-27 09:30:27 — ✓ Success (1 files processed)
```

- [ ] **Step 5: Verify audio file was archived**

```bash
ls -la /Users/carlson/.openclaw/workspace/memos/audio-archive/
```

Expected: `test-message.m4a` should be present with recent timestamp.

- [ ] **Step 6: Verify transcription was added to memo**

```bash
tail -30 /Users/carlson/.openclaw/workspace/memos/2026-05-27.md
```

Expected: New section with timestamp and transcribed text:
```markdown
## HH:MM — Voice Memo

Transcribed text from the audio file...
```

- [ ] **Step 7: Verify Telegram notification**

Check your Telegram chat. You should have received a notification like:
```
✓ Transcription (09:30)
1 files processed and added to memo
```

- [ ] **Step 8: Clean up test file from archive**

```bash
rm /Users/carlson/.openclaw/workspace/memos/audio-archive/test-message.m4a
```

- [ ] **Step 9: Final commit**

```bash
cd /Users/carlson/.openclaw/workspace
git status
# Should show clean tree (or only expected changes)
```

---

## Checklist Summary

- [ ] Wrapper script created and tested
- [ ] LaunchAgent plist created and loaded
- [ ] Installation script created
- [ ] End-to-end test passed
- [ ] All changes committed

