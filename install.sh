#!/usr/bin/env bash
# YouTube TV Kiosk Installer for Raspberry Pi OS Lite (Bookworm 64-bit)
set -euo pipefail
[[ $EUID -eq 0 ]] && { echo "Run as a regular user, not root."; exit 1; }

CURRENT_USER=$(whoami)

echo ">>> Updating system..."
sudo apt update && sudo apt full-upgrade -y

echo ">>> Installing required packages..."
sudo apt install -y \
  cog \
  libwpewebkit-2.0-1 \
  libwpebackend-fdo-1.0-1 \
  libwpe-1.0-1 \
  gstreamer1.0-wpe \
  gstreamer1.0-libav \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-bad \
  gstreamer1.0-plugins-ugly

echo ">>> Patching boot config (config.txt)..."
CONFIG_FILE="/boot/firmware/config.txt"
[ ! -f "$CONFIG_FILE" ] && CONFIG_FILE="/boot/config.txt"

# Add gpu_mem if missing
if ! grep -q "^gpu_mem=" "$CONFIG_FILE"; then
  echo "gpu_mem=256" | sudo tee -a "$CONFIG_FILE" >/dev/null
fi

# Add performance settings if not already there
# if ! grep -q "^# --- YouTube TV kiosk ---" "$CONFIG_FILE"; then
#   sudo tee -a "$CONFIG_FILE" >/dev/null <<'EOF'

# # --- YouTube TV kiosk ---
# # Optional power optimization
# arm_freq=1200
# over_voltage=2
# temp_limit=75
# force_turbo=0
# EOF
# fi

echo ">>> Configuring cmdline.txt..."
CMDLINE_FILE="/boot/firmware/cmdline.txt"
[ ! -f "$CMDLINE_FILE" ] && CMDLINE_FILE="/boot/cmdline.txt"

# Add silent boot flags if not already present
if ! grep -q "quiet loglevel=3" "$CMDLINE_FILE"; then
  sudo sed -i '1s/$/ quiet loglevel=3 logo.nologo vt.global_cursor_default=0/' "$CMDLINE_FILE"
fi

# Optional: boot to CLI only
# sudo systemctl set-default multi-user.target

echo ">>> Creating kiosk launch script..."
sudo tee /usr/local/bin/youtube-kiosk.sh >/dev/null <<'EOF'
#!/bin/bash
export XDG_RUNTIME_DIR=/run/user/$(id -u)
LOGFILE="/var/log/youtube-kiosk.log"

# Create log file
if [ ! -f "$LOGFILE" ]; then
  sudo touch "$LOGFILE"
  sudo chown $(id -u):$(id -g) "$LOGFILE"
fi

echo "[INFO] Kiosk script started at $(date)" >> "$LOGFILE"

# Wait for network
until ping -c 1 -W 2 8.8.8.8 &>/dev/null; do
  echo "[WARN] Waiting for network..." >> "$LOGFILE"
  sleep 2
done

sleep 1

# Launch cog using drm
exec /usr/bin/cog \
  -P drm \
  --enable-media \
  --enable-fullscreen \
  --enable-javascript \
  --enable-spatial-navigation=true \
  --user-agent="Mozilla/5.0 (SMART-TV; Linux; Tizen 5.0) AppleWebKit/537.36" \
  https://www.youtube.com/tv
EOF
sudo chmod +x /usr/local/bin/youtube-kiosk.sh

echo ">>> Creating systemd service..."
sudo tee /etc/systemd/system/youtube-kiosk.service >/dev/null <<EOF
[Unit]
Description=YouTube TV Kiosk (Cog Browser with WPE)
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

echo ">>> Configuring auto-login on tty1..."
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
