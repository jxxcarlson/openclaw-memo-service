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
