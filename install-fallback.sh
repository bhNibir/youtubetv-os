#!/usr/bin/env bash
# youtube-tv-kiosk-install-fallback.sh – Try multiple installation methods
set -euo pipefail
[[ $EUID -eq 0 ]] && { echo "Run as a regular user, not root."; exit 1; }

CURRENT_USER=$(whoami)

echo ">>> Updating system..."
sudo apt update && sudo apt full-upgrade -y

echo ">>> Installing basic dependencies..."
sudo apt install -y \
  gstreamer1.0-libav \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-bad \
  gstreamer1.0-plugins-ugly

echo ">>> Trying to install WPE WebKit packages..."

# Method 1: Try standard package names
if sudo apt install -y libwpewebkit-2.0-1 cog 2>/dev/null; then
    echo ">>> Successfully installed from standard packages!"
    COG_PATH="/usr/bin/cog"
elif sudo apt install -y libwpewebkit-1.1-0 cog 2>/dev/null; then
    echo ">>> Successfully installed WebKit 1.1 from packages!"
    COG_PATH="/usr/bin/cog"
else
    echo ">>> Package installation failed, building from source..."
    
    # Install build dependencies
    sudo apt install -y \
      build-essential \
      cmake \
      meson \
      ninja-build \
      pkg-config \
      ruby \
      python3 \
      perl \
      libglib2.0-dev \
      libsoup-3.0-dev \
      libwebp-dev \
      libxslt1-dev \
      libgcrypt20-dev \
      libjpeg-dev \
      libpng-dev \
      libgl1-mesa-dev \
      libegl1-mesa-dev \
      libdrm-dev \
      libgbm-dev \
      libwayland-dev \
      wayland-protocols
    
    cd /tmp
    
    # Build libwpe
    echo ">>> Building libwpe..."
    wget -O libwpe-1.16.2.tar.xz https://wpewebkit.org/releases/libwpe-1.16.2.tar.xz
    tar -xf libwpe-1.16.2.tar.xz
    cd libwpe-1.16.2
    mkdir build && cd build
    cmake -DCMAKE_BUILD_TYPE=Release -GNinja ..
    ninja
    sudo ninja install
    sudo ldconfig
    cd /tmp
    
    # Build wpebackend-fdo
    echo ">>> Building wpebackend-fdo..."
    wget -O wpebackend-fdo-1.16.0.tar.xz https://wpewebkit.org/releases/wpebackend-fdo-1.16.0.tar.xz
    tar -xf wpebackend-fdo-1.16.0.tar.xz
    cd wpebackend-fdo-1.16.0
    meson setup build --buildtype=release
    ninja -C build
    sudo ninja -C build install
    sudo ldconfig
    cd /tmp
    
    # Build cog (lightweight, faster than WebKit)
    echo ">>> Building cog..."
    wget -O cog-0.18.5.tar.xz https://wpewebkit.org/releases/cog-0.18.5.tar.xz
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
    
    COG_PATH="/usr/local/bin/cog"
    
    # Clean up
    cd /
    rm -rf /tmp/libwpe-* /tmp/wpebackend-* /tmp/cog-*
    
    echo ">>> Build completed successfully!"
fi

echo ">>> Configuring boot config..."
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

# Power optimization
arm_freq=1200
over_voltage=2
temp_limit=75
force_turbo=0
EOF
fi

echo ">>> Configuring cmdline.txt..."
CMDLINE_FILE="/boot/firmware/cmdline.txt"
if [ ! -f "$CMDLINE_FILE" ]; then
  CMDLINE_FILE="/boot/cmdline.txt"
fi

sudo sed -i '1s/$/ quiet loglevel=3 logo.nologo vt.global_cursor_default=0/' "$CMDLINE_FILE"

echo ">>> Creating kiosk script..."
sudo tee /usr/local/bin/youtube-kiosk.sh >/dev/null <<EOF
#!/bin/bash
export XDG_RUNTIME_DIR=/run/user/\$(id -u)
LOGFILE="/var/log/youtube-kiosk.log"

# Create the log file if it doesn't exist
if [ ! -f "\$LOGFILE" ]; then
  sudo touch "\$LOGFILE"
  sudo chown \$(id -u):\$(id -g) "\$LOGFILE"
fi

echo "[INFO] Kiosk script started at \$(date)" >> "\$LOGFILE"

# Wait for network
until ping -c 1 -W 2 google.com &>/dev/null; do
  echo "[WARN] Waiting for network..." >> "\$LOGFILE"
  sleep 2
done

sleep 1

# Launch cog in kiosk mode with mouse support
$COG_PATH \\
  -P drm \\
  -O fullscreen=true \\
  --enable-media \\
  --enable-fullscreen \\
  --enable-javascript \\
  --enable-spatial-navigation=true \\
  --gamepad \\
  --user-agent="Mozilla/5.0 (X11; Linux armv7l) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" \\
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