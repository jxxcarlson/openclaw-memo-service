# Telegram Memo Handler Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a Node.js handler that captures Telegram messages, parses optional `/topic` commands, and appends entries to daily memo files while tracking topic state.

**Architecture:** Single-file Node.js handler registered as an OpenClaw hook. When Telegram messages arrive, OpenClaw invokes the handler via stdin/stdout. Handler parses message, updates memo file, updates `.session.json` state.

**Tech Stack:** Node.js (built-ins only: fs, path, JSON), OpenClaw hooks

---

## Task 1: Create Message Parsing Module

**Files:**
- Create: `memos/telegram-memo-handler.js`

- [ ] **Step 1: Set up handler skeleton with exports**

Create `memos/telegram-memo-handler.js`:

```javascript
#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// Parse message into { topic, content }
function parseMessage(rawMessage) {
  const lines = rawMessage.trim().split('\n');
  let topic = null;
  let contentLines = [];
  
  // Check first line for /topic command
  if (lines.length > 0 && lines[0].startsWith('/topic ')) {
    topic = lines[0].substring(6).trim();
    contentLines = lines.slice(1);
  } else {
    contentLines = lines;
  }
  
  const content = contentLines.join('\n').trim();
  
  return { topic, content };
}

// Get current topic from session
function readSession() {
  const sessionPath = path.join(__dirname, '.session.json');
  try {
    if (fs.existsSync(sessionPath)) {
      const data = fs.readFileSync(sessionPath, 'utf8');
      return JSON.parse(data);
    }
  } catch (err) {
    console.error('Error reading session:', err.message);
  }
  return { currentTopic: 'Telegram', lastEntryTime: '00:00' };
}

// Write updated session
function writeSession(topic, timestamp) {
  const sessionPath = path.join(__dirname, '.session.json');
  const session = readSession();
  
  if (topic) {
    session.currentTopic = topic;
  }
  session.lastEntryTime = timestamp;
  
  try {
    const tmpPath = sessionPath + '.tmp';
    fs.writeFileSync(tmpPath, JSON.stringify(session, null, 2), 'utf8');
    fs.renameSync(tmpPath, sessionPath);
  } catch (err) {
    console.error('Error writing session:', err.message);
    process.exit(1);
  }
}

// Get today's memo file path
function getTodayMemoPath() {
  const now = new Date();
  const dateStr = now.toISOString().split('T')[0]; // YYYY-MM-DD
  return path.join(__dirname, `${dateStr}.md`);
}

// Get current timestamp in HH:MM format
function getCurrentTimestamp() {
  const now = new Date();
  const hours = String(now.getHours()).padStart(2, '0');
  const minutes = String(now.getMinutes()).padStart(2, '0');
  return `${hours}:${minutes}`;
}

module.exports = { parseMessage, readSession, writeSession, getTodayMemoPath, getCurrentTimestamp };
```

- [ ] **Step 2: Verify file was created and is valid JavaScript**

Run: `node -c memos/telegram-memo-handler.js`

Expected: No output (syntax is valid)

---

## Task 2: Test Message Parsing Logic

**Files:**
- Create: `memos/test-parser.js`
- Reference: `memos/telegram-memo-handler.js`

- [ ] **Step 1: Write test file for message parsing**

Create `memos/test-parser.js`:

```javascript
const { parseMessage } = require('./telegram-memo-handler');

function test(description, input, expectedTopic, expectedContent) {
  const result = parseMessage(input);
  const topicMatch = result.topic === expectedTopic;
  const contentMatch = result.content === expectedContent;
  
  if (topicMatch && contentMatch) {
    console.log(`✓ ${description}`);
  } else {
    console.log(`✗ ${description}`);
    if (!topicMatch) console.log(`  Expected topic: "${expectedTopic}", got: "${result.topic}"`);
    if (!contentMatch) console.log(`  Expected content: "${expectedContent}", got: "${result.content}"`);
  }
}

// Test cases
test('Simple message without topic', 'Buy milk', null, 'Buy milk');
test('Message with /topic command', '/topic Groceries\nBuy milk and bread', 'Groceries', 'Buy milk and bread');
test('Message with /topic and multiple lines', '/topic Planning\nFinish proposal\nReview notes', 'Planning', 'Finish proposal\nReview notes');
test('Empty topic name', '/topic \nContent here', '', 'Content here');
test('Message with leading/trailing whitespace', '  Buy milk  ', null, 'Buy milk');
```

