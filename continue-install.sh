#!/bin/bash

echo "Continuing ARM64 GObject Introspection installation..."
echo "===================================================="

# Check if ARM64 architecture is added
if ! dpkg --print-foreign-architectures | grep -q arm64; then
    echo "Adding ARM64 architecture..."
    sudo dpkg --add-architecture arm64
    sudo apt-get update
fi

# Try to install the missing gobject-introspection dependencies
echo "Installing gobject-introspection dependencies..."
sudo apt-get install -y gobject-introspection-bin:arm64 gobject-introspection-bin-linux:arm64

# Now try to install gobject-introspection:arm64
echo "Installing gobject-introspection:arm64..."
sudo apt-get install -y gobject-introspection:arm64

# Clean up
echo "Cleaning up..."
sudo apt-get autoremove -y
sudo apt-get autoclean

echo "Installation completed!"