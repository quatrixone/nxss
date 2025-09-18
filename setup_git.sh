#!/bin/bash

# Navigate to the nxss directory
cd /home/dietpi/Desktop/Projekty/nxss

# Remove any existing git repository
rm -rf .git

# Initialize git repository
git init
git branch -m main

# Add all files
git add .

# Make initial commit
git commit -m "Initial commit: NXSS Cross-Platform File Sync System

- Complete Flutter mobile/desktop app with sync functionality
- Node.js server with local and Google Drive storage support
- Docker setup for easy deployment
- Folder pairing with server folder selection
- Modern UI with settings panel
- Cross-platform support (Windows, Linux, macOS, Android, iOS)
- Open source ready with MIT license
- Comprehensive documentation and contributing guidelines"

echo "Git repository initialized successfully!"
echo "Ready to push to GitHub!"
