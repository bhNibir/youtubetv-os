#!/bin/bash

# Deployment script for YouTube TV OS
# This script packages and prepares the project for GitHub deployment

set -e

echo "📦 Preparing YouTube TV OS for deployment..."

# Create deployment directory
mkdir -p dist
rm -rf dist/*

# Copy all necessary files
echo "📁 Copying project files..."
cp -r web dist/
cp -r scripts dist/
cp -r config dist/
cp server.js dist/
cp package.json dist/
cp install.sh dist/
cp setup.sh dist/
cp README.md dist/

# Make scripts executable
chmod +x dist/install.sh
chmod +x dist/setup.sh
chmod +x dist/scripts/*.sh

# Create a compressed archive
echo "🗜️ Creating archive..."
cd dist
tar -czf ../youtubetv-os.tar.gz .
cd ..

echo "✅ Deployment package created: youtubetv-os.tar.gz"
echo "📋 Files ready for GitHub:"
echo "   - Upload all files in the dist/ directory to your GitHub repository"
echo "   - Update the repository URL in install.sh"
echo "   - Test the installation with: curl -sSL https://raw.githubusercontent.com/bhNibir/youtubetv-os/main/install.sh | bash"