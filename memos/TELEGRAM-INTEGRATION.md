# Telegram Integration Guide

This guide walks through setting up the memo service to receive and process commands via Telegram.

## Architecture Overview

The memo service integrates with Telegram via a bot that:
1. Receives messages from you via Telegram
2. Parses memo commands (`/memo`, `/topic`, `/tag`, `/review`, etc.)
3. Routes them to the memo file system
4. Sends confirmation messages back to you

## Step 1: Create a Telegram Bot with BotFather

1. **Open Telegram** and search for `@BotFather` (official bot by Telegram)
2. **Start the conversation:** `/start`
3. **Create a new bot:** `/newbot`
4. **Follow the prompts:**
   - Give your bot a name (e.g., "My Memo Bot")
   - Give it a username (must be unique and end with `bot`, e.g., `my_memo_bot`)
5. **Receive your API Token**
   - BotFather will provide a long token string
   - Example: `123456789:ABCdefGHIjklmnoPQRstuvWXYZ1234567`
   - **Keep this secret!**

## Step 2: Store the Token Securely

Create a `.env` file in the workspace root:

```bash
touch /Users/carlson/.openclaw/workspace/.env
```

Add your token (keep this file out of git):

```
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklmnoPQRstuvWXYZ1234567
```

Ensure `.env` is in `.gitignore`:

```bash
echo ".env" >> /Users/carlson/.openclaw/workspace/.gitignore
echo "*.local.json" >> /Users/carlson/.openclaw/workspace/.gitignore
```

## Step 3: Choose Integration Method

### Option A: Long Polling (Simpler, Recommended for Local Dev)

The bot continuously asks Telegram "any new messages for me?" Every few seconds, your bot polls Telegram's servers.

**Pros:**
- No webhook setup needed
- Works behind firewalls/NAT
- Good for development and local testing

**Cons:**
- Slightly higher latency (a few seconds)
- More API calls

### Option B: Webhook (Production-Ready)

Telegram pushes new messages directly to your server via HTTP webhook.

**Pros:**
- Instant message delivery
- More efficient

**Cons:**
- Requires publicly accessible HTTPS endpoint
- More complex setup
- Not ideal for local development

**For now, we'll use polling.**

## Step 4: Bot Implementation

Create a bot handler in `/Users/carlson/.openclaw/workspace/memos/telegram-bot.js` (or your preferred language):

```javascript
const TelegramBot = require('node-telegram-bot-api');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const token = process.env.TELEGRAM_BOT_TOKEN;
if (!token) {
  console.error('Error: TELEGRAM_BOT_TOKEN not set in .env');
  process.exit(1);
}

const bot = new TelegramBot(token, { polling: true });

// Get today's memo file path
function getTodayMemoFile() {
  const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
  return path.join(__dirname, `${today}.md`);
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

// Parse and handle memo commands
function handleMemoCommand(msg) {
  const chatId = msg.chat.id;
  const text = msg.text || '';
  const timestamp = new Date().toLocaleTimeString('en-US', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: false
  });

  try {
    const memoFile = ensureMemoFile();
    
    if (text.startsWith('/memo ')) {
      // Add a new memo entry
      const content = text.slice(6).trim();
      const entry = `\n## ${timestamp} — Memo\n\n${content}\n`;
      fs.appendFileSync(memoFile, entry);
      bot.sendMessage(chatId, `✅ Memo saved at ${timestamp}`);
      
    } else if (text.startsWith('/topic ')) {
      // Set current topic
      const topic = text.slice(7).trim();
      const entry = `\n## ${timestamp} — ${topic}\n\n`;
      fs.appendFileSync(memoFile, entry);
      bot.sendMessage(chatId, `📌 Topic set to: ${topic}`);
      
    } else if (text.startsWith('/tag ')) {
      // Add tags (note: implementation may store in session state)
      const tags = text.slice(5).trim();
      bot.sendMessage(chatId, `🏷️ Tags added: ${tags}`);
      
    } else if (text === '/review') {
      // Review and archive today's memo
      const filePath = getTodayMemoFile();
      if (fs.existsSync(filePath)) {
        // Create archive path
        const today = new Date().toISOString().split('T')[0];
        const archivePath = path.join(__dirname, '..', 'memos-archive', today + '.md');
        
        // Ensure archive directory exists
        fs.mkdirSync(path.dirname(archivePath), { recursive: true });
        
        // Move file
        fs.renameSync(filePath, archivePath);
        bot.sendMessage(chatId, `✅ Memo archived and ready for next day`);
      }
      
    } else if (text === '/help') {
      const help = `
📝 **Memo Commands**

/memo [text] - Add a quick memo
/topic [name] - Set current topic
/tag [tags] - Add tags (#scripta #elm)
/review - Archive today's memo
/help - Show this message
      `.trim();
      bot.sendMessage(chatId, help);
      
    } else {
      bot.sendMessage(chatId, `❓ Unknown command. Type /help for available commands.`);
    }
  } catch (error) {
    console.error('Error:', error);
    bot.sendMessage(chatId, '❌ Error processing command');
  }
}

