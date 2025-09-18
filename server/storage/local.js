const fs = require('fs');
const fsp = require('fs').promises;
const path = require('path');

class LocalStorage {
  constructor() {
    this.rootDir = process.env.STORAGE_DATA_DIR || path.join(__dirname, '..', 'storage_data');
    if (!fs.existsSync(this.rootDir)) fs.mkdirSync(this.rootDir, { recursive: true });
  }

  async saveFile(tempPath, key) {
    const destPath = path.join(this.rootDir, key);
    const dir = path.dirname(destPath);
    await fsp.mkdir(dir, { recursive: true });
    await fsp.rename(tempPath, destPath);
    return { key };
  }

  async getFileStream(key) {
    const filePath = path.join(this.rootDir, key);
    return fs.createReadStream(filePath);
  }

  async deleteFile(key) {
    const filePath = path.join(this.rootDir, key);
    try {
      await fsp.unlink(filePath);
    } catch (e) {
      // ignore
    }
  }
}

module.exports = LocalStorage;



