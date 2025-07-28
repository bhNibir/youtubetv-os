#!/usr/bin/env bash
# build-cog.sh - Build Cog browser from source
set -euo pipefail

echo ">>> Building cog v0.18.5..."
cd /tmp

# Clean up any previous build attempts
sudo rm -rf /tmp/cog-*

# Download and build cog v0.18.5
wget -O cog-0.18.5.tar.xz https://wpewebkit.org/releases/cog-0.18.5.tar.xz
tar -xf cog-0.18.5.tar.xz
cd cog-0.18.5
rm -rf build
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCOG_PLATFORM_DRM=ON \
      -DCOG_PLATFORM_X11=ON \
      -DCOG_PLATFORM_WL=ON \
      -GNinja ..
ninja
sudo ninja install
sudo ldconfig

echo ">>> Cog build completed successfully!"