// Listen for text messages
bot.on('message', (msg) => {
  console.log(`Message from ${msg.from.first_name}: ${msg.text}`);
  
  if (msg.text && msg.text.startsWith('/')) {
    handleMemoCommand(msg);
  } else {
    // Free-form text (optional: treat as /memo)
    bot.sendMessage(msg.chat.id, `Type /help to see available commands, or start with /memo to add a memo.`);
  }
});

bot.onPollingError((error) => {
  console.log(`Polling error: ${error.code} ${error.message}`);
});

console.log('🤖 Telegram bot is running...');
```

## Step 5: Install Dependencies

If using Node.js:

```bash
npm install node-telegram-bot-api dotenv
```

Or use an existing Telegram library for your preferred language:
- **Python:** `python-telegram-bot`
- **Go:** `go-telegram-bot-api`
- **Rust:** `teloxide`

## Step 6: Run the Bot

Start the bot:

```bash
node /Users/carlson/.openclaw/workspace/memos/telegram-bot.js
```

The bot will start polling and print: `🤖 Telegram bot is running...`

## Step 7: Test the Bot

1. **In Telegram**, find your bot (search for its username)
2. **Send a test command:**
   ```
   /help
   ```
3. **Try a memo:**
   ```
   /topic Testing
   /memo This is my first memo from Telegram
   ```
4. **Check the daily memo file:**
   ```bash
   cat /Users/carlson/.openclaw/workspace/memos/$(date +%Y-%m-%d).md
   ```
   You should see the memo entries.

## Step 8: Security Considerations

- **Token:** Keep `TELEGRAM_BOT_TOKEN` out of version control
- **User ID Verification:** (Optional) Restrict bot to specific users
- **Input Validation:** Sanitize memo content before writing to files
- **Rate Limiting:** Add cooldowns to prevent spam

### Optional: Restrict to Your User ID

To ensure only you can use the bot, add user ID verification:

```javascript
const AUTHORIZED_USER_ID = 123456789; // Your Telegram user ID

bot.on('message', (msg) => {
  if (msg.from.id !== AUTHORIZED_USER_ID) {
    bot.sendMessage(msg.chat.id, '❌ Unauthorized');
    return;
  }
  // ... rest of handler
});
```

To find your user ID:
1. Send any message to the bot
2. Check the logs — it will show your user ID

## Step 9: Make It Persistent

For production use, run the bot continuously. Options:

### Option A: System Service (macOS)
Create a LaunchAgent:

```bash
cat > ~/Library/LaunchAgents/com.memo.bot.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.memo.bot</string>
    <key>ProgramArguments</key>
    <array>
        <string>node</string>
        <string>/Users/carlson/.openclaw/workspace/memos/telegram-bot.js</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF

launchctl load ~/Library/LaunchAgents/com.memo.bot.plist
```

### Option B: PM2 (Node Process Manager)
```bash
npm install -g pm2
pm2 start /Users/carlson/.openclaw/workspace/memos/telegram-bot.js --name memo-bot
pm2 save
pm2 startup
```

### Option C: Cron with Restart
Add to crontab:
```
@reboot node /Users/carlson/.openclaw/workspace/memos/telegram-bot.js >> /tmp/memo-bot.log 2>&1
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `TELEGRAM_BOT_TOKEN not set` | Make sure `.env` file exists in workspace root and contains your token |
| Bot doesn't respond | Check that polling is running (`console.log` shows "Telegram bot is running") |
| `403 Forbidden` error | Verify token is correct (copy directly from BotFather) |
| Commands not being parsed | Make sure commands start with `/` |
| Memos not saving | Check file permissions on `memos/` directory |
| Token leaked on GitHub | Immediately revoke token in BotFather (`/token`) and create a new one |

## Next Steps

- [ ] Set up bot with BotFather
- [ ] Store token in `.env`
- [ ] Choose implementation language
- [ ] Deploy bot handler
- [ ] Test with memo commands
- [ ] Set up persistent running (LaunchAgent/PM2/cron)
- [ ] Add user ID verification for security

---

**Related:** See [MEMO-COMMANDS.md](MEMO-COMMANDS.md) for command reference and [VOICE-MEMOS.md](VOICE-MEMOS.md) for voice integration.
