# Telegram Memo Polling Integration Design

**Date:** 2026-05-27  
**Status:** Approved  
**Approach:** Simple polling script + cron  

## Overview

Integrate Telegram messaging with the memo system via a scheduled polling job. When users send messages to a dedicated Telegram bot, the polling script fetches them, pipes them through the memo handler, and sends back confirmation messages.

## Use Case

Users can dictate or type memos from their iPhone while away from their computer. When the computer comes back online or during regular polling cycles, all accumulated messages are retrieved and processed without loss.

## Architecture

```
Telegram Server
    ↓ (getUpdates API call)
Polling Script (runs via cron every 1-2 min)
    ├─ Check .poll-state.json for last message ID
    ├─ Fetch new messages from Telegram
    ├─ For each message:
    │  ├─ Pipe to handler (telegram-memo-handler.js)
    │  ├─ Send confirmation back to Telegram
    │  └─ Log success
    ├─ Update .poll-state.json with latest ID
    └─ Handle errors: log + alert if serious
```

## Components

### 1. Polling Script (`telegram-memo-poller.js`)

Main executable that runs on a cron schedule.

**Responsibilities:**
- Read config from `telegram-memo.config.js`
- Restore last message ID from `.poll-state.json`
- Call Telegram's `getUpdates(offset=lastId+1)` to fetch new messages only
- For each message received:
  - Extract message text and sender info
  - Pipe message text to `telegram-memo-handler.js` via stdin
  - Capture handler output/success
  - Send confirmation message back to user via Telegram `sendMessage()` API
  - Log the transaction
  - Update state with new message ID
- Handle errors: log, increment counter, alert if threshold exceeded
- Update `.poll-state.json` with latest message ID and timestamp
- Exit cleanly

**Language:** Node.js  
**Dependencies:** `node-telegram-bot-api` (or equivalent) for Telegram API calls

### 2. Configuration File (`telegram-memo.config.js`)

Centralized config for easy customization without code changes.

**Fields:**
```javascript
{
  TELEGRAM_BOT_TOKEN: "your-bot-token-from-botfather",
  POLL_INTERVAL_SECONDS: 60,  // How often cron runs
  CHAT_IDS: ["12345678"],     // User/group IDs to listen to
  ERROR_ALERT_THRESHOLD: 3,   // Alert after N failures
  HANDLER_SCRIPT: "./telegram-memo-handler.js",
  LOG_FILE: "./.poll.log",
  STATE_FILE: "./.poll-state.json"
}
```

All values can be changed without modifying the script.

### 3. State File (`.poll-state.json`)

Persistent state tracking across cron runs. Enables resumption after gaps (laptop offline, cron stopped, etc.).

**Format:**
```json
{
  "lastMessageId": 12345,
  "lastPolledAt": "2026-05-27T06:45:00Z",
  "errorCount": 0
}
```

**Behavior:**
- Initialized to `{ lastMessageId: 0, errorCount: 0 }` on first run
- Updated after each poll (even if no messages)
- Error count incremented on failure, reset on success
- Used as offset for next poll: `getUpdates(offset=lastMessageId+1)`

### 4. Cron Job

Runs the polling script at regular intervals. Example:

```bash
*/2 * * * * cd /Users/carlson/.openclaw/workspace/memos && node telegram-memo-poller.js
```

This runs every 2 minutes. Interval is configurable via `POLL_INTERVAL_SECONDS`.

## Data Flow

### Happy Path (Message Received)

1. User sends message to Telegram bot `jxc_memo` (or similar)
2. Message sits on Telegram server until next poll
3. Cron triggers → `telegram-memo-poller.js` starts
4. Poller reads `.poll-state.json` → gets `lastMessageId`
5. Calls `getUpdates(offset=lastMessageId+1)`
6. Telegram returns: `[ { message_id: 12346, text: "/topic Bug fix\n..." } ]`
7. For the message:
   - Extract text: `"/topic Bug fix\n..."`
   - Run handler: `echo "/topic Bug fix\n..." | node telegram-memo-handler.js`
   - Handler appends to `2026-05-27.md`, outputs: `Added to 2026-05-27.md: Bug fix`
   - Poller sends response: `sendMessage(chat_id, "✅ Memo saved: Bug fix")`
   - Log: `2026-05-27 06:47:15 INFO Processed message 12346 from user 123456: Bug fix`
