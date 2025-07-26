#!/bin/bash

# Test script for YouTube TV OS installation
# This script verifies that all components are working correctly

echo "🧪 Testing YouTube TV OS Installation..."

# Check if Node.js is installed
echo "📦 Checking Node.js..."
if command -v node &> /dev/null; then
    echo "✅ Node.js version: $(node --version)"
else
    echo "❌ Node.js not found"
    exit 1
fi

# Check if npm is installed
echo "📦 Checking npm..."
if command -v npm &> /dev/null; then
    echo "✅ npm version: $(npm --version)"
else
    echo "❌ npm not found"
    exit 1
fi

# Check if Chromium is installed
echo "📦 Checking Chromium..."
if command -v chromium-browser &> /dev/null; then
    echo "✅ Chromium browser found"
else
    echo "❌ Chromium browser not found"
    exit 1
fi

# Check if project directory exists
echo "📁 Checking project directory..."
if [ -d "/opt/youtubetv-os" ]; then
    echo "✅ Project directory exists"
    cd /opt/youtubetv-os
else
    echo "❌ Project directory not found"
    exit 1
fi

# Check if all required files exist
echo "📄 Checking project files..."
required_files=("server.js" "package.json" "web/index.html" "web/app.js" "web/styles.css")
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
        exit 1
    fi
done

# Check if Node.js dependencies are installed
echo "📦 Checking Node.js dependencies..."
if [ -d "node_modules" ]; then
    echo "✅ Node.js dependencies installed"
else
    echo "⚠️  Installing Node.js dependencies..."
    npm install
fi

# Test if the server can start
echo "🚀 Testing server startup..."
timeout 10 node server.js &
SERVER_PID=$!
sleep 3

# Check if server is responding
if curl -s http://localhost:8080 > /dev/null; then
    echo "✅ Server is responding on port 8080"
    kill $SERVER_PID 2>/dev/null
else
    echo "❌ Server not responding"
    kill $SERVER_PID 2>/dev/null
    exit 1
fi

# Check systemd service
echo "🔧 Checking systemd service..."
if systemctl is-enabled youtubetv-os &> /dev/null; then
    echo "✅ Service is enabled"
    if systemctl is-active youtubetv-os &> /dev/null; then
        echo "✅ Service is running"
    else
        echo "⚠️  Service is not running (this is normal during installation)"
    fi
else
    echo "⚠️  Service not enabled (this is normal during installation)"
fi

# Check WiFi tools
echo "📶 Checking WiFi tools..."
if command -v iwlist &> /dev/null; then
    echo "✅ WiFi scanning tools available"
else
    echo "❌ WiFi tools not found"
fi

# Check Bluetooth tools
echo "🔵 Checking Bluetooth tools..."
if command -v bluetoothctl &> /dev/null; then
    echo "✅ Bluetooth tools available"
else
    echo "❌ Bluetooth tools not found"
fi

echo ""
echo "🎉 Installation test completed!"
echo "📋 Next steps:"
echo "   1. Reboot the system: sudo reboot"
echo "   2. The YouTube TV OS should start automatically"
echo "   3. Access the interface at http://localhost:8080"
echo ""
echo "🔧 Manual start (for testing): sudo systemctl start youtubetv-os"
echo "📊 Check logs: journalctl -u youtubetv-os -f"