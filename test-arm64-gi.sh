#!/bin/bash

echo "Testing ARM64 GObject Introspection packages..."
echo "=============================================="

# Test if ARM64 GObject Introspection packages are available
echo "Checking ARM64 GObject Introspection packages..."

# Test python3-gi:arm64
if apt-cache show python3-gi:arm64 >/dev/null 2>&1; then
    echo "✅ python3-gi:arm64 is available"
else
    echo "❌ python3-gi:arm64 is not available"
fi

# Test gobject-introspection:arm64
if apt-cache show gobject-introspection:arm64 >/dev/null 2>&1; then
    echo "✅ gobject-introspection:arm64 is available"
else
    echo "❌ gobject-introspection:arm64 is not available"
fi

# Test libgirepository1.0-dev:arm64
if apt-cache show libgirepository1.0-dev:arm64 >/dev/null 2>&1; then
    echo "✅ libgirepository1.0-dev:arm64 is available"
else
    echo "❌ libgirepository1.0-dev:arm64 is not available"
fi

# Test python3-gi-cairo:arm64
if apt-cache show python3-gi-cairo:arm64 >/dev/null 2>&1; then
    echo "✅ python3-gi-cairo:arm64 is available"
else
    echo "❌ python3-gi-cairo:arm64 is not available"
fi

echo ""
echo "Test completed!"