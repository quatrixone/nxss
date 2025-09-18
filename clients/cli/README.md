# NXSS CLI Client

Cross-platform command-line client for NXSS file synchronization.

## 🚀 Quick Start

```bash
# Install globally
npm install -g .

# Initialize sync folder
nxss init --server http://localhost:8080 --folder "/path/to/sync"

# Login (creates account if doesn't exist)
nxss login --email you@example.com --password yourpassword

# Sync files
nxss sync

# Watch for changes (keeps running)
nxss watch
```

## 📋 Commands

### `nxss init`
Initialize a folder for synchronization.

```bash
nxss init --server <server-url> --folder <folder-path>
```

**Options:**
- `--server, -s` - NXSS server URL (required)
- `--folder, -f` - Local folder to sync (required)
- `--config, -c` - Config file path (default: ~/.nxss/config.ini)

### `nxss login`
Authenticate with the server.

```bash
nxss login --email <email> --password <password>
```

**Options:**
- `--email, -e` - Your email address (required)
- `--password, -p` - Your password (required)
- `--server, -s` - Override server URL

### `nxss sync`
Synchronize files with the server.

```bash
nxss sync [options]
```

**Options:**
- `--dry-run` - Show what would be synced without making changes
- `--force` - Force sync even if no changes detected
- `--verbose, -v` - Verbose output

### `nxss watch`
Watch for file changes and sync automatically.

```bash
nxss watch [options]
```

**Options:**
- `--interval, -i` - Check interval in seconds (default: 5)
- `--verbose, -v` - Verbose output

### `nxss status`
Show sync status and configuration.

```bash
nxss status
```

### `nxss logout`
Clear stored authentication.

```bash
nxss logout
```

## ⚙️ Configuration

Configuration is stored in `~/.nxss/config.ini`:

```ini
[server]
url = http://localhost:8080

[local]
folder = /path/to/sync/folder

[auth]
token = your-jwt-token
```

## 🔧 Development

```bash
# Install dependencies
npm install

# Build
npm run build

# Run from source
node src/index.js <command>

# Run tests
npm test
```

## 📁 File Structure

```
clients/cli/
├── src/
│   └── index.js          # Main CLI application
├── scripts/
│   └── build.js          # Build script
├── dist/
│   └── index.js          # Built executable
├── package.json
└── README.md
```

## 🐛 Troubleshooting

### Common Issues

1. **"Server not reachable"**
   - Check if server is running
   - Verify server URL in config
   - Check network connectivity

2. **"Authentication failed"**
   - Run `nxss login` to re-authenticate
   - Check if server is accessible

3. **"Permission denied"**
   - Check folder permissions
   - Ensure you have read/write access

### Debug Mode

Run with verbose output for debugging:

```bash
nxss sync --verbose
nxss watch --verbose
```
