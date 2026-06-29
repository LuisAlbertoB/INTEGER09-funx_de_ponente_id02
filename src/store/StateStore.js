const fs = require('fs');
const path = require('path');

const STATE_FILE = path.join(__dirname, 'state.json');

class StateStore {
  constructor() {
    this.state = {};
    this.loadState();
  }

  loadState() {
    try {
      if (fs.existsSync(STATE_FILE)) {
        const data = fs.readFileSync(STATE_FILE, 'utf8');
        this.state = JSON.parse(data);
      }
    } catch (error) {
      console.error('Error cargando state.json:', error);
      this.state = {};
    }
  }

  saveState() {
    try {
      fs.writeFileSync(STATE_FILE, JSON.stringify(this.state, null, 2));
    } catch (error) {
      console.error('Error guardando state.json:', error);
    }
  }

  get(key) {
    return this.state[key];
  }

  set(key, value) {
    this.state[key] = value;
    this.saveState();
  }

  clear() {
    this.state = {};
    this.saveState();
  }
}

module.exports = new StateStore();