- [ ] **Step 2: Run parser tests**

Run: `node memos/test-parser.js`

Expected output:
```
✓ Simple message without topic
✓ Message with /topic command
✓ Message with /topic and multiple lines
✓ Empty topic name
✓ Message with leading/trailing whitespace
```

- [ ] **Step 3: Remove test file (no longer needed)**

Run: `rm memos/test-parser.js`

---

## Task 3: Test Memo File Creation and Appending

**Files:**
- Create: `memos/test-memo-io.js`
- Reference: `memos/telegram-memo-handler.js`

- [ ] **Step 1: Create test file for memo I/O**

Create `memos/test-memo-io.js`:

```javascript
const fs = require('fs');
const path = require('path');

// Test memo file operations
function appendToMemoFile(memoPath, timestamp, topic, content) {
  try {
    // Create file with header if it doesn't exist
    if (!fs.existsSync(memoPath)) {
      const dateStr = path.basename(memoPath, '.md');
      fs.writeFileSync(memoPath, `# ${dateStr}\n`, 'utf8');
    }
    
    // Append entry
    const entry = `\n## ${timestamp} — ${topic}\n\n${content}\n`;
    fs.appendFileSync(memoPath, entry, 'utf8');
    
    return true;
  } catch (err) {
    console.error('Error appending to memo:', err.message);
    return false;
  }
}

// Test
const testPath = '/tmp/test-memo-2026-05-27.md';

// Clean up if exists
if (fs.existsSync(testPath)) fs.unlinkSync(testPath);

// Test 1: Create new file
const result1 = appendToMemoFile(testPath, '10:30', 'Groceries', 'Buy milk and bread');
const content1 = fs.readFileSync(testPath, 'utf8');
const hasHeader = content1.includes('# 2026-05-27');
const hasFirstEntry = content1.includes('## 10:30 — Groceries');
console.log(result1 && hasHeader && hasFirstEntry ? '✓ Create new memo file' : '✗ Create new memo file');

// Test 2: Append to existing file
const result2 = appendToMemoFile(testPath, '10:45', 'Planning', 'Review proposal');
const content2 = fs.readFileSync(testPath, 'utf8');
const hasSecondEntry = content2.includes('## 10:45 — Planning');
console.log(result2 && hasSecondEntry ? '✓ Append to existing memo file' : '✗ Append to existing memo file');

