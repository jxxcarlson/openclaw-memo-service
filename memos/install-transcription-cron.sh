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
