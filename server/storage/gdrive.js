const fs = require('fs');
const fsp = require('fs').promises;
const path = require('path');
const { google } = require('googleapis');

class GDriveStorage {
  constructor() {
    this.configDir = path.join(__dirname, '..', 'config');
    this.mapFile = path.join(this.configDir, 'gdrive.map.json');
    if (!fs.existsSync(this.configDir)) fs.mkdirSync(this.configDir, { recursive: true });
    if (!fs.existsSync(this.mapFile)) fs.writeFileSync(this.mapFile, JSON.stringify({}, null, 2));
    this.drive = null;
    this.appFolderId = null;
  }

  async init() {
    if (this.drive) return;
    const credentialsPath = path.join(this.configDir, 'gdrive.credentials.json');
    const tokenPath = path.join(this.configDir, 'gdrive.token.json');
    if (!fs.existsSync(credentialsPath) || !fs.existsSync(tokenPath)) {
      throw new Error('Google Drive not configured. Missing credentials/token files.');
    }
    const credentials = JSON.parse(fs.readFileSync(credentialsPath, 'utf-8'));
    const token = JSON.parse(fs.readFileSync(tokenPath, 'utf-8'));

    const { client_id, client_secret, redirect_uris } = credentials.installed || credentials.web || {};
    const oAuth2Client = new google.auth.OAuth2(
      process.env.GDRIVE_OAUTH_CLIENT_ID || client_id,
      process.env.GDRIVE_OAUTH_CLIENT_SECRET || client_secret,
      process.env.GDRIVE_OAUTH_REDIRECT_URI || (redirect_uris && redirect_uris[0]) || 'http://localhost'
    );
    oAuth2Client.setCredentials(token);
    this.drive = google.drive({ version: 'v3', auth: oAuth2Client });
    this.appFolderId = await this.ensureAppFolder();
  }

  async ensureAppFolder() {
    const name = 'NXSS';
    const list = await this.drive.files.list({ q: `name='${name}' and mimeType='application/vnd.google-apps.folder' and trashed=false`, fields: 'files(id,name)' });
    if (list.data.files && list.data.files.length > 0) return list.data.files[0].id;
    const folder = await this.drive.files.create({
      requestBody: { name, mimeType: 'application/vnd.google-apps.folder' }
    });
    return folder.data.id;
  }

  _readMap() {
    const raw = fs.readFileSync(this.mapFile, 'utf-8');
    try { return JSON.parse(raw); } catch { return {}; }
  }

  _writeMap(map) {
    fs.writeFileSync(this.mapFile, JSON.stringify(map, null, 2));
  }

  async saveFile(tempPath, key) {
    await this.init();
    const map = this._readMap();

    // If exists, replace contents
    let fileId = map[key];
    const media = { body: fs.createReadStream(tempPath) };
    if (fileId) {
      await this.drive.files.update({ fileId, media });
    } else {
      const created = await this.drive.files.create({
        requestBody: { name: key, parents: [this.appFolderId] },
        media
      });
      fileId = created.data.id;
      map[key] = fileId;
      this._writeMap(map);
    }
    await fsp.unlink(tempPath).catch(() => {});
    return { key };
  }

  async getFileStream(key) {
    await this.init();
    const map = this._readMap();
    const fileId = map[key];
    if (!fileId) throw new Error('File not found');
    const res = await this.drive.files.get({ fileId, alt: 'media' }, { responseType: 'stream' });
    return res.data;
  }

  async deleteFile(key) {
    await this.init();
    const map = this._readMap();
    const fileId = map[key];
    if (!fileId) return;
    await this.drive.files.delete({ fileId }).catch(() => {});
    delete map[key];
    this._writeMap(map);
  }
}

module.exports = GDriveStorage;



