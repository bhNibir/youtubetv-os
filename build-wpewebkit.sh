#!/usr/bin/env bash
# build-wpewebkit.sh - Build WPE WebKit from source
set -euo pipefail

echo ">>> Building wpewebkit v2.48.4 (this will take 1-3 hours)..."
cd /tmp

# Clean up any previous build attempts
sudo rm -rf /tmp/wpewebkit-*

# Download and build wpewebkit v2.48.4
wget -O wpewebkit-2.48.4.tar.xz https://wpewebkit.org/releases/wpewebkit-2.48.4.tar.xz
tar -xf wpewebkit-2.48.4.tar.xz
cd wpewebkit-2.48.4
rm -rf build
mkdir build && cd build

echo ">>> Configuring WebKit build..."
cmake -DCMAKE_BUILD_TYPE=Release \
      -DPORT=WPE \
      -DENABLE_GAMEPAD=ON \
      -DENABLE_VIDEO=ON \
      -DENABLE_WEB_AUDIO=ON \
      -DENABLE_MEDIA_STREAM=ON \
      -DENABLE_ENCRYPTED_MEDIA=ON \
      -DENABLE_INTROSPECTION=ON \
      -DENABLE_SPEECH_SYNTHESIS=ON \
      -DENABLE_WPE_PLATFORM=ON \
      -DENABLE_WPE_PLATFORM_DRM=ON \
      -DENABLE_WPE_PLATFORM_HEADLESS=ON \
      -DENABLE_DOCUMENTATION=OFF \
      -USE_GSTREAMER_WEBRTC \
      -DUSE_JPEGXL=ON \
      -DUSE_AVIF=ON \
      -DUSE_LIBBACKTRACE=OFF \
      -GNinja ..

echo ">>> Starting WebKit compilation (this will take 1-3 hours)..."
ninja

echo ">>> Installing WebKit..."
sudo ninja install
sudo ldconfig

echo ">>> WebKit build completed successfully!"