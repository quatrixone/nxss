const fs = require('fs');
const fsp = require('fs').promises;
const path = require('path');
const express = require('express');
const multer = require('multer');
const dotenv = require('dotenv');
const crypto = require('crypto');

dotenv.config({ path: path.join(__dirname, '.env') });

const { ensureDataStores, db } = require('./services/db');
const LocalStorage = require('./storage/local');
const GDriveStorage = require('./storage/gdrive');

const app = express();
app.use(express.json({ limit: '25mb' }));

const PORT = process.env.PORT || 8080;
const HOST = process.env.HOST || '0.0.0.0';
const STORAGE_PROVIDER = process.env.STORAGE_PROVIDER || 'local';

const storageImpl = STORAGE_PROVIDER === 'gdrive' ? new GDriveStorage() : new LocalStorage();
const upload = multer({ dest: path.join(process.cwd(), 'tmp_uploads') });

// Pairing code storage
const pairingCodes = new Map(); // code -> { clientId, createdAt, expiresAt }

ensureDataStores();

app.get('/health', (req, res) => {
  res.json({ ok: true, provider: STORAGE_PROVIDER });
});

// Pairing code endpoints
app.get('/pairing', (req, res) => {
  res.send(`
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NXSS Pairing</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0;
            padding: 20px;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: white;
            border-radius: 16px;
            padding: 40px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            text-align: center;
            max-width: 500px;
            width: 100%;
        }
        .logo {
            width: 80px;
            height: 80px;
            background: #6366F1;
            border-radius: 20px;
            margin: 0 auto 20px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 32px;
            font-weight: bold;
        }
        h1 {
            color: #1f2937;
            margin-bottom: 10px;
            font-size: 28px;
        }
        .subtitle {
            color: #6b7280;
            margin-bottom: 30px;
            font-size: 16px;
        }
        .code-display {
            background: #f8fafc;
            border: 2px dashed #d1d5db;
            border-radius: 12px;
            padding: 20px;
            margin: 20px 0;
            font-family: 'Courier New', monospace;
            font-size: 24px;
            font-weight: bold;
            color: #1f2937;
            letter-spacing: 2px;
        }
        .code-label {
            color: #6b7280;
            font-size: 14px;
            margin-bottom: 10px;
        }
        .expires {
            color: #ef4444;
            font-size: 14px;
            margin-top: 10px;
        }
        .button {
            background: #6366F1;
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: background 0.2s;
            margin: 10px;
        }
        .button:hover {
            background: #4f46e5;
        }
        .button:disabled {
            background: #9ca3af;
            cursor: not-allowed;
        }
        .instructions {
            background: #f0f9ff;
            border: 1px solid #0ea5e9;
            border-radius: 8px;
            padding: 16px;
            margin: 20px 0;
            text-align: left;
        }
        .instructions h3 {
            margin: 0 0 10px 0;
            color: #0c4a6e;
            font-size: 16px;
        }
        .instructions ol {
            margin: 0;
            padding-left: 20px;
            color: #0c4a6e;
        }
        .instructions li {
            margin: 5px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">🔄</div>
        <h1>NXSS Pairing</h1>
        <p class="subtitle">Generate a pairing code to connect your client</p>
        
        <div class="code-label">Pairing Code:</div>
        <div class="code-display" id="pairingCode">Click "Generate Code" to start</div>
        <div class="expires" id="expiresText"></div>
        
        <button class="button" onclick="generateCode()" id="generateBtn">Generate Code</button>
        <button class="button" onclick="copyCode()" id="copyBtn" disabled>Copy Code</button>
        
        <div class="instructions">
            <h3>How to pair:</h3>
            <ol>
                <li>Click "Generate Code" to create a new pairing code</li>
                <li>Copy the code and enter it in your NXSS client</li>
                <li>The code expires in 5 minutes for security</li>
                <li>Once paired, your client will be connected to this server</li>
            </ol>
        </div>
    </div>

    <script>
        let currentCode = null;
        let expiresAt = null;
        
        function generateCode() {
            const code = Math.random().toString(36).substring(2, 8).toUpperCase();
            const now = new Date();
            expiresAt = new Date(now.getTime() + 5 * 60 * 1000); // 5 minutes
            
            document.getElementById('pairingCode').textContent = code;
            document.getElementById('expiresText').textContent = \`Expires at \${expiresAt.toLocaleTimeString()}\`;
            document.getElementById('generateBtn').disabled = true;
            document.getElementById('copyBtn').disabled = false;
            
            currentCode = code;
            
            // Send code to server
            fetch('/api/pairing/generate', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ code: code, expiresAt: expiresAt.getTime() })
            });
            
            // Auto-refresh when expired
            setTimeout(() => {
                document.getElementById('generateBtn').disabled = false;
                document.getElementById('copyBtn').disabled = true;
                document.getElementById('expiresText').textContent = 'Code expired';
            }, 5 * 60 * 1000);
        }
        
        function copyCode() {
            if (currentCode) {
                navigator.clipboard.writeText(currentCode).then(() => {
                    const btn = document.getElementById('copyBtn');
                    const originalText = btn.textContent;
                    btn.textContent = 'Copied!';
                    setTimeout(() => {
                        btn.textContent = originalText;
                    }, 2000);
                });
            }
        }
    </script>
</body>
</html>
  `);
});

