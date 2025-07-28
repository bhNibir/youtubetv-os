#!/usr/bin/env bash
# build-libwpe.sh - Build libwpe from source
set -euo pipefail

echo ">>> Building libwpe v1.16.2..."
cd /tmp

# Clean up any previous build attempts
sudo rm -rf /tmp/libwpe-*

# Download and build libwpe v1.16.2
wget -O libwpe-1.16.2.tar.xz https://wpewebkit.org/releases/libwpe-1.16.2.tar.xz
tar -xf libwpe-1.16.2.tar.xz
cd libwpe-1.16.2
rm -rf build
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release -GNinja ..
ninja
sudo ninja install
sudo ldconfig

echo ">>> libwpe build completed successfully!"