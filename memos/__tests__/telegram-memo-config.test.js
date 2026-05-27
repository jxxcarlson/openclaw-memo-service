const ConfigLoader = require('../telegram-memo-config');

describe('ConfigLoader', () => {
  test('loads config with all required fields', () => {
    const mockConfig = {
      TELEGRAM_BOT_TOKEN: 'test-token-123',
      POLL_INTERVAL_SECONDS: 60,
      CHAT_IDS: ['123456'],
      ERROR_ALERT_THRESHOLD: 3,
      HANDLER_SCRIPT: './telegram-memo-handler.js',
      LOG_FILE: './.poll.log',
      STATE_FILE: './.poll-state.json'
    };

    const loader = new ConfigLoader(mockConfig);
    const config = loader.get();
    expect(config.TELEGRAM_BOT_TOKEN).toBe('test-token-123');
    expect(config.POLL_INTERVAL_SECONDS).toBe(60);
    expect(Array.isArray(config.CHAT_IDS)).toBe(true);
  });

  test('throws on missing required token', () => {
    const mockConfig = {
      POLL_INTERVAL_SECONDS: 60,
      CHAT_IDS: ['123456']
    };

    expect(() => {
      new ConfigLoader(mockConfig);
    }).toThrow('TELEGRAM_BOT_TOKEN is required');
  });

  test('validates CHAT_IDS is array', () => {
    const mockConfig = {
      TELEGRAM_BOT_TOKEN: 'token',
      CHAT_IDS: 'not-an-array'
    };

    expect(() => {
      new ConfigLoader(mockConfig);
    }).toThrow('CHAT_IDS must be an array');
  });
});
