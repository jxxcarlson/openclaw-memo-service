const fs = require('fs');
const path = require('path');

class PollerLogger {
  constructor(logFile) {
    this.logFile = logFile;
    this.ensureLogFile();
  }

  ensureLogFile() {
    const dir = path.dirname(this.logFile);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    if (!fs.existsSync(this.logFile)) {
      fs.writeFileSync(this.logFile, '');
    }
  }

  formatTimestamp() {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const seconds = String(now.getSeconds()).padStart(2, '0');
    return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
  }

  log(level, message) {
    const timestamp = this.formatTimestamp();
    const logLine = `${timestamp} ${level} ${message}\n`;
    try {
      fs.appendFileSync(this.logFile, logLine, 'utf8');
    } catch (err) {
      console.error(`Failed to write log: ${err.message}`);
    }
  }

  info(message) {
    this.log('INFO', message);
  }

  error(message) {
    this.log('ERROR', message);
  }

  alert(message) {
    this.log('ALERT', message);
  }
}

module.exports = PollerLogger;
