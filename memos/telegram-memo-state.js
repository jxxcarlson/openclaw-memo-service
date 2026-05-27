const fs = require('fs');
const path = require('path');

class StateManager {
  constructor(stateFile) {
    this.stateFile = stateFile;
    this.ensureState();
  }

  ensureState() {
    if (!fs.existsSync(this.stateFile)) {
      const initialState = {
        lastMessageId: 0,
        lastPolledAt: new Date().toISOString(),
        errorCount: 0
      };
      this.write(initialState);
    }
  }

  read() {
    try {
      const data = fs.readFileSync(this.stateFile, 'utf8');
      return JSON.parse(data);
    } catch (err) {
      throw new Error(`Failed to read state: ${err.message}`);
    }
  }

  write(data) {
    try {
      const tmpFile = this.stateFile + '.tmp';
      fs.writeFileSync(tmpFile, JSON.stringify(data, null, 2), 'utf8');
      fs.renameSync(tmpFile, this.stateFile);
    } catch (err) {
      throw new Error(`Failed to write state: ${err.message}`);
    }
  }

  updateMessageId(messageId) {
    const data = this.read();
    data.lastMessageId = messageId;
    data.lastPolledAt = new Date().toISOString();
    this.write(data);
  }

  incrementErrorCount() {
    const data = this.read();
    data.errorCount += 1;
    this.write(data);
  }

  resetErrorCount() {
    const data = this.read();
    data.errorCount = 0;
    this.write(data);
  }

  getLastMessageId() {
    return this.read().lastMessageId;
  }

  getErrorCount() {
    return this.read().errorCount;
  }
}

module.exports = StateManager;
