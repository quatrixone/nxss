const fs = require('fs');
const fsp = require('fs').promises;
const path = require('path');

const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, '..', 'data');

function ensureDirSync(dir) {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
}

function ensureFileSync(filePath, initial) {
  if (!fs.existsSync(filePath)) fs.writeFileSync(filePath, JSON.stringify(initial, null, 2));
}

function collectionPath(name) {
  return path.join(DATA_DIR, `${name}.json`);
}

const db = {
  read(name) {
    const file = collectionPath(name);
    ensureDirSync(DATA_DIR);
    ensureFileSync(file, []);
    const raw = fs.readFileSync(file, 'utf-8');
    try {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed)) return parsed;
      return [];
    } catch (e) {
      return [];
    }
  },
  write(name, value) {
    const file = collectionPath(name);
    ensureDirSync(DATA_DIR);
    fs.writeFileSync(file, JSON.stringify(value, null, 2));
  }
};

function ensureDataStores() {
  ensureDirSync(DATA_DIR);
  ensureFileSync(collectionPath('users'), []);
  ensureFileSync(collectionPath('files'), []);
}

module.exports = { ensureDataStores, db };



