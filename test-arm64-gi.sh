#!/bin/bash

echo "Testing ARM64 GObject Introspection setup..."
echo "============================================"

# Check if ARM64 architecture is added
echo "1. Checking ARM64 architecture..."
if dpkg --print-foreign-architectures | grep -q arm64; then
    echo "✅ ARM64 architecture is added"
else
    echo "❌ ARM64 architecture is not added"
fi

# Check if ARM64 GObject Introspection packages are available
echo ""
echo "2. Checking ARM64 GObject Introspection packages..."
if apt-cache policy python3-gi:arm64 | grep -q "Installed\|Candidate"; then
    echo "✅ python3-gi:arm64 is available"
else
    echo "❌ python3-gi:arm64 is not available"
fi

if apt-cache policy libgirepository1.0-dev:arm64 | grep -q "Installed\|Candidate"; then
    echo "✅ libgirepository1.0-dev:arm64 is available"
else
    echo "❌ libgirepository1.0-dev:arm64 is not available"
fi

if apt-cache policy gobject-introspection:arm64 | grep -q "Installed\|Candidate"; then
    echo "✅ gobject-introspection:arm64 is available"
else
    echo "❌ gobject-introspection:arm64 is not available"
fi

# Check if ARM64 libraries exist
echo ""
echo "3. Checking ARM64 GObject Introspection libraries..."
if [ -f "/usr/lib/aarch64-linux-gnu/libgirepository-1.0.so" ]; then
    echo "✅ ARM64 GObject Introspection library exists"
else
    echo "❌ ARM64 GObject Introspection library not found"
fi

if [ -d "/usr/lib/aarch64-linux-gnu/python3/dist-packages" ]; then
    echo "✅ ARM64 Python packages directory exists"
else
    echo "❌ ARM64 Python packages directory not found"
fi

# Check host GObject Introspection
echo ""
echo "4. Checking host GObject Introspection..."
if [ -f "/usr/lib/x86_64-linux-gnu/libgirepository-1.0.so" ]; then
    echo "✅ Host GObject Introspection library exists"
else
    echo "❌ Host GObject Introspection library not found"
fi

if command -v g-ir-scanner >/dev/null 2>&1; then
    echo "✅ g-ir-scanner is available"
else
    echo "❌ g-ir-scanner is not available"
fi

echo ""
echo "Test completed!"