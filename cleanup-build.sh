#!/usr/bin/env bash
# cleanup-build.sh - Clean up build files and remove unnecessary packages
set -euo pipefail

echo ">>> Cleaning up build files..."
cd /
sudo rm -rf /tmp/libwpe-* /tmp/wpebackend-* /tmp/wpewebkit-* /tmp/cog-*

echo ">>> Removing unnecessary build packages to save space..."
sudo apt remove -y \
  build-essential \
  cmake \
  meson \
  ninja-build \
  ruby-dev \
  unifdef \
  libtasn1-6-dev \
  libgirepository1.0-dev \
  gobject-introspection \
  flite1-dev \
  libjxl-dev \
  libwoff-dev \
  libavif-dev \
  libseccomp-dev \
  gperf \
  libglib2.0-dev \
  libgtk-3-dev \
  libsoup-3.0-dev \
  libwebp-dev \
  libxslt1-dev \
  libsecret-1-dev \
  libgcrypt20-dev \
  libsystemd-dev \
  libjpeg-dev \
  libpng-dev \
  libavcodec-dev \
  libavformat-dev \
  libavutil-dev \
  libgl1-mesa-dev \
  libegl1-mesa-dev \
  libdrm-dev \
  libgbm-dev \
  libinput-dev \
  libudev-dev \
  libwayland-dev \
  wayland-protocols \
  libgstreamer1.0-dev \
  libgstreamer-plugins-base1.0-dev \
  libgstreamer-plugins-bad1.0-dev

echo ">>> Cleaning up package cache and orphaned packages..."
sudo apt autoremove -y
sudo apt autoclean
sudo apt clean

echo ">>> Build cleanup completed successfully!"