8. Update state: `{ lastMessageId: 12346, lastPolledAt: "...", errorCount: 0 }`
9. Exit

### Offline Scenario

1. User sends 3 messages while laptop is off
2. All 3 queue on Telegram servers
3. Laptop wakes up, cron runs
4. Poller calls `getUpdates(offset=lastId+1)`
5. Telegram returns all 3 messages
6. Poller processes all 3, sends 3 confirmations
7. No messages lost

### Error Handling

**Transient errors** (network timeout, Telegram API temporary outage):
- Log: `ERROR: Failed to poll Telegram: Connection timeout`
- Increment `errorCount` in state
- Exit normally → next cron run tries again

**Repeated errors** (threshold exceeded):
- If `errorCount >= ERROR_ALERT_THRESHOLD`:
  - Send Telegram message: `"⚠️ Memo polling has failed 3+ times. Check logs: memos/.poll.log"`
  - Log the alert
  - Exit
- Next successful poll resets `errorCount` to 0

**Validation errors** (bad token, user not found):
- Log error with details
- Increment counter
- Alert if threshold hit
- Do NOT crash; let cron retry

## Configuration Management

**Initial setup:**
1. User creates `telegram-memo.config.js` with bot token from BotFather
2. Sets `CHAT_IDS` to their user ID
3. Sets `POLL_INTERVAL_SECONDS` (default 60)

**Runtime customization:**
- Edit `telegram-memo.config.js` to change interval, add chat IDs, adjust alert threshold
- No restart needed; next cron run picks up changes
- All values read fresh on each execution

## Logging

**Log file:** `memos/.poll.log`

**Format:** `YYYY-MM-DD HH:MM:SS LEVEL Message`

**Examples:**
```
2026-05-27 06:45:15 INFO Polling started. Last message ID: 12345
2026-05-27 06:45:16 INFO Found 2 new messages
2026-05-27 06:45:17 INFO Processed message 12346 from 123456: Testing the handler
2026-05-27 06:45:18 INFO Sent confirmation to chat 123456
2026-05-27 06:45:19 INFO State updated: lastMessageId=12346, errorCount=0
2026-05-27 06:45:20 INFO Poll completed successfully
2026-05-27 06:47:15 ERROR Failed to poll Telegram: ECONNREFUSED. Retry count: 1/3
2026-05-27 06:49:15 ALERT Polling failed 3 times. User notified.
```

**Rotation:** Daily (old logs archived, new file starts each day)

## Security Considerations

- Bot token stored in `telegram-memo.config.js` (exclude from git)
- Only processes messages from whitelisted `CHAT_IDS`
- No credentials logged; errors scrubbed of sensitive info
- Rate limiting: cron interval prevents API spam

## Testing Strategy

1. **Unit tests** for state file I/O, config parsing, message parsing
2. **Integration test** with real Telegram bot:
   - Send test message
   - Verify memo file updated
   - Verify confirmation sent
   - Check state file updated
3. **Offline test:** Send messages while poller disabled, then enable and verify all caught
4. **Error test:** Simulate network failure, verify alert sent after threshold

## Success Criteria

✅ Messages sent to Telegram bot are captured in memo file  
✅ Confirmation sent back to user immediately  
✅ No messages lost when computer offline  
✅ Polling interval is configurable  
✅ Errors logged and alerted appropriately  
✅ State persists across reboots and cron interruptions  
✅ Cron can be set up without manual intervention  

## Dependencies

- Node.js (already installed)
- `node-telegram-bot-api` npm package
- Telegram bot created via BotFather (token obtained)
- Existing `telegram-memo-handler.js` (already tested)

## Future Enhancements (Out of Scope)

- Support for media (photos, voice notes) 
- Tag extraction from messages
- Multi-user support (different CHAT_IDs, separate memo streams)
- Web dashboard for polling status
- Message deduplication