// API endpoints for pairing
app.post('/api/pairing/generate', (req, res) => {
  const { code, expiresAt } = req.body;
  const clientId = crypto.randomUUID();
  
  pairingCodes.set(code, {
    clientId,
    createdAt: Date.now(),
    expiresAt: expiresAt
  });
  
  // Clean up expired codes
  for (const [c, data] of pairingCodes.entries()) {
    if (data.expiresAt < Date.now()) {
      pairingCodes.delete(c);
    }
  }
  
  res.json({ success: true, clientId });
});

app.post('/api/pairing/verify', (req, res) => {
  const { code } = req.body;
  
  if (!code) {
    return res.status(400).json({ error: 'Pairing code required' });
  }
  
  const pairingData = pairingCodes.get(code);
  
  if (!pairingData) {
    return res.status(404).json({ error: 'Invalid pairing code' });
  }
  
  if (pairingData.expiresAt < Date.now()) {
    pairingCodes.delete(code);
    return res.status(410).json({ error: 'Pairing code expired' });
  }
  
  // Remove the used code
  pairingCodes.delete(code);
  
  res.json({ 
    success: true, 
    clientId: pairingData.clientId,
    message: 'Pairing successful'
  });
});

// Settings endpoints
app.get('/settings', (req, res) => {
  res.json({
    storageProvider: STORAGE_PROVIDER,
    serverUrl: `http://${HOST}:${PORT}`,
    features: {
      googleDrive: STORAGE_PROVIDER === 'gdrive',
      localStorage: STORAGE_PROVIDER === 'local',
      debugMode: process.env.DEBUG_MODE === 'true'
    }
  });
});

app.post('/settings/storage', (req, res) => {
  const { provider, credentials } = req.body;
  
  if (provider === 'gdrive' && credentials) {
    try {
      // Validate JSON credentials
      const creds = JSON.parse(credentials);
      if (!creds.client_email || !creds.private_key) {
        return res.status(400).json({ error: 'Invalid Google Drive credentials format' });
      }
      
      // Save credentials to file
      const fs = require('fs');
      const path = require('path');
      const credsPath = path.join(__dirname, 'config', 'gdrive.credentials.json');
      
      // Ensure config directory exists
      const configDir = path.dirname(credsPath);
      if (!fs.existsSync(configDir)) {
        fs.mkdirSync(configDir, { recursive: true });
      }
      
      fs.writeFileSync(credsPath, JSON.stringify(creds, null, 2));
      
      res.json({ 
        success: true, 
        message: 'Google Drive credentials saved successfully',
        provider: 'gdrive'
      });
    } catch (e) {
      res.status(400).json({ error: 'Invalid JSON credentials: ' + e.message });
    }
  } else if (provider === 'local') {
    res.json({ 
      success: true, 
      message: 'Switched to local storage',
      provider: 'local'
    });
  } else {
    res.status(400).json({ error: 'Invalid storage provider or missing credentials' });
  }
});

// Files (no auth required)
app.get('/files', (req, res) => {
  const all = db.read('files');
  res.json(all);
});

app.post('/files/upload', upload.single('file'), async (req, res) => {
  try {
    const tmpPath = req.file?.path;
    const { relPath, lastModified, hash, folderId } = req.body;
    if (!tmpPath || !relPath) return res.status(400).json({ error: 'file and relPath required' });
    const fileId = require('uuid').v4();
    const normalizedRel = path.posix.normalize(relPath).replace(/^\.\/+/, '');
    const storagePrefix = path.posix.join(folderId || 'default', normalizedRel);
    const stored = await storageImpl.saveFile(tmpPath, storagePrefix);

    const files = db.read('files');
    const record = {
      id: fileId,
      folderId: folderId || 'default',
      relPath: normalizedRel,
      lastModified: Number(lastModified) || Date.now(),
      hash: hash || null,
      size: req.file.size,
      storageKey: stored.key,
      createdAt: Date.now()
    };
    files.push(record);
    db.write('files', files);

    res.json({ id: fileId, key: stored.key });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'upload failed' });
  } finally {
    if (req.file?.path) fs.unlink(req.file.path, () => {});
  }
});

