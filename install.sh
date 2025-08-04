#!/usr/bin/env bash
# YouTube TV Kiosk Installer for Raspberry Pi OS Lite (Bookworm 64-bit)
# Optimized for 1280x1024 resolution with DRM framebuffer
set -euo pipefail
[[ $EUID -eq 0 ]] && { echo "Run as a regular user, not root."; exit 1; }

CURRENT_USER=$(whoami)
USER_ID=$(id -u)

echo ">>> Updating system..."
sudo apt update && sudo apt full-upgrade -y

echo ">>> Installing required packages..."
sudo apt install -y \
  cog \
  libwpewebkit-2.0-1 \
  libwpebackend-fdo-1.0-1 \
  libwpe-1.0-1 \
  libgles2 \
  gstreamer1.0-wpe \
  gstreamer1.0-libav \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-bad \
  gstreamer1.0-plugins-ugly \
  pipewire \
  pipewire-alsa \
  pipewire-pulse \
  wireplumber \
  dbus-x11

echo ">>> Adding user to audio group..."
sudo usermod -a -G audio "$CURRENT_USER"

echo ">>> Configuring PipeWire..."
# Create user PipeWire config directory
mkdir -p ~/.config/pipewire
if [ -f /usr/share/pipewire/pipewire.conf ]; then
  cp /usr/share/pipewire/pipewire.conf ~/.config/pipewire/
fi

# Enable PipeWire services for user
systemctl --user enable pipewire pipewire-pulse wireplumber || true

echo ">>> Patching boot config (config.txt)..."
CONFIG_FILE="/boot/firmware/config.txt"
[ ! -f "$CONFIG_FILE" ] && CONFIG_FILE="/boot/config.txt"

# Remove any existing display settings to avoid conflicts
sudo sed -i '/# Display Configuration/,/^$/d' "$CONFIG_FILE"
sudo sed -i '/hdmi_group=/d' "$CONFIG_FILE"
sudo sed -i '/hdmi_mode=/d' "$CONFIG_FILE" 
sudo sed -i '/framebuffer_width=/d' "$CONFIG_FILE"
sudo sed -i '/framebuffer_height=/d' "$CONFIG_FILE"
sudo sed -i '/hdmi_force_hotplug=/d' "$CONFIG_FILE"
sudo sed -i '/disable_overscan=/d' "$CONFIG_FILE"

# Add gpu_mem if missing
if ! grep -q "^gpu_mem=" "$CONFIG_FILE"; then
  echo "gpu_mem=256" | sudo tee -a "$CONFIG_FILE" >/dev/null
fi

# Add audio configuration
if ! grep -q "dtparam=audio=on" "$CONFIG_FILE"; then
  echo "dtparam=audio=on" | sudo tee -a "$CONFIG_FILE" >/dev/null
fi

# Add 1280x1024 display configuration
sudo tee -a "$CONFIG_FILE" >/dev/null <<'EOF'

# Display Configuration for 1280x1024
hdmi_force_hotplug=1
disable_overscan=1
hdmi_group=2
hdmi_mode=35
framebuffer_width=1280
framebuffer_height=1024
EOF

echo ">>> Configuring cmdline.txt..."
CMDLINE_FILE="/boot/firmware/cmdline.txt"
[ ! -f "$CMDLINE_FILE" ] && CMDLINE_FILE="/boot/cmdline.txt"

# Add silent boot flags if not already present
if ! grep -q "quiet loglevel=3" "$CMDLINE_FILE"; then
  sudo sed -i '1s/$/ quiet loglevel=3 logo.nologo vt.global_cursor_default=0/' "$CMDLINE_FILE"
fi

echo ">>> Creating kiosk launch script..."
sudo tee /usr/local/bin/youtube-kiosk.sh >/dev/null <<'EOF'
#!/bin/bash
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
export PULSE_RUNTIME_PATH="${XDG_RUNTIME_DIR}/pulse"
export COG_PLATFORM_DRM_CURSOR=1
export WPE_BCMRPI_TOUCH=1
LOGFILE="/var/log/youtube-kiosk.log"

# Create log file
if [ ! -f "$LOGFILE" ]; then
  sudo touch "$LOGFILE"
  sudo chown $(id -u):$(id -g) "$LOGFILE"
fi

echo "[INFO] Kiosk script started at $(date)" >> "$LOGFILE"
echo "[INFO] User: $(whoami), UID: $(id -u)" >> "$LOGFILE"
echo "[INFO] XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR" >> "$LOGFILE"

