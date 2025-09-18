const { Command } = require('commander');
const path = require('path');
const fs = require('fs');
const fsp = require('fs').promises;
const chokidar = require('chokidar');
const axios = require('axios');
const FormData = require('form-data');
const os = require('os');
const ini = require('ini');

const CONFIG_DIR = path.join(os.homedir(), '.nxss');
const CONFIG_PATH = path.join(CONFIG_DIR, 'config.ini');

function ensureConfig() {
  if (!fs.existsSync(CONFIG_DIR)) fs.mkdirSync(CONFIG_DIR, { recursive: true });
  if (!fs.existsSync(CONFIG_PATH)) fs.writeFileSync(CONFIG_PATH, ini.encode({ server: { url: 'http://localhost:8080' } }));
}

function readConfig() {
  ensureConfig();
  return ini.decode(fs.readFileSync(CONFIG_PATH, 'utf-8'));
}

function writeConfig(cfg) {
  ensureConfig();
  fs.writeFileSync(CONFIG_PATH, ini.encode(cfg));
}

function getApi(cfg) {
  const instance = axios.create({ baseURL: cfg.server?.url || 'http://localhost:8080' });
  if (cfg.auth?.token) {
    instance.interceptors.request.use((c) => {
      c.headers = c.headers || {};
      c.headers['Authorization'] = `Bearer ${cfg.auth.token}`;
      return c;
    });
  }
  return instance;
}

async function uploadFile(api, root, fullPath) {
  const relPath = path.relative(root, fullPath).split(path.sep).join('/');
  const stat = await fsp.stat(fullPath);
  const stream = fs.createReadStream(fullPath);
  const fd = new FormData();
  fd.append('relPath', relPath);
  fd.append('lastModified', String(stat.mtimeMs));
  fd.append('file', stream);
  const headers = fd.getHeaders();
  const res = await api.post('/files/upload', fd, { headers });
  return res.data;
}

async function fullSync(api, folder) {
  const files = await listAllFiles(folder);
  for (const file of files) {
    await uploadFile(api, folder, file).catch((e) => console.error('upload failed', file, e.message));
  }
}

async function listAllFiles(dir) {
  const acc = [];
  const entries = await fsp.readdir(dir, { withFileTypes: true });
  for (const e of entries) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) {
      const inner = await listAllFiles(p);
      acc.push(...inner);
    } else if (e.isFile()) {
      acc.push(p);
    }
  }
  return acc;
}

const program = new Command();
program.name('nxss').description('NXSS CLI - sync files with NXSS server');

program.command('init')
  .requiredOption('--server <url>', 'Server base URL, e.g., http://localhost:8080')
  .requiredOption('--folder <path>', 'Folder to sync')
  .action((opts) => {
    const cfg = readConfig();
    cfg.server = { url: opts.server };
    cfg.sync = { folder: path.resolve(opts.folder) };
    writeConfig(cfg);
    console.log('Configured:', cfg);
  });

program.command('login')
  .requiredOption('--email <email>')
  .requiredOption('--password <password>')
  .action(async (opts) => {
    const cfg = readConfig();
    const api = getApi(cfg);
    try {
      // try login, else register
      let token;
      try {
        const r = await api.post('/auth/login', { email: opts.email, password: opts.password });
        token = r.data.token;
      } catch {
        const r2 = await api.post('/auth/register', { email: opts.email, password: opts.password });
        token = r2.data.token;
      }
      cfg.auth = { token };
      writeConfig(cfg);
      console.log('Logged in.');
    } catch (e) {
      console.error('Auth failed:', e.message);
      process.exit(1);
    }
  });

program.command('sync')
  .action(async () => {
    const cfg = readConfig();
    if (!cfg.sync?.folder) return console.error('Run: nxss init --server ... --folder ...');
    const api = getApi(cfg);
    await fullSync(api, cfg.sync.folder);
    console.log('Sync complete');
  });

program.command('watch')
  .action(async () => {
    const cfg = readConfig();
    if (!cfg.sync?.folder) return console.error('Run: nxss init --server ... --folder ...');
    const api = getApi(cfg);
    const watcher = chokidar.watch(cfg.sync.folder, { ignoreInitial: true, persistent: true });
    watcher.on('add', fp => uploadFile(api, cfg.sync.folder, fp).then(() => console.log('Uploaded', fp)).catch(e => console.error(e.message)));
    watcher.on('change', fp => uploadFile(api, cfg.sync.folder, fp).then(() => console.log('Updated', fp)).catch(e => console.error(e.message)));
    console.log('Watching for changes...');
  });

program.parseAsync();



