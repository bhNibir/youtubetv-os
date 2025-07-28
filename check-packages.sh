#!/usr/bin/env bash
# check-packages.sh - Check what WPE packages are available
set -euo pipefail

echo ">>> Checking available WPE packages..."

echo "=== Searching for libwpe packages ==="
apt search libwpe 2>/dev/null | grep -E "(libwpe|wpe)" || echo "No libwpe packages found"

echo ""
echo "=== Searching for webkit packages ==="
apt search webkit 2>/dev/null | grep -E "(webkit|wpe)" || echo "No webkit packages found"

echo ""
echo "=== Searching for cog packages ==="
apt search cog 2>/dev/null | grep cog || echo "No cog packages found"

echo ""
echo "=== Checking repository sources ==="
grep -r "raspberrypi" /etc/apt/sources.list* || echo "No Raspberry Pi repository found"

echo ""
echo "=== Available WPE-related packages ==="
apt list --installed 2>/dev/null | grep -E "(wpe|webkit)" || echo "No WPE packages currently installed"

echo ""
echo "=== Architecture ==="
dpkg --print-architecture

echo ""
echo "=== OS Version ==="
cat /etc/os-release | grep -E "(NAME|VERSION)"