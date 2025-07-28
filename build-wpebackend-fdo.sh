#!/usr/bin/env bash
# build-wpebackend-fdo.sh - Build wpebackend-fdo from source
set -euo pipefail

echo ">>> Building wpebackend-fdo v1.16.0..."
cd /tmp

# Clean up any previous build attempts
sudo rm -rf /tmp/wpebackend-fdo-*

# Download and build wpebackend-fdo v1.16.0
wget -O wpebackend-fdo-1.16.0.tar.xz https://wpewebkit.org/releases/wpebackend-fdo-1.16.0.tar.xz
tar -xf wpebackend-fdo-1.16.0.tar.xz
cd wpebackend-fdo-1.16.0
rm -rf build
meson setup build --buildtype=release
ninja -C build
sudo ninja -C build install
sudo ldconfig

echo ">>> wpebackend-fdo build completed successfully!"