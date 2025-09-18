#!/bin/bash

# Navigate to the nxss project directory
cd /home/dietpi/Desktop/Projekty/nxss

# Remove any existing git repository
rm -rf .git

# Initialize new git repository
git init
git branch -m main

# Configure git user (if not already configured)
git config user.name "NXSS Team"
git config user.email "team@nxss.dev"

# Add all project files
git add .

# Make initial commit
git commit -m "Initial commit: NXSS Cross-Platform File Sync System

- Complete Flutter mobile/desktop app with sync functionality
- Node.js/Express server with local and Google Drive storage
- Docker support for easy deployment
- Folder pairing with server folder selection
- Cross-platform support (Windows, Linux, macOS, Android, iOS)
- Open source ready with MIT license
- Comprehensive documentation and contributing guidelines"

# Add remote origin
git remote add origin git@github.com:quatrixone/nxss.git

# Push to GitHub
git push -u origin main

echo "✅ Successfully pushed NXSS to GitHub!"
echo "Repository: https://github.com/quatrixone/nxss"
