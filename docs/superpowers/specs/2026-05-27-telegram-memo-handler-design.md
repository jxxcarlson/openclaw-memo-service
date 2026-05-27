# Telegram Memo Handler Design

**Date:** 2026-05-27  
**Scope:** Telegram message integration with daily memo system  
**Status:** Design approved

---

## Overview

Integrate OpenClaw's Telegram system with the memo service to allow users to send messages via Telegram and have them automatically appended to the daily memo file. Messages can optionally specify a topic using the `/topic` command; subsequent messages without a topic use the last-set topic.

---

## Architecture

**Data Flow:**
```
Telegram Message → OpenClaw Hook → telegram-memo-handler.js → 
  Parse message → Update memo file & session.json → Done
```

**Components:**
1. **OpenClaw Hook** — Registered trigger that invokes handler when Telegram messages arrive
2. **Handler Script** (`memos/telegram-memo-handler.js`) — Node.js script that processes messages
3. **State File** (`.session.json`) — Tracks current topic for default behavior

---

## File Structure

```
memos/
├── telegram-memo-handler.js      # Main handler script (new)
├── .session.json                  # State file (existing, updated)
├── .status.json                   # Lifecycle tracker (existing, read-only)
├── 2026-05-XX.md                  # Daily memo files (existing)
└── transcribe.sh                  # Audio handler (existing)
```

---

## Message Parsing Logic

**Input Examples:**
```
/topic Groceries
Buy milk and bread

---

Just a quick note about the meeting

---

/topic Planning
Finish the proposal
```

**Parsing Rules:**
1. If first line starts with `/topic`, extract the topic name (everything after `/topic `)
2. Remove the `/topic` line from the message
3. Remaining text becomes the content
4. If no `/topic` command, use `currentTopic` from `.session.json`
5. If no topic exists anywhere, default to "Telegram"

**Output Format (appended to memo file):**
```markdown
## HH:MM — Topic Name

Content here
```

**State Updates:**
- If `/topic` was specified, update `.session.json` with the new topic
- Always update `lastEntryTime` with current timestamp in HH:MM format

---

## File I/O & State Management

### Memo File Operations
- **Path:** `/Users/carlson/.openclaw/workspace/memos/YYYY-MM-DD.md`
- **Date:** Always today's date; create new file if doesn't exist
- **Header (if new file):** `# YYYY-MM-DD`
- **Append:** Add entry to end with proper markdown formatting
- **Whitespace:** Single blank line between entries

### State File Operations (.session.json)
```json
{
  "currentTopic": "Topic Name",
  "lastEntryTime": "HH:MM"
}
```

- **Read:** At start to get default topic
- **Update:** After processing, write updated topic and timestamp
- **Atomicity:** Use temp file + rename to prevent corruption

### Status File (.status.json)
- **Role:** Read-only reference (not modified by handler)
- **Lifecycle:** Managed by separate system

---

## Error Handling

| Error Scenario | Behavior |
|---|---|
| Memo file write fails | Log error, return failure to OpenClaw |
| `.session.json` is invalid JSON | Reset to sensible defaults (`currentTopic: "Telegram"`) |
| Empty message content | Skip entry but still update topic if `/topic` was provided |
| Missing memo directory | Create directory if it doesn't exist |
| Today's memo doesn't exist | Create new file with header |

---

## OpenClaw Hook Integration

**Hook Registration (in `openclaw.json`):**
```json
{
  "hooks": {
    "internal": {
      "entries": {
        "telegram-memo-handler": {
          "enabled": true,
          "trigger": "telegram:message",
          "script": "./memos/telegram-memo-handler.js"
        }
      }
    }
  }
}
```

**Invocation:**
- OpenClaw calls the script when a Telegram message arrives
- Message data passed via JSON on stdin (standard OpenClaw hook pattern)
- Handler processes and returns success/failure with exit code

**Dependencies:**
- Node.js built-ins only (fs, path, JSON)
- No external packages required
- No network calls needed

---

## Implementation Checklist

- [ ] Create `memos/telegram-memo-handler.js`
- [ ] Register hook in `openclaw.json`
- [ ] Test message parsing logic
- [ ] Test memo file creation and appending
- [ ] Test state file updates
- [ ] Test Telegram integration end-to-end
- [ ] Handle edge cases (empty messages, invalid JSON, etc.)

---

## Success Criteria

- ✓ Telegram messages append to daily memo file with correct timestamp
- ✓ Topic can be set via `/topic` command
- ✓ Subsequent messages without `/topic` use last-set topic
- ✓ `.session.json` tracks current topic and last entry time
- ✓ New memo files are created automatically for new days
- ✓ Handler fails gracefully on error and logs issues

---

## Notes

- This is Phase 1 of the memo system; command-based operations (MEMO-COMMANDS.md) are deferred
- Audio transcription (transcribe.sh) and Telegram text handling are independent systems
- State tracking is topic-only; tags are not persisted across messages
