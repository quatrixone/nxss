# NXSS Server - Docker Setup

This guide explains how to run the NXSS server using Docker and Docker Compose.

## 🐳 Quick Start

### Prerequisites
- Docker and Docker Compose installed
- At least 1GB of available disk space

### Basic Setup

1. **Clone and navigate to the server directory**:
   ```bash
   cd server
   ```

2. **Build and run with Docker Compose**:
   ```bash
   docker-compose up -d
   ```

3. **Check if the server is running**:
   ```bash
   curl http://localhost:8080/health
   ```

### Configuration

1. **Copy environment file**:
   ```bash
   cp env.example .env
   ```

2. **Edit configuration** (optional):
   ```bash
   nano .env
   ```

## 🔧 Docker Commands

### Build and Run
```bash
# Build the image
docker build -t nxss-server .

# Run the container
docker run -d \
  --name nxss-server \
  -p 8080:8080 \
  -v $(pwd)/storage_data:/app/storage_data \
  -v $(pwd)/config:/app/config \
  nxss-server

# Run with Docker Compose
docker-compose up -d
```

### Management
```bash
# View logs
docker-compose logs -f

# Stop the server
docker-compose down

# Restart the server
docker-compose restart

# Update and rebuild
docker-compose down
docker-compose up -d --build
```

### Debugging
```bash
# Access container shell
docker exec -it nxss-server sh

# View container logs
docker logs nxss-server

# Check container status
docker ps
```

## 📁 Volume Mounts

The Docker setup mounts the following directories:

- `./storage_data` → `/app/storage_data` (file storage)
- `./config` → `/app/config` (configuration files)
- `./tmp_uploads` → `/app/tmp_uploads` (temporary uploads)

## 🌐 Network Configuration

### Default Setup
- **Server Port**: 8080
- **Internal Port**: 8080
- **Access URL**: `http://localhost:8080`

### With Nginx (Optional)
```bash
# Run with nginx reverse proxy
docker-compose --profile nginx up -d
```

This will:
- Expose the server on port 80
- Add rate limiting and security headers
- Provide SSL termination (if configured)

## 🔒 Security Features

### Container Security
- Runs as non-root user (`nxss`)
- Minimal Alpine Linux base image
- Health checks enabled
- Resource limits (configurable)

### Network Security
- Rate limiting (10 requests/second)
- Security headers
- File upload size limits (100MB)
- Request timeout protection

## 📊 Monitoring

### Health Checks
```bash
# Check server health
curl http://localhost:8080/health

# Check container health
docker inspect nxss-server | grep Health
```

### Logs
```bash
# View all logs
docker-compose logs

# Follow logs in real-time
docker-compose logs -f

# View specific service logs
docker-compose logs nxss-server
```

## 🚀 Production Deployment

### Environment Variables
```bash
# Production environment
NODE_ENV=production
PORT=8080
HOST=0.0.0.0
STORAGE_PROVIDER=local
DEBUG_MODE=false
```

### Resource Limits
Add to `docker-compose.yml`:
```yaml
services:
  nxss-server:
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
        reservations:
          memory: 256M
          cpus: '0.25'
```

### SSL/HTTPS
1. Place SSL certificates in `./ssl/` directory
2. Uncomment HTTPS configuration in `nginx.conf`
3. Run with nginx profile: `docker-compose --profile nginx up -d`

## 🔄 Updates and Maintenance

### Update Server
```bash
# Pull latest changes
git pull

# Rebuild and restart
docker-compose down
docker-compose up -d --build
```

### Backup Data
```bash
# Backup storage data
tar -czf backup-$(date +%Y%m%d).tar.gz storage_data/

# Backup configuration
cp -r config/ backup-config-$(date +%Y%m%d)/
```

### Cleanup
```bash
# Remove old containers and images
docker system prune -a

# Remove specific volumes (CAUTION: This deletes data)
docker volume rm server_storage_data
```

## 🐛 Troubleshooting

### Common Issues

1. **Port already in use**:
   ```bash
   # Change port in docker-compose.yml
   ports:
     - "8081:8080"  # Use port 8081 instead
   ```

2. **Permission denied**:
   ```bash
   # Fix ownership
   sudo chown -R 1001:1001 storage_data config tmp_uploads
   ```

3. **Container won't start**:
   ```bash
   # Check logs
   docker-compose logs nxss-server
   
   # Check configuration
   docker-compose config
   ```

4. **Storage issues**:
   ```bash
   # Check volume mounts
   docker inspect nxss-server | grep Mounts
   
   # Verify directory permissions
   ls -la storage_data/
   ```

### Debug Mode
```bash
# Run in debug mode
docker run -it --rm \
  -p 8080:8080 \
  -e DEBUG_MODE=true \
  -v $(pwd)/storage_data:/app/storage_data \
  nxss-server
```

## 📈 Performance Tuning

### Memory Optimization
```yaml
# In docker-compose.yml
services:
  nxss-server:
    environment:
      - NODE_OPTIONS=--max-old-space-size=512
```

### File Upload Limits
```yaml
# Increase upload limits in nginx.conf
client_max_body_size 500M;
proxy_read_timeout 600s;
```

This Docker setup provides a production-ready, secure, and scalable deployment of the NXSS server!
