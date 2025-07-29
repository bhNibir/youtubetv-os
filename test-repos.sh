#!/bin/bash

echo "Testing ARM64 repository configuration..."
echo "========================================"

# Check Ubuntu version
UBUNTU_VERSION=$(lsb_release -cs)
echo "Ubuntu version: $UBUNTU_VERSION"

# Check if ARM64 architecture is added
echo "Checking ARM64 architecture..."
if dpkg --print-foreign-architectures | grep -q arm64; then
    echo "✅ ARM64 architecture is added"
else
    echo "❌ ARM64 architecture is not added"
fi

# Check ARM64 sources
echo "Checking ARM64 sources..."
if [ -f "/etc/apt/sources.list.d/arm64.list" ]; then
    echo "✅ ARM64 sources file exists:"
    cat /etc/apt/sources.list.d/arm64.list
else
    echo "❌ ARM64 sources file not found"
fi

# Test apt update
echo "Testing apt update..."
if sudo apt-get update >/dev/null 2>&1; then
    echo "✅ apt update successful"
else
    echo "❌ apt update failed"
fi

# Test installing a simple ARM64 package
echo "Testing ARM64 package installation..."
if sudo apt-get install -y --dry-run pkg-config:arm64 >/dev/null 2>&1; then
    echo "✅ ARM64 packages are available"
else
    echo "❌ ARM64 packages are not available"
fi

echo "Test completed!"