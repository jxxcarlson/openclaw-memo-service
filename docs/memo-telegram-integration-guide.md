# Telegram Memo Integration Guide

## What Is This?

The Telegram memo integration lets you send messages from your phone (Telegram) that automatically get captured into your daily memo files on your computer.

## How It Works

1. You send a message to a Telegram bot
2. Every 2 minutes, a cron job checks for new messages
3. Each message gets piped through the memo handler
4. Your message is appended to today's memo file
5. You get a confirmation message back on Telegram

## Setup Steps

### Step 1: Create a Telegram Bot

1. Open Telegram and search for `@BotFather`
2. Send `/start`, then `/newbot`
3. Choose a name (e.g., "jxc_memo")
4. Choose a username (must end in "bot", e.g., "jxc_memo_bot")
5. **Copy the token** — you'll need this next

### Step 2: Find Your Telegram User ID

1. Search for `@userinfobot` in Telegram
2. Send `/start`
3. You'll get a message with your ID number
4. **Copy this number** — you'll need it next

### Step 3: Configure the Poller

1. Edit `memos/telegram-memo.config.js`
2. Replace `YOUR_BOT_TOKEN_HERE` with your bot token from Step 1
3. Replace `123456789` in `CHAT_IDS` with your user ID from Step 2

Example:

```javascript
module.exports = {
  TELEGRAM_BOT_TOKEN: '1234567890:ABCDefGHijKLMNopqrSTuvWXYzabcDEfgh',
  POLL_INTERVAL_SECONDS: 60,
  CHAT_IDS: ['987654321'],
  // ... rest of config
};
```

4. Save the file

### Step 4: Install the Cron Job

Run the setup script:

```bash
bash memos/setup-cron.sh
```

Or manually edit crontab:

```bash
crontab -e
```

Add this line:

```
*/2 * * * * cd /Users/carlson/.openclaw/workspace/memos && node telegram-memo-poller.js
```

### Step 5: Test It

1. Open Telegram and find your bot (search for the username from Step 1)
2. Send a test message:

```
/topic Testing Integration
This is my first memo!
```

3. Wait up to 2 minutes
4. You should get a confirmation: `✅ Memo saved: Testing Integration`
5. Check your memo file:

```bash
cat memos/2026-05-27.md  # (use today's date)
```

You should see your message there!

## Using It

### Basic Message

Just send any text:

```
Buy groceries for dinner
```

Appears in memos as:

```
## HH:MM — Telegram

Buy groceries for dinner
```

### With a Topic

Start with `/topic`:

```
/topic Grocery List
- Milk
- Eggs
- Bread
```

Appears in memos as:

```
## HH:MM — Grocery List

- Milk
- Eggs
- Bread
```

### Checking Status

View the polling log:

```bash
tail -f memos/.poll.log
```

You'll see entries like:

```
2026-05-27 06:45:15 INFO Polling started. Last message ID: 12345
2026-05-27 06:45:16 INFO Found 1 new message(s)
2026-05-27 06:45:17 INFO Processing message 12346 from 123456789
2026-05-27 06:45:18 INFO Processed message 12346: Testing Integration
2026-05-27 06:45:20 INFO Poll completed successfully
```

## Customization

### Change Polling Interval

Edit `memos/telegram-memo.config.js`:

```javascript
POLL_INTERVAL_SECONDS: 120,  // Poll every 2 minutes instead of 1
```

Then restart cron (no action needed — it will pick up the change next run).

### Add Multiple Chat IDs

If you want multiple users to send memos:

```javascript
CHAT_IDS: ['987654321', '123456789', '555555555'],
```

### Change Error Alert Threshold

How many failures before you get alerted:

```javascript
ERROR_ALERT_THRESHOLD: 5,  // Alert after 5 failures (default is 3)
```

## Troubleshooting

### Messages Not Being Captured

1. Check the log:

```bash
tail memos/.poll.log
```

2. Check that the cron job is running:

```bash
crontab -l | grep telegram-memo
```

3. Test the handler manually:

```bash
cd memos && echo "/topic Test\nHello" | node telegram-memo-handler.js
```

### Bot Not Responding

1. Verify your bot token in the config
2. Verify you can message the bot (search by username in Telegram)
3. Check Telegram connectivity

### Cron Not Running

See `CRON-SETUP.md` troubleshooting section.

## Viewing Archived Memos

Once you review and approve a memo file, move it to the archive:

```bash
mv memos/2026-05-27.md memos-archive/
```

## Disabling the Integration

To temporarily stop the poller:

```bash
crontab -e
# Comment out or remove the telegram-memo-poller line
```

To remove the cron job permanently:

```bash
crontab -e
# Delete the entire telegram-memo-poller line
# Save and exit
```
