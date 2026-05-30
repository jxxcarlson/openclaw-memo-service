#!/usr/bin/env node

const TelegramBot = require('node-telegram-bot-api');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const token = process.env.TELEGRAM_BOT_TOKEN;
if (!token) {
  console.error('Error: TELEGRAM_BOT_TOKEN not set in .env');
  process.exit(1);
}

const bot = new TelegramBot(token, { polling: true });
const memosDir = __dirname;
const archiveDir = path.join(__dirname, '..', 'memos-archive');
const inboxDir = path.join(memosDir, 'audio-inbox');

// Ensure inbox directory exists
if (!fs.existsSync(inboxDir)) {
  fs.mkdirSync(inboxDir, { recursive: true });
}

// Store session state per user
const userState = {};

// Get today's memo file path
function getTodayMemoFile() {
  const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
  return path.join(memosDir, `${today}.md`);
}

// Get or create memo file with header
function ensureMemoFile() {
  const filePath = getTodayMemoFile();
  if (!fs.existsSync(filePath)) {
    const today = new Date().toISOString().split('T')[0];
    fs.writeFileSync(filePath, `# ${today}\n\n`);
  }
  return filePath;
}

// Get timestamp for entries
function getTimestamp() {
  return new Date().toLocaleTimeString('en-US', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: false
  });
}

// Initialize user state
function initUserState(userId) {
  if (!userState[userId]) {
    userState[userId] = {
      currentTopic: null,
      currentTags: [],
      lastEntryTime: null
    };
  }
  return userState[userId];
}

// Parse and handle memo commands
function handleMemoCommand(msg) {
  const chatId = msg.chat.id;
  const userId = msg.from.id;
  const text = msg.text || '';
  const timestamp = getTimestamp();

  const state = initUserState(userId);

  try {
    const memoFile = ensureMemoFile();

    if (text.startsWith('/memo ')) {
      // Add a new memo entry
      const content = text.slice(6).trim();
      let entry = `\n## ${timestamp} — Memo\n\n${content}\n`;

      // Add current topic if set
      if (state.currentTopic) {
        entry = `\n## ${timestamp} — ${state.currentTopic}\n\n${content}\n`;
      }

      // Add tags if set
      if (state.currentTags.length > 0) {
        entry += `\n*Tags: ${state.currentTags.join(', ')}*\n`;
      }

      fs.appendFileSync(memoFile, entry);
      state.lastEntryTime = timestamp;
      bot.sendMessage(chatId, `✅ Memo saved at ${timestamp}`);

    } else if (text.startsWith('/topic ')) {
      // Set current topic
      const topic = text.slice(7).trim();
      state.currentTopic = topic;
      const entry = `\n## ${timestamp} — ${topic}\n\n`;
      fs.appendFileSync(memoFile, entry);
      bot.sendMessage(chatId, `📌 Topic set to: **${topic}**\n\nNext memos will be grouped under this topic.`);

    } else if (text.startsWith('/tag ')) {
      // Add tags
      const tagInput = text.slice(5).trim();
      const tags = tagInput.split(/\s+/);
      state.currentTags = tags;
      bot.sendMessage(chatId, `🏷️ Tags set: ${tags.join(', ')}\n\nNext memos will include these tags.`);

    } else if (text === '/clear-topic') {
      state.currentTopic = null;
      bot.sendMessage(chatId, `✅ Topic cleared. Future memos will have no topic.`);

    } else if (text === '/clear-tags') {
      state.currentTags = [];
      bot.sendMessage(chatId, `✅ Tags cleared.`);

    } else if (text === '/review') {
      // Review and archive today's memo
      const filePath = getTodayMemoFile();
      if (fs.existsSync(filePath)) {
        try {
          // Create archive path (YYYY/MM/YYYY-MM-DD.md)
          const today = new Date().toISOString().split('T')[0];
          const [year, month, day] = today.split('-');
          const archivePath = path.join(archiveDir, year, month, `${today}.md`);

          // Ensure archive directory exists
          fs.mkdirSync(path.dirname(archivePath), { recursive: true });

          // Move file
          fs.renameSync(filePath, archivePath);

          // Reset user state for new day
          state.currentTopic = null;
          state.currentTags = [];
          state.lastEntryTime = null;

          // Create new day's file
          ensureMemoFile();

          bot.sendMessage(chatId, `✅ Memo reviewed and archived!\n\nFile: \`${archivePath}\`\n\nReady for tomorrow's memos.`);
        } catch (err) {
          console.error('Archive error:', err);
          bot.sendMessage(chatId, `❌ Error archiving memo: ${err.message}`);
        }
      } else {
        bot.sendMessage(chatId, `ℹ️ No memo file to review today.`);
      }

    } else if (text === '/status') {
      // Show current state
      let status = `📊 **Current Status**\n\n`;
      status += `Topic: ${state.currentTopic || '(none)'}\n`;
      status += `Tags: ${state.currentTags.length > 0 ? state.currentTags.join(', ') : '(none)'}\n`;
      status += `Last entry: ${state.lastEntryTime || '(none)'}\n`;
      status += `\nMemo file: ${getTodayMemoFile()}`;
      bot.sendMessage(chatId, status);

    } else if (text === '/help') {
      const help = `📝 **Memo Commands**

\`/memo [text]\` - Add a memo entry
\`/topic [name]\` - Set topic for next memos
\`/tag [tags]\` - Add tags (#tag1 #tag2)
\`/clear-topic\` - Clear current topic
\`/clear-tags\` - Clear current tags
\`/status\` - Show current state
\`/review\` - Archive today's memo
\`/help\` - Show this message`;
      bot.sendMessage(chatId, help);

    } else {
      bot.sendMessage(chatId, `❓ Unknown command. Type /help for available commands.`);
    }
  } catch (error) {
    console.error('Error:', error);
    bot.sendMessage(chatId, `❌ Error processing command: ${error.message}`);
  }
}

