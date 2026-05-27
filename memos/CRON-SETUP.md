# Setting Up the Telegram Memo Poller Cron Job

The poller needs to run automatically at regular intervals. Use cron to schedule it.

## Prerequisites

1. Configure `telegram-memo.config.js` with your bot token and chat ID
2. Test the poller manually (see Task 7)

## Manual Cron Setup

1. Open crontab editor:

```bash
crontab -e
```

2. Add this line to run the poller every 2 minutes:

```
*/2 * * * * cd /Users/carlson/.openclaw/workspace/memos && node telegram-memo-poller.js
```

To adjust the interval, change the `*/2`:
- `*/1` — every 1 minute
- `*/5` — every 5 minutes
- `*/10` — every 10 minutes
- `0 * * * *` — every hour

3. Save and exit (in most editors: Ctrl+X, then Y, then Enter)

4. Verify it was added:

```bash
crontab -l | grep telegram-memo-poller
```

## Testing the Cron Job

1. Wait for the next scheduled execution (up to 2 minutes)
2. Check the log file:

```bash
tail -f /Users/carlson/.openclaw/workspace/memos/.poll.log
```

3. Send a test message to your Telegram bot
4. Within 2 minutes, you should see the message processed in the log and a confirmation in Telegram

## Troubleshooting

**Cron job not running:**
- Check if cron is enabled: `sudo systemctl status cron` (or similar for your OS)
- Verify the full path to `node` — use `which node` and update the crontab entry if needed

**No logs appearing:**
- Check that `.poll.log` exists: `ls -la memos/.poll.log`
- Check system cron logs: `log stream --predicate 'eventMessage contains[cd] "telegram"'`

**Config not being picked up:**
- Ensure you're using the correct full path in the crontab
- Verify config values with: `node -e "console.log(require('./telegram-memo.config'))"`

## Disabling the Cron Job

```bash
crontab -e
# Remove the line containing 'telegram-memo-poller'
# Save and exit
```

Verify removal:

```bash
crontab -l
```