app.get('/files/download/:id', async (req, res) => {
  const { id } = req.params;
  const files = db.read('files');
  const rec = files.find(f => f.id === id);
  if (!rec) return res.status(404).end();
  try {
    const stream = await storageImpl.getFileStream(rec.storageKey);
    stream.on('error', (err) => {
      console.error(err);
      res.status(500).end();
    });
    stream.pipe(res);
  } catch (e) {
    console.error(e);
    res.status(500).end();
  }
});

app.delete('/files/:id', async (req, res) => {
  const { id } = req.params;
  const files = db.read('files');
  const idx = files.findIndex(f => f.id === id);
  if (idx === -1) return res.status(404).end();
  const rec = files[idx];
  await storageImpl.deleteFile(rec.storageKey);
  files.splice(idx, 1);
  db.write('files', files);
  res.json({ ok: true });
});

// Folder sync endpoints
app.get('/folders', (req, res) => {
  const files = db.read('files');
  const folders = [...new Set(files.map(f => f.folderId))].map(folderId => ({
    id: folderId,
    name: folderId,
    fileCount: files.filter(f => f.folderId === folderId).length,
    lastModified: Math.max(...files.filter(f => f.folderId === folderId).map(f => f.lastModified || 0))
  })).sort((a, b) => a.name.localeCompare(b.name));
  res.json(folders);
});

app.get('/folders/:folderId/files', (req, res) => {
  const { folderId } = req.params;
  const files = db.read('files');
  const folderFiles = files.filter(f => f.folderId === folderId);
  res.json(folderFiles);
});

app.post('/sync/folder', async (req, res) => {
  try {
    const { folderPath, folderId } = req.body;
    if (!folderPath || !folderId) {
      return res.status(400).json({ error: 'folderPath and folderId required' });
    }

    // Check if folder exists
    if (!fs.existsSync(folderPath)) {
      return res.status(404).json({ error: 'Folder not found' });
    }

    // Get all files in the folder
    const files = await getAllFilesInFolder(folderPath);
    const existingFiles = db.read('files');
    const folderFiles = existingFiles.filter(f => f.folderId === folderId);

    // Sync files
    for (const filePath of files) {
      const relPath = path.relative(folderPath, filePath);
      const stats = await fsp.stat(filePath);
      const existingFile = folderFiles.find(f => f.relPath === relPath);

      if (!existingFile || existingFile.lastModified < stats.mtime.getTime()) {
        // Ensure tmp_uploads directory exists
        const tmpDir = path.join(process.cwd(), 'tmp_uploads');
        if (!fs.existsSync(tmpDir)) {
          await fsp.mkdir(tmpDir, { recursive: true });
        }
        
        // Upload file
        const tmpPath = path.join(tmpDir, path.basename(filePath));
        await fsp.copyFile(filePath, tmpPath);
        
        const fileId = require('uuid').v4();
        const storagePrefix = path.posix.join(folderId, relPath);
        const stored = await storageImpl.saveFile(tmpPath, storagePrefix);

        const record = {
          id: fileId,
          folderId: folderId,
          relPath: relPath,
          lastModified: stats.mtime.getTime(),
          size: stats.size,
          storageKey: stored.key,
          createdAt: Date.now()
        };

        // Remove old record if exists
        const oldIndex = existingFiles.findIndex(f => f.relPath === relPath);
        if (oldIndex !== -1) {
          existingFiles.splice(oldIndex, 1);
        }

        existingFiles.push(record);
        // Only delete temp file if it exists
        try {
          await fsp.unlink(tmpPath);
        } catch (e) {
          // Ignore if file doesn't exist
          console.log('Temp file already cleaned up:', tmpPath);
        }
      }
    }

    // Update database
    const allFiles = db.read('files');
    const otherFiles = allFiles.filter(f => f.folderId !== folderId);
    db.write('files', [...otherFiles, ...existingFiles]);

    res.json({ 
      success: true, 
      syncedFiles: files.length,
      folderId: folderId 
    });
  } catch (e) {
    console.error('Sync error:', e);
    res.status(500).json({ error: 'Sync failed: ' + e.message });
  }
});

// Helper function to get all files in a folder recursively
async function getAllFilesInFolder(folderPath) {
  const files = [];
  
  async function scanDir(dirPath) {
    const entries = await fsp.readdir(dirPath, { withFileTypes: true });
    
    for (const entry of entries) {
      const fullPath = path.join(dirPath, entry.name);
      
      if (entry.isDirectory()) {
        await scanDir(fullPath);
      } else if (entry.isFile()) {
        files.push(fullPath);
      }
    }
  }
  
  await scanDir(folderPath);
  return files;
}

app.listen(PORT, HOST, () => {
  console.log(`NXSS server listening on http://${HOST}:${PORT} (storage=${STORAGE_PROVIDER})`);
});