// Handle voice messages
function handleVoiceMessage(msg) {
  const chatId = msg.chat.id;
  const fileId = msg.voice.file_id;
  const timestamp = getTimestamp();

  try {
    // Generate filename with timestamp
    const filename = `voice-${Date.now()}.ogg`;
    const filePath = path.join(inboxDir, filename);

    // Create write stream
    const stream = fs.createWriteStream(filePath);

    // Download voice file and pipe to disk
    bot.getFileStream(fileId).pipe(stream);

    stream.on('finish', () => {
      bot.sendMessage(chatId, `🎙️ Voice memo received at ${timestamp}\n\nWaiting to be transcribed...`);
      console.log(`[${timestamp}] Voice memo saved: ${filename}`);
    });

    stream.on('error', (error) => {
      console.error('Error writing voice file:', error);
      fs.unlink(filePath, () => {}); // Clean up partial file
      bot.sendMessage(chatId, `❌ Error saving voice memo: ${error.message}`);
    });
  } catch (error) {
    console.error('Error handling voice message:', error);
    bot.sendMessage(chatId, `❌ Error processing voice memo: ${error.message}`);
  }
}

// Listen for all messages
bot.on('message', (msg) => {
  const timestamp = getTimestamp();

  // Handle voice messages
  if (msg.voice) {
    console.log(`[${timestamp}] Voice message from ${msg.from.first_name}`);
    handleVoiceMessage(msg);
  } else if (msg.text) {
    console.log(`[${timestamp}] Text message from ${msg.from.first_name}: ${msg.text}`);

    // iPhone dictation transcribes "/memo" as "/Memo" — normalize before dispatch
    if (/^\/Memo(\s|$)/.test(msg.text)) {
      msg.text = '/memo' + msg.text.slice(5);
    }

    if (msg.text.startsWith('/')) {
      handleMemoCommand(msg);
    } else {
      // Free-form text: ask if they want to save as memo
      const chatId = msg.chat.id;
      bot.sendMessage(chatId, `💡 Type /help to see available commands.\n\nOr start with /memo to add a memo: \`/memo your text here\``);
    }
  }
});

bot.on('polling_error', (error) => {
  console.error(`Polling error: ${error.code || error.message}`);
});

console.log('🤖 Telegram memo bot is running...');
console.log(`📁 Memos directory: ${memosDir}`);
console.log(`📚 Archive directory: ${archiveDir}`);
console.log('Press Ctrl+C to stop\n');
