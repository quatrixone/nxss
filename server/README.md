# NXSS Server

The NXSS server handles file synchronization, user authentication, and storage management.

## 🚀 Quick Start

```bash
# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your settings

# Start server
npm start
```

## ⚙️ Configuration

### Environment Variables

Create a `.env` file with the following variables:

```env
# Server Configuration
PORT=8080
HOST=0.0.0.0

# Security
JWT_SECRET=your-super-secret-jwt-key-change-in-production

# Storage Configuration
STORAGE_PROVIDER=local  # or 'gdrive'
STORAGE_PATH=./storage_data

# Google Drive (if using gdrive provider)
GDRIVE_CREDENTIALS_PATH=./config/gdrive.credentials.json
GDRIVE_TOKEN_PATH=./config/gdrive.token.json
```

### Storage Providers

#### Local Storage (Default)
Files are stored in the `storage_data/` directory.

#### Google Drive
1. Set `STORAGE_PROVIDER=gdrive`
2. Place OAuth credentials in `config/gdrive.credentials.json`
3. Place access token in `config/gdrive.token.json`

## 📁 API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration
- `POST /api/auth/refresh` - Refresh token

### Files
- `GET /api/files` - List user files
- `POST /api/files/upload` - Upload file
- `GET /api/files/:id` - Download file
- `DELETE /api/files/:id` - Delete file
- `POST /api/files/sync` - Sync files

## 🔒 Security

- JWT-based authentication
- File access restricted to authenticated users
- Configurable CORS settings
- Rate limiting (configurable)

## 🛠️ Development

```bash
# Start in development mode with auto-reload
npm run dev

# Run tests
npm test

# Lint code
npm run lint
```

## 📊 Monitoring

The server provides basic health check endpoints:
- `GET /health` - Server health status
- `GET /api/stats` - Basic statistics (if enabled)
