#!/usr/bin/env bash
# youtube-tv-kiosk-install.sh – Raspberry Pi OS Lite Bookworm 64-bit
set -euo pipefail
[[ $EUID -eq 0 ]] && { echo "Run as a regular user, not root."; exit 1; }

CURRENT_USER=$(whoami)

echo ">>> Updating system..."
sudo apt update && sudo apt full-upgrade -y

echo ">>> Installing required packages..."
sudo apt install -y \
  cog \
  libwpewebkit-1.1-0 \
  libwpebackend-fdo-1.0-1 \
  libwpe-1.0-1 \
  gstreamer1.0-wpe \
  gstreamer1.0-libav \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-bad \
  gstreamer1.0-plugins-ugly

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

# Wait for network
until ping -c 1 -W 2 google.com &>/dev/null; do
  sleep 2
done

# Give the display a moment to come up
sleep 1

exec /usr/bin/cog \
  --platform=drm \
  --enable-media \
  --on-display-request=fullscreen \
  --user-agent="Mozilla/5.0 (SMART-TV; Linux; Tizen 5.0) AppleWebKit/537.36" \
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