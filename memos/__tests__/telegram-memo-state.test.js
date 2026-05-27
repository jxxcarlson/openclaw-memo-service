const fs = require('fs');
const path = require('path');
const StateManager = require('../telegram-memo-state');

describe('StateManager', () => {
  const testStateFile = path.join(__dirname, '.test-state.json');

  afterEach(() => {
    if (fs.existsSync(testStateFile)) {
      fs.unlinkSync(testStateFile);
    }
  });

  test('initializes state on first run', () => {
    const state = new StateManager(testStateFile);
    const data = state.read();
    expect(data.lastMessageId).toBe(0);
    expect(data.errorCount).toBe(0);
    expect(data.lastPolledAt).toBeDefined();
  });

  test('persists and reads state', () => {
    const state = new StateManager(testStateFile);
    state.updateMessageId(12345);
    state.resetErrorCount();

    const state2 = new StateManager(testStateFile);
    const data = state2.read();
    expect(data.lastMessageId).toBe(12345);
    expect(data.errorCount).toBe(0);
  });

  test('increments error count', () => {
    const state = new StateManager(testStateFile);
    state.incrementErrorCount();
    state.incrementErrorCount();
    const data = state.read();
    expect(data.errorCount).toBe(2);
  });

  test('resets error count', () => {
    const state = new StateManager(testStateFile);
    state.incrementErrorCount();
    state.incrementErrorCount();
    state.resetErrorCount();
    const data = state.read();
    expect(data.errorCount).toBe(0);
  });
});
