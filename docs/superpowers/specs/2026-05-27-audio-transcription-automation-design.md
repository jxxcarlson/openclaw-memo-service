# Audio Transcription Automation Design

**Date:** 2026-05-27  
**Goal:** Automate voice memo transcription by running a cron job every 15 minutes that processes audio files, transcribes them with Whisper, and notifies via Telegram.

---

## Architecture

The system consists of three components:

1. **Wrapper Script** (`memos/transcribe-cron.sh`) — Orchestrates the transcription workflow, handles logging, and sends notifications
2. **LaunchAgent** (`~/Library/LaunchAgents/com.carlson.memo-transcribe.plist`) — macOS system scheduler that triggers the wrapper every 15 minutes
3. **Log File** (`memos/transcribe.log`) — Timestamped record of each run with status and errors

The existing `transcribe.sh` script remains unchanged and is called by the wrapper.

---

## Components

### Wrapper Script (`memos/transcribe-cron.sh`)

**Responsibilities:**
- Check if audio files exist in `memos/audio-inbox/`
- Execute `transcribe.sh` and capture output/exit code
- Log results with timestamp to `memos/transcribe.log`
- Send Telegram notification on success
- Handle errors gracefully without stopping

**Behavior:**
- Idempotent: safe to run repeatedly, even with no new files
- Non-blocking: completes within seconds, suitable for frequent execution
- All output logged; errors don't prevent subsequent runs

**Output Format for Success:**
```
✓ Transcription (HH:MM)
N files processed and added to YYYY-MM-DD.md
```

**Output Format for Error:**
```
⚠ Transcription failed (HH:MM)
Check memos/transcribe.log for details
```

### LaunchAgent (`com.carlson.memo-transcribe.plist`)

**Configuration:**
- Interval: Every 15 minutes (900 seconds)
- Path: `~/Library/LaunchAgents/com.carlson.memo-transcribe.plist`
- Executable: `/Users/carlson/.openclaw/workspace/memos/transcribe-cron.sh`
- StandardOutPath: `memos/transcribe-cron.log` (wrapper's own output)
- StandardErrorPath: `memos/transcribe-cron.log`

**Lifecycle:**
- Installed once (manual setup or via installation script)
- Automatically restarts on reboot
- Can be managed with `launchctl load/unload/list`

### Log File (`memos/transcribe.log`)

**Format:**
```
2026-05-27 15:30:15 — Processing started (3 files in inbox)
2026-05-27 15:30:22 — morning-thoughts.m4a transcribed (245 chars)
2026-05-27 15:30:28 — Added to 2026-05-27.md
2026-05-27 15:30:30 — Telegram notification sent
2026-05-27 15:30:30 — ✓ Success
```

**On Error:**
```
2026-05-27 15:45:15 — Processing started (1 file in inbox)
2026-05-27 15:45:22 — ERROR: Whisper transcription failed for recording.m4a
2026-05-27 15:45:22 — File remains in inbox for retry
2026-05-27 15:45:23 — ⚠ Partial failure (see details above)
```

---

## Data Flow

```
LaunchAgent triggers (every 15 min)
  ↓
transcribe-cron.sh starts
  ↓
Check memos/audio-inbox/ for files
  ↓
  If files exist:
    Run transcribe.sh
    Capture exit code
    Log result
    Send Telegram notification
  Else:
    Log "No files to process"
  ↓
Update memos/transcribe.log
  ↓
Exit (success or graceful error)
```

---

## Error Handling

Errors are non-fatal and logged without stopping:

- **File permission issues** → Logged, continue with next file
- **Whisper transcription fails** → File stays in inbox for next attempt, logged
- **Telegram notification fails** → Logged, but transcription is still complete
- **Memo file can't be written** → Logged, audio moved to archive anyway (prevents re-processing)

**Philosophy:** The cron job always completes successfully at the system level, but detailed status (including errors) is captured in the log file.

---

## Setup

### Manual Installation

1. Create wrapper script at `memos/transcribe-cron.sh`
2. Make it executable: `chmod +x memos/transcribe-cron.sh`
3. Create LaunchAgent plist at `~/Library/LaunchAgents/com.carlson.memo-transcribe.plist`
4. Load it: `launchctl load ~/Library/LaunchAgents/com.carlson.memo-transcribe.plist`
5. Verify: `launchctl list | grep memo-transcribe`

### Installation Script (Optional)

Provide `memos/install-transcription-cron.sh` to automate the above steps.

---

## Testing

**Manual verification:**
1. Drop an audio file in `memos/audio-inbox/`
2. Run wrapper script directly: `./memos/transcribe-cron.sh`
3. Check that file was transcribed and added to memo
4. Check `memos/transcribe.log` for entry
5. Verify Telegram notification arrived

**System verification:**
1. Confirm LaunchAgent is loaded: `launchctl list | grep memo-transcribe`
2. Check LaunchAgent output log: `tail memos/transcribe-cron.log`
3. Wait for 15-minute interval or manually trigger launchctl
4. Verify notification and log entries

---

## Dependencies

- `whisper` (OpenAI, already installed)
- `telegram-bot` (existing integration, already set up)
- `bash` (macOS standard)
- Telegram bot token (already available from existing memo system)

---

## Future Extensions

- Add configurable transcription model (currently "medium")
- Support for multiple notification channels
- Metrics/stats on transcribed files (word count, language detection)
- Archive older logs (transcribe.log rotation)
