# Use Node.js 18 LTS as base image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application code
COPY . .

# Create necessary directories
RUN mkdir -p tmp_uploads storage_data config

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nxss -u 1001 -G nodejs

# Change ownership of app directory
RUN chown -R nxss:nodejs /app

# Switch to non-root user
USER nxss

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:8080/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

# Start the application
CMD ["node", "index.js"]