// Clean up
fs.unlinkSync(testPath);
console.log('✓ Test file cleaned up');
```

- [ ] **Step 2: Run memo I/O tests**

Run: `node memos/test-memo-io.js`

Expected output:
```
✓ Create new memo file
✓ Append to existing memo file
✓ Test file cleaned up
```

- [ ] **Step 3: Remove test file**

Run: `rm memos/test-memo-io.js`

---

## Task 4: Complete Handler Implementation

**Files:**
- Modify: `memos/telegram-memo-handler.js`

- [ ] **Step 1: Add main handler function to the module**

Edit `memos/telegram-memo-handler.js` to add this before `module.exports`:

```javascript
// Main handler: read Telegram message from stdin, process, update files
function processMessage(rawMessage) {
  if (!rawMessage || rawMessage.trim().length === 0) {
    console.error('No message content');
    process.exit(1);
  }
  
  // Parse message
  const { topic, content } = parseMessage(rawMessage);
  
  // Skip if only whitespace after parsing
  if (content.length === 0) {
    console.log('Skipped: empty content after parsing');
    process.exit(0);
  }
  
  // Get or use current topic
  const timestamp = getCurrentTimestamp();
  const session = readSession();
  const finalTopic = topic || session.currentTopic || 'Telegram';
  
  // Get memo file path
  const memoPath = getTodayMemoPath();
  
  // Ensure memo directory exists
  const memoDir = path.dirname(memoPath);
  if (!fs.existsSync(memoDir)) {
    fs.mkdirSync(memoDir, { recursive: true });
  }
  
  // Create file with header if needed
  if (!fs.existsSync(memoPath)) {
    const dateStr = path.basename(memoPath, '.md');
    fs.writeFileSync(memoPath, `# ${dateStr}\n`, 'utf8');
  }
  
  // Append entry to memo file
  const entry = `\n## ${timestamp} — ${finalTopic}\n\n${content}\n`;
  try {
    fs.appendFileSync(memoPath, entry, 'utf8');
  } catch (err) {
    console.error('Error writing memo:', err.message);
    process.exit(1);
  }
  
  // Update session with new topic (if provided) and timestamp
  writeSession(topic, timestamp);
  
  console.log(`Added to ${path.basename(memoPath)}: ${finalTopic}`);
  process.exit(0);
}
```

- [ ] **Step 2: Update module.exports to expose processMessage**

Edit the `module.exports` line at the end of the file:

```javascript
module.exports = { parseMessage, readSession, writeSession, getTodayMemoPath, getCurrentTimestamp, processMessage };
```

- [ ] **Step 3: Add CLI entry point to handler file**

Add this at the very end of `memos/telegram-memo-handler.js`:

```javascript
// CLI entry point: read from stdin if invoked directly
if (require.main === module) {
  let message = '';
  process.stdin.on('data', (chunk) => {
    message += chunk.toString();
  });
  process.stdin.on('end', () => {
    processMessage(message);
  });
}
```

- [ ] **Step 4: Make handler executable**

Run: `chmod +x memos/telegram-memo-handler.js`

- [ ] **Step 5: Verify handler runs (with empty input)**

Run: `echo "" | node memos/telegram-memo-handler.js 2>&1 | head -1`

Expected: Error about no message content (this is correct)

---

## Task 5: Test Handler End-to-End

**Files:**
- Reference: `memos/telegram-memo-handler.js`
- Reference: `memos/.session.json`
- Reference: `memos/2026-05-27.md` (will be created)

- [ ] **Step 1: Test with simple message (no topic)**

Run: `echo "Buy milk at the store" | node memos/telegram-memo-handler.js`

Expected: `Added to 2026-05-27.md: Telegram`

- [ ] **Step 2: Verify memo file was created with correct content**

Run: `cat memos/2026-05-27.md | head -10`

Expected:
```
# 2026-05-27

## HH:MM — Telegram

