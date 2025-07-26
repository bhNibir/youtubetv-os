#!/bin/bash

# YouTube TV OS Installer for Raspberry Pi 3B+
# This script sets up everything needed for the YouTube TV OS

set -e

echo "🚀 Installing YouTube TV OS for Raspberry Pi 3B+..."

# Check if running on Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo; then
    echo "⚠️  Warning: This script is designed for Raspberry Pi. Continue anyway? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install minimal GUI (X11 + openbox) as suggested by OpenAI
echo "📦 Installing minimal GUI components..."
sudo apt install --no-install-recommends xserver-xorg x11-xserver-utils xinit openbox -y

# Install required packages
echo "📦 Installing required packages..."
sudo apt install -y \
    chromium-browser \
    lightdm \
    unclutter \
    nodejs \
    npm \
    bluez \
    bluez-tools \
    rfkill \
    wireless-tools \
    wpasupplicant \
    git \
    curl \
    wget \
    vim \
    htop

# Install Node.js 18 if not already installed
echo "📦 Checking Node.js version..."
NODE_VERSION=$(node --version 2>/dev/null | cut -d'v' -f2 | cut -d'.' -f1 || echo "0")
if [ "$NODE_VERSION" -lt 14 ]; then
    echo "📦 Installing Node.js 18..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Create installation directory
echo "📁 Creating installation directory..."
sudo mkdir -p /opt/youtubetv-os
cd /opt/youtubetv-os

# Download the project files from GitHub
echo "📥 Downloading YouTube TV OS files..."
if [ -d ".git" ]; then
    echo "Repository already exists, pulling latest changes..."
    sudo git pull
else
    echo "Cloning repository from GitHub..."
    sudo git clone https://github.com/bhNibir/youtubetv-os.git .
fi

# Set permissions
sudo chown -R pi:pi /opt/youtubetv-os
sudo chmod +x /opt/youtubetv-os/setup.sh
sudo chmod +x /opt/youtubetv-os/scripts/*.sh

# Run setup
echo "🔧 Running setup script..."
sudo -u pi ./setup.sh

echo "✅ Installation complete!"
echo "📋 Next steps:"
echo "   1. The system will reboot automatically"
echo "   2. After reboot, the YouTube TV OS will start automatically"
echo "   3. Access the control panel at http://localhost:8080"
echo "   4. Use your TV remote or keyboard for navigation"
echo ""
echo "🔄 Rebooting system in 10 seconds... (Press Ctrl+C to cancel)"
sleep 10
sudo reboot