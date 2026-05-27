class ConfigLoader {
  constructor(config) {
    this.validate(config);
    this.config = config;
  }

  validate(config) {
    if (!config.TELEGRAM_BOT_TOKEN) {
      throw new Error('TELEGRAM_BOT_TOKEN is required');
    }
    if (!Array.isArray(config.CHAT_IDS)) {
      throw new Error('CHAT_IDS must be an array');
    }
    if (!config.CHAT_IDS || config.CHAT_IDS.length === 0) {
      throw new Error('CHAT_IDS cannot be empty');
    }
  }

  get() {
    return {
      TELEGRAM_BOT_TOKEN: this.config.TELEGRAM_BOT_TOKEN,
      POLL_INTERVAL_SECONDS: this.config.POLL_INTERVAL_SECONDS || 60,
      CHAT_IDS: this.config.CHAT_IDS,
      ERROR_ALERT_THRESHOLD: this.config.ERROR_ALERT_THRESHOLD || 3,
      HANDLER_SCRIPT: this.config.HANDLER_SCRIPT || './telegram-memo-handler.js',
      LOG_FILE: this.config.LOG_FILE || './.poll.log',
      STATE_FILE: this.config.STATE_FILE || './.poll-state.json'
    };
  }
}

module.exports = ConfigLoader;
