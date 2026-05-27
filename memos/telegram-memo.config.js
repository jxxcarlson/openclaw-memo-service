// Telegram Memo Polling Configuration
// Edit this file with your Telegram bot token and preferences.
// Token: Get from BotFather (@BotFather on Telegram)

module.exports = {
  // Required: Bot token from BotFather
  TELEGRAM_BOT_TOKEN: process.env.TELEGRAM_BOT_TOKEN || 'YOUR_BOT_TOKEN_HERE',

  // How often to poll for new messages (in seconds)
  POLL_INTERVAL_SECONDS: 60,

  // Chat IDs to listen to (your user ID, comma-separated for multiple users)
  CHAT_IDS: ['123456789'],

  // How many errors before alerting you
  ERROR_ALERT_THRESHOLD: 3,

  // Path to memo handler script
  HANDLER_SCRIPT: './telegram-memo-handler.js',

  // Log file location
  LOG_FILE: './.poll.log',

  // State file location
  STATE_FILE: './.poll-state.json'
};