# Ensure XDG_RUNTIME_DIR exists with correct permissions
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# Start D-Bus session if not running
if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ] || ! dbus-send --session --dest=org.freedesktop.DBus --type=method_call --print-reply /org/freedesktop/DBus org.freedesktop.DBus.GetId &>/dev/null; then
    echo "[INFO] Starting D-Bus session..." >> "$LOGFILE"
    eval $(dbus-launch --sh-syntax)
    export DBUS_SESSION_BUS_ADDRESS
    echo "[INFO] D-Bus session started: $DBUS_SESSION_BUS_ADDRESS" >> "$LOGFILE"
fi

# Start PipeWire if not running
if ! pgrep -x "pipewire" > /dev/null; then
    echo "[INFO] Starting PipeWire..." >> "$LOGFILE"
    pipewire &
    sleep 2
fi

if ! pgrep -x "wireplumber" > /dev/null; then
    echo "[INFO] Starting WirePlumber..." >> "$LOGFILE"
    wireplumber &
    sleep 2
fi

if ! pgrep -x "pipewire-pulse" > /dev/null; then
    echo "[INFO] Starting PipeWire PulseAudio..." >> "$LOGFILE"
    pipewire-pulse &
    sleep 2
fi

# Wait for network
echo "[INFO] Waiting for network..." >> "$LOGFILE"
until ping -c 1 -W 2 8.8.8.8 &>/dev/null; do
  echo "[WARN] Still waiting for network..." >> "$LOGFILE"
  sleep 2
done

echo "[INFO] Network is ready" >> "$LOGFILE"
sleep 3

# Check framebuffer resolution
FB_INFO=$(fbset -s 2>/dev/null || echo "Could not get framebuffer info")
echo "[INFO] Framebuffer info: $FB_INFO" >> "$LOGFILE"

echo "[INFO] Starting Cog browser for 1280x1024 display..." >> "$LOGFILE"

# Launch cog using drm with mouse and cursor support
exec /usr/bin/cog \
  -P drm \
  --enable-media \
  --enable-fullscreen \
  --enable-javascript \
  --enable-spatial-navigation=true \
  --disable-web-security \
  --enable-mouse-cursor \
  --user-agent="Mozilla/5.0 (SMART-TV; Linux; Tizen 5.0) AppleWebKit/537.36" \
  https://www.youtube.com/tv 2>>"$LOGFILE"
EOF

sudo chmod +x /usr/local/bin/youtube-kiosk.sh

echo ">>> Creating systemd service..."
sudo tee /etc/systemd/system/youtube-kiosk.service >/dev/null <<EOF
[Unit]
Description=YouTube TV Kiosk (Cog Browser with WPE) - 1280x1024
After=network-online.target sound.target multi-user.target
Wants=network-online.target

[Service]
Type=simple
User=$CURRENT_USER
Group=audio
Environment="XDG_RUNTIME_DIR=/run/user/$USER_ID"
Environment="HOME=/home/$CURRENT_USER"
Environment="USER=$CURRENT_USER"
RuntimeDirectory=user-$USER_ID
RuntimeDirectoryMode=0700
ExecStartPre=/bin/chown $CURRENT_USER:$CURRENT_USER /run/user/$USER_ID
ExecStart=/usr/local/bin/youtube-kiosk.sh
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
TimeoutStartSec=60

[Install]
WantedBy=multi-user.target
EOF

echo ">>> Configuring auto-login on tty1..."
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf >/dev/null <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $CURRENT_USER --noclear %I \$TERM
EOF

echo ">>> Enabling services..."
sudo systemctl daemon-reload
sudo systemctl enable youtube-kiosk.service

# Create log file with proper permissions
sudo touch /var/log/youtube-kiosk.log
sudo chown "$CURRENT_USER:$CURRENT_USER" /var/log/youtube-kiosk.log

echo ">>> Installation complete!"
echo ""
echo "Display Configuration Applied:"
echo "  ✓ Resolution: 1280x1024 (hdmi_mode=35)"
echo "  ✓ DRM framebuffer optimized"
echo "  ✓ Overscan disabled"
echo "  ✓ HDMI hotplug forced"
echo ""
echo "Audio & System Fixes:"
echo "  ✓ PipeWire audio system configured"
echo "  ✓ D-Bus session management fixed"
echo "  ✓ Runtime directory handling improved"
echo "  ✓ Enhanced error logging added"
echo "  ✓ Audio group membership configured"
echo ""
echo "After reboot, the green box should be gone!"
echo ""
echo "To apply changes:"
echo "  sudo reboot"
echo ""
echo "To monitor after reboot:"
echo "  journalctl -u youtube-kiosk.service -f"
echo "  tail -f /var/log/youtube-kiosk.log"
echo ""
echo "To verify framebuffer resolution:"
echo "  fbset -s"
echo ""

read -p "Reboot now to apply 1280x1024 resolution? (y/N): " -n 1 -r

echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Rebooting in 3 seconds..."
    sleep 3
    sudo reboot
fi