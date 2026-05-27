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

module.exports = { parseMessage, readSession, writeSession, getTodayMemoPath, getCurrentTimestamp };
