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
    topic = lines[0].substring(6).trim() || null;
    contentLines = lines.slice(1);
  } else {
    contentLines = lines;
  }

  const content = contentLines.join('\n').trim();

  return { topic, content };
}

// Read current session state
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
  return { currentTopic: 'Telegram', currentTags: [], lastEntryTime: '00:00' };
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

module.exports = { parseMessage, readSession, writeSession, getTodayMemoPath, getCurrentTimestamp, processMessage };

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