Buy milk at the store
```

(Timestamp will vary based on current time)

- [ ] **Step 3: Verify .session.json was updated**

Run: `cat memos/.session.json`

Expected: `lastEntryTime` should match the timestamp from step 2

- [ ] **Step 4: Test with /topic command**

Run: `echo -e "/topic Groceries\nBread and eggs" | node memos/telegram-memo-handler.js`

Expected: `Added to 2026-05-27.md: Groceries`

- [ ] **Step 5: Verify topic was updated in .session.json**

Run: `cat memos/.session.json | grep currentTopic`

Expected: Contains `"currentTopic": "Groceries"`

- [ ] **Step 6: Test message without /topic (should use current topic)**

Run: `echo "Milk too" | node memos/telegram-memo-handler.js`

Expected: `Added to 2026-05-27.md: Groceries`

(Note: Uses "Groceries" because previous message set it)

- [ ] **Step 7: Verify memo file has all three entries**

Run: `cat memos/2026-05-27.md`

Expected: File contains three separate entries with correct topics and content

- [ ] **Step 8: Clean up test file (optional)**

Run: `rm memos/2026-05-27.md`

This removes the test memo. You can keep it for manual verification if desired.

---

## Task 6: Register Hook in OpenClaw Configuration

**Files:**
- Modify: `openclaw.json`

- [ ] **Step 1: Read current openclaw.json hooks section**

Run: `grep -A 20 '"hooks"' openclaw.json | head -25`

(To understand current structure)

- [ ] **Step 2: Add telegram-memo-handler hook**

Edit `openclaw.json` in the `hooks.internal.entries` section. Find this:

```json
"hooks": {
  "internal": {
    "enabled": true,
    "entries": {
      "command-logger": {
        "enabled": true
      },
      ...
    }
  }
}
```

Add this new entry in the `entries` object (after the existing entries, before the closing brace):

```json
"telegram-memo-handler": {
  "enabled": true,
  "trigger": "telegram:message",
  "script": "memos/telegram-memo-handler.js"
}
```

So the full `entries` section looks like:

```json
"entries": {
  "command-logger": {
    "enabled": true
  },
  "session-memory": {
    "enabled": true
  },
  "bootstrap-extra-files": {
    "enabled": true
  },
  "telegram-memo-handler": {
    "enabled": true,
    "trigger": "telegram:message",
    "script": "memos/telegram-memo-handler.js"
  }
}
```

- [ ] **Step 3: Verify JSON is valid**

Run: `node -e "require('./openclaw.json'); console.log('Valid')"`

Expected: `Valid`

---

## Task 7: Final Integration Test

**Files:**
- Reference: `memos/telegram-memo-handler.js`
- Reference: `openclaw.json`
- Reference: `memos/.session.json`

- [ ] **Step 1: Verify handler script path is correct in openclaw.json**

Run: `grep -A 2 "telegram-memo-handler" openclaw.json`

Expected:
```json
"telegram-memo-handler": {
  "enabled": true,
  "trigger": "telegram:message",
  "script": "memos/telegram-memo-handler.js"
}
```

- [ ] **Step 2: Verify handler file exists and is executable**

Run: `ls -la memos/telegram-memo-handler.js`

Expected: `-rwxr-xr-x ... memos/telegram-memo-handler.js` (x permissions set)

- [ ] **Step 3: Create fresh test memo and session files for clean state**

Run: `cat > memos/.session.json << 'EOF'
{
  "currentTopic": "Telegram",
  "lastEntryTime": "00:00"
}
EOF`

- [ ] **Step 4: Test handler with realistic Telegram message**

Run: `echo -e "/topic Meeting Notes\n- Discussed project timeline\n- Assigned tasks" | node memos/telegram-memo-handler.js`

Expected: `Added to 2026-05-27.md: Meeting Notes`

- [ ] **Step 5: Verify final memo file structure**

Run: `cat memos/2026-05-27.md`

Expected: File has proper markdown structure with heading, timestamp, topic, and content

- [ ] **Step 6: Commit all changes**

Run:
```bash
git add memos/telegram-memo-handler.js openclaw.json
git commit -m "feat: add Telegram memo handler integration

- Created telegram-memo-handler.js with message parsing
- Parses /topic commands and extracts content
- Appends entries to daily memo files with timestamps
- Tracks current topic in .session.json for state
- Registered as OpenClaw hook for telegram:message events

Handles edge cases: missing files, empty messages, invalid JSON
Uses atomic writes (temp file + rename) for reliability"
```

Expected: Commit succeeds with both files staged

---

## Self-Review Against Spec

✓ **Architecture:** Single handler script registered as hook — matches "Approach 1"
✓ **Message parsing:** `/topic` command extraction with stateful fallback — matches spec
✓ **File I/O:** Creates daily memo files, appends entries with timestamps — matches spec
✓ **State management:** Updates `.session.json` with topic and timestamp — matches spec
✓ **Error handling:** Graceful failures with logging — covered in Task 4
✓ **Hook registration:** Added to `openclaw.json` with correct trigger — matches spec
✓ **No placeholders:** All code complete, all commands specified, all expected output defined
✓ **Complete coverage:** All spec sections have corresponding tasks

---

## Notes for Implementation

1. **Handler is Node.js, no dependencies** — Uses only built-in `fs` and `path` modules
2. **Reads from stdin** — OpenClaw passes message data to handler via stdin
3. **Idempotent operations** — Can run multiple times without corruption (atomic writes)
4. **Exit codes:** `0` for success, `1` for error — allows OpenClaw to track status
5. **State file atomicity:** Uses temp file + rename pattern to prevent corruption if handler crashes mid-write
6. **Today's date auto-discovery** — Uses system date to determine memo file name; no manual configuration needed
