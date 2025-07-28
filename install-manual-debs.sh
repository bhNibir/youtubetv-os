#!/usr/bin/env bash
# youtube-tv-kiosk-install-manual-debs.sh – Manual installation using .deb files
set -euo pipefail
[[ $EUID -eq 0 ]] && { echo "Run as a regular user, not root."; exit 1; }

CURRENT_USER=$(whoami)
REPO_BASE="https://archive.raspberrypi.com/debian/pool/main"

echo ">>> Updating system..."
sudo apt update && sudo apt full-upgrade -y

echo ">>> Installing basic dependencies..."
sudo apt install -y \
  gstreamer1.0-libav \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-bad \
  gstreamer1.0-plugins-ugly \
  libwpe-1.0-1 \
  libwpebackend-fdo-1.0-1

echo ">>> Downloading WPE WebKit .deb packages..."
cd /tmp

# Download the required .deb files for arm64
wget "${REPO_BASE}/w/wpewebkit/libwpewebkit-2.0-1_2.48.1-2+rpi1_arm64.deb" || {
    echo "arm64 package not found, trying armhf..."
    wget "${REPO_BASE}/w/wpewebkit/libwpewebkit-2.0-1_2.48.1-2+rpi1_armhf.deb"
}

wget "${REPO_BASE}/c/cog/cog_0.18.4-1+rpi1_all.deb" || {
    echo "Cog package not found, will install from source later..."
}

echo ">>> Installing downloaded packages..."
sudo dpkg -i *.deb || {
    echo ">>> Fixing broken dependencies..."
    sudo apt-get install -f -y
    sudo dpkg -i *.deb
}

echo ">>> Checking if cog is installed..."
if ! command -v cog &> /dev/null; then
    echo ">>> Installing cog from repository..."
    sudo apt install -y cog || {
        echo ">>> Building cog from source..."
        sudo apt install -y build-essential cmake ninja-build pkg-config libwpe-1.0-dev libwpebackend-fdo-1.0-dev
        
        wget https://wpewebkit.org/releases/cog-0.18.5.tar.xz
        tar -xf cog-0.18.5.tar.xz
        cd cog-0.18.5
        mkdir build && cd build
        cmake -DCMAKE_BUILD_TYPE=Release \
              -DCOG_PLATFORM_DRM=ON \
              -DCOG_PLATFORM_X11=ON \
              -DCOG_PLATFORM_WL=ON \
              -GNinja ..
        ninja
        sudo ninja install
        sudo ldconfig
        cd /tmp
    }
fi

echo ">>> Cleaning up downloaded files..."
rm -f *.deb *.tar.xz
rm -rf cog-*

echo ">>> WPE WebKit installation completed!"

echo ">>> Configuring boot config..."
# Check for new location first, fallback to old location
CONFIG_FILE="/boot/firmware/config.txt"
if [ ! -f "$CONFIG_FILE" ]; then
  CONFIG_FILE="/boot/config.txt"
fi

if ! grep -q "^dtoverlay=vc4-kms-v3d" "$CONFIG_FILE"; then
  sudo tee -a "$CONFIG_FILE" >/dev/null <<'EOF'

# --- YouTube TV kiosk ---
dtoverlay=vc4-kms-v3d
disable_overscan=1
max_framebuffers=2
disable_splash=1
gpu_mem=256

# Power optimization to reduce undervoltage issues
arm_freq=1200
over_voltage=2
temp_limit=75
force_turbo=0
EOF
fi

echo ">>> Configuring cmdline.txt..."
# Check for new location first, fallback to old location
CMDLINE_FILE="/boot/firmware/cmdline.txt"
if [ ! -f "$CMDLINE_FILE" ]; then
  CMDLINE_FILE="/boot/cmdline.txt"
fi

sudo sed -i '1s/$/ quiet loglevel=3 logo.nologo vt.global_cursor_default=0/' "$CMDLINE_FILE"

echo ">>> Creating kiosk script..."
sudo tee /usr/local/bin/youtube-kiosk.sh >/dev/null <<'EOF'
#!/bin/bash
export XDG_RUNTIME_DIR=/run/user/$(id -u)
LOGFILE="/var/log/youtube-kiosk.log"

# Create the log file if it doesn't exist
if [ ! -f "$LOGFILE" ]; then
  sudo touch "$LOGFILE"
  sudo chown $(id -u):$(id -g) "$LOGFILE"
fi

echo "[INFO] Kiosk script started at $(date)" >> "$LOGFILE"

# Wait for network
until ping -c 1 -W 2 google.com &>/dev/null; do
  echo "[WARN] Waiting for network..." >> "$LOGFILE"
  sleep 2
done

# Give time for display manager (if any)
sleep 1

# Try different cog locations
COG_BIN=""
if [ -f "/usr/local/bin/cog" ]; then
    COG_BIN="/usr/local/bin/cog"
elif [ -f "/usr/bin/cog" ]; then
    COG_BIN="/usr/bin/cog"
else
    echo "[ERROR] Cog browser not found!" >> "$LOGFILE"
    exit 1
fi

echo "[INFO] Using cog at: $COG_BIN" >> "$LOGFILE"

# Launch cog in kiosk mode with mouse support
$COG_BIN \
  -P drm \
  -O fullscreen=true \
  --enable-media \
  --enable-fullscreen \
  --enable-javascript \
  --enable-spatial-navigation=true \
  --gamepad \
  --user-agent="Mozilla/5.0 (X11; Linux armv7l) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" \
  https://www.youtube.com/tv
EOF
sudo chmod +x /usr/local/bin/youtube-kiosk.sh

echo ">>> Creating systemd service..."
cat <<EOF | sudo tee /etc/systemd/system/youtube-kiosk.service >/dev/null
[Unit]
Description=YouTube TV kiosk (WPE WebKit)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$CURRENT_USER
Environment="XDG_RUNTIME_DIR=/run/user/$(id -u $CURRENT_USER)"
ExecStart=/usr/local/bin/youtube-kiosk.sh
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reexec
sudo systemctl enable youtube-kiosk.service

echo ">>> Configuring auto-login for user: $CURRENT_USER..."
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf >/dev/null <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $CURRENT_USER --noclear %I \$TERM
EOF

sudo systemctl daemon-reload

echo ">>> Installation completed successfully!"
echo ">>> The system will reboot and start the YouTube TV kiosk automatically."
echo ">>> Rebooting in 5 seconds..."
sleep 5
sudo reboot