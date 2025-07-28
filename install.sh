#!/usr/bin/env bash
# youtube-tv-kiosk-install.sh – Raspberry Pi OS Lite Bookworm 64-bit
set -euo pipefail
[[ $EUID -eq 0 ]] && { echo "Run as a regular user, not root."; exit 1; }

CURRENT_USER=$(whoami)
REPO_URL="https://raw.githubusercontent.com/bhNibir/youtubetv-os/main"

echo ">>> Updating system..."
sudo apt update && sudo apt full-upgrade -y

echo ">>> Installing build dependencies..."
sudo apt install -y \
  build-essential \
  cmake \
  meson \
  ninja-build \
  pkg-config \
  ruby \
  ruby-dev \
  python3 \
  perl \
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
  gstreamer1.0-libav \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-bad \
  gstreamer1.0-plugins-ugly \
  libgstreamer1.0-dev \
  libgstreamer-plugins-base1.0-dev \
  libgstreamer-plugins-bad1.0-dev

echo ">>> Downloading build scripts..."
cd /tmp
wget -O build-libwpe.sh "$REPO_URL/build-libwpe.sh"
wget -O build-wpebackend-fdo.sh "$REPO_URL/build-wpebackend-fdo.sh"
wget -O build-wpewebkit.sh "$REPO_URL/build-wpewebkit.sh"
wget -O build-cog.sh "$REPO_URL/build-cog.sh"
wget -O cleanup-build.sh "$REPO_URL/cleanup-build.sh"

chmod +x build-*.sh cleanup-build.sh

echo ">>> Building WPE from latest stable releases..."

# Build libwpe
./build-libwpe.sh

# Build wpebackend-fdo
./build-wpebackend-fdo.sh

# Build wpewebkit (this will take 1-3 hours)
./build-wpewebkit.sh

# Build cog
./build-cog.sh

# Clean up build files and packages
./cleanup-build.sh

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

# Optional: uncomment below if you want to boot to CLI by default
# sudo systemctl set-default multi-user.target

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

# Launch cog in kiosk mode with mouse support
/usr/local/bin/cog \
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

echo ">>> Done! Rebooting..."
sleep 3
sudo reboot