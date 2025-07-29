#!/bin/bash

echo "Testing apt configuration fix..."
echo "================================"

# Test the repository configuration function
source ./build-wpewebkit-manual.sh

# Call the repository configuration function
check_repository_config

# Test if ARM64 packages are available
echo ""
echo "Testing ARM64 package availability..."
if sudo apt-get install -y --dry-run pkg-config:arm64 >/dev/null 2>&1; then
    echo "✅ ARM64 packages are available"
    echo "✅ Repository configuration is working correctly"
else
    echo "❌ ARM64 packages are not available"
    echo "❌ Repository configuration failed"
fi

echo ""
echo "Test completed!"