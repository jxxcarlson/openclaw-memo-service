#!/bin/bash

# Setup script to install cron job for telegram memo poller

set -e

REPO_DIR="/Users/carlson/.openclaw/workspace"
MEMOS_DIR="$REPO_DIR/memos"
SCRIPT="$MEMOS_DIR/telegram-memo-poller.js"

# Check if script exists
if [ ! -f "$SCRIPT" ]; then
  echo "❌ Error: $SCRIPT not found"
  exit 1
fi

# Get current cron jobs
CURRENT_CRON=$(crontab -l 2>/dev/null || echo "")

# Check if already installed
if echo "$CURRENT_CRON" | grep -q "telegram-memo-poller"; then
  echo "⚠️  Cron job already exists. Skipping installation."
  echo "To reinstall, remove it manually with: crontab -e"
  exit 0
fi

# Add new cron job
NEW_CRON=$(echo "$CURRENT_CRON"; echo "*/2 * * * * cd $MEMOS_DIR && node telegram-memo-poller.js")

# Install cron job
echo "$NEW_CRON" | crontab -

echo "✅ Cron job installed successfully"
echo "   Interval: Every 2 minutes"
echo "   Command: cd $MEMOS_DIR && node telegram-memo-poller.js"
echo ""
echo "Verify with: crontab -l"
echo "View logs with: tail -f $MEMOS_DIR/.poll.log"
