#!/usr/bin/env node

const TelegramBot = require('node-telegram-bot-api');
const { spawn } = require('child_process');
const path = require('path');
const StateManager = require('./telegram-memo-state');
const ConfigLoader = require('./telegram-memo-config');
const PollerLogger = require('./telegram-memo-logger');

// Load configuration
let config;
try {
  const rawConfig = require('./telegram-memo.config');
  const loader = new ConfigLoader(rawConfig);
  config = loader.get();
} catch (err) {
  console.error(`Config load failed: ${err.message}`);
  process.exit(1);
}

// Initialize services
const state = new StateManager(path.join(__dirname, config.STATE_FILE));
const logger = new PollerLogger(path.join(__dirname, config.LOG_FILE));
const bot = new TelegramBot(config.TELEGRAM_BOT_TOKEN);

async function processMessage(chatId, messageId, messageText) {
  // Pipe message through handler
  return new Promise((resolve, reject) => {
    const handlerPath = path.join(__dirname, config.HANDLER_SCRIPT);
    const handler = spawn('node', [handlerPath]);

    let handlerOutput = '';
    let handlerError = '';

    handler.stdout.on('data', (data) => {
      handlerOutput += data.toString();
    });

    handler.stderr.on('data', (data) => {
      handlerError += data.toString();
    });

    handler.on('close', (code) => {
      if (code === 0) {
        // Extract topic from output: "Added to YYYY-MM-DD.md: TopicName"
        const match = handlerOutput.match(/Added to .* : (.+)/);
        const topic = match ? match[1] : 'Memo';
        resolve({ topic, output: handlerOutput });
      } else {
        reject(new Error(`Handler exited with code ${code}: ${handlerError}`));
      }
    });

    handler.stdin.write(messageText);
    handler.stdin.end();
  });
}

async function sendConfirmation(chatId, topic) {
  try {
    const message = `✅ Memo saved: ${topic}`;
    await bot.sendMessage(chatId, message);
  } catch (err) {
    logger.error(`Failed to send confirmation to ${chatId}: ${err.message}`);
    throw err;
  }
}

async function poll() {
  try {
    logger.info('Polling started. Last message ID: ' + state.getLastMessageId());

    const lastMessageId = state.getLastMessageId();
    const updates = await bot.getUpdates({ offset: lastMessageId + 1 });

    if (updates.length === 0) {
      logger.info('No new messages');
      state.resetErrorCount();
      return;
    }

    logger.info(`Found ${updates.length} new message(s)`);

    for (const update of updates) {
      const message = update.message;
      if (!message || !message.text) {
        continue;
      }

      const chatId = message.chat.id;
      const messageId = message.message_id;
      const messageText = message.text;

      // Check if chat is whitelisted
      if (!config.CHAT_IDS.includes(String(chatId))) {
        logger.info(`Skipped message ${messageId}: chat ${chatId} not in whitelist`);
        state.updateMessageId(messageId);
        continue;
      }

      try {
        logger.info(`Processing message ${messageId} from ${chatId}`);
        const { topic } = await processMessage(chatId, messageId, messageText);
        await sendConfirmation(chatId, topic);
        logger.info(`Processed message ${messageId}: ${topic}`);
        state.updateMessageId(messageId);
        state.resetErrorCount();
      } catch (err) {
        logger.error(`Failed to process message ${messageId}: ${err.message}`);
        state.updateMessageId(messageId);
        state.incrementErrorCount();

        const errorCount = state.getErrorCount();
        if (errorCount >= config.ERROR_ALERT_THRESHOLD) {
          try {
            const alertMessage = `⚠️ Memo polling has failed ${errorCount} times. Check logs: memos/.poll.log`;
            await bot.sendMessage(chatId, alertMessage);
            logger.alert(`Alert sent to ${chatId} after ${errorCount} failures`);
          } catch (alertErr) {
            logger.error(`Failed to send alert: ${alertErr.message}`);
          }
        }
      }
    }

    logger.info('Poll completed successfully');
  } catch (err) {
    logger.error(`Poll failed: ${err.message}`);
    state.incrementErrorCount();

    const errorCount = state.getErrorCount();
    if (errorCount >= config.ERROR_ALERT_THRESHOLD) {
      try {
        // Alert the user (send to first whitelisted chat)
        const chatId = config.CHAT_IDS[0];
        const alertMessage = `⚠️ Memo polling has failed ${errorCount} times. Check logs: memos/.poll.log`;
        await bot.sendMessage(chatId, alertMessage);
        logger.alert(`Alert sent to ${chatId} after ${errorCount} failures`);
      } catch (alertErr) {
        logger.error(`Failed to send alert: ${alertErr.message}`);
      }
    }
  }
}

// Run polling
poll()
  .then(() => {
    process.exit(0);
  })
  .catch((err) => {
    logger.error(`Unhandled error: ${err.message}`);
    process.exit(1);
  });
