#!/bin/bash

# Setup script for YouTube TV OS
set -e

echo "🔧 Setting up YouTube TV OS..."

# Create directories
sudo mkdir -p /opt/youtubetv-os/{web,scripts,config}
sudo mkdir -p /home/pi/.config/openbox

# Install Node.js dependencies
echo "📦 Installing Node.js dependencies..."
cd /opt/youtubetv-os
sudo npm install express socket.io cors child_process

# Copy web files
echo "📁 Setting up web interface..."
sudo cp -r web/* /opt/youtubetv-os/web/
sudo cp -r scripts/* /opt/youtubetv-os/scripts/
sudo cp -r config/* /opt/youtubetv-os/config/

# Set permissions
sudo chown -R pi:pi /opt/youtubetv-os
sudo chmod +x /opt/youtubetv-os/scripts/*.sh

# Configure auto-login
echo "🔐 Configuring auto-login..."
sudo systemctl enable lightdm
sudo mkdir -p /etc/lightdm/lightdm.conf.d
sudo tee /etc/lightdm/lightdm.conf.d/01-autologin.conf > /dev/null <<EOF
[Seat:*]
autologin-user=pi
autologin-user-timeout=0
EOF

# Configure Openbox
echo "🖥️ Configuring window manager..."
sudo tee /home/pi/.config/openbox/autostart > /dev/null <<'EOF'
# Hide cursor
unclutter -idle 0.1 -root &

# Start the YouTube TV OS server
cd /opt/youtubetv-os && node server.js &

# Wait for server to start
sleep 3

# Launch Chromium in kiosk mode
chromium-browser \
  --kiosk \
  --no-sandbox \
  --disable-infobars \
  --disable-session-crashed-bubble \
  --disable-restore-session-state \
  --disable-web-security \
  --disable-features=VizDisplayCompositor \
  --start-fullscreen \
  --window-position=0,0 \
  --window-size=1920,1080 \
  --autoplay-policy=no-user-gesture-required \
  http://localhost:8080
EOF

# Create systemd service for the server
echo "🔧 Creating system service..."
sudo tee /etc/systemd/system/youtubetv-os.service > /dev/null <<EOF
[Unit]
Description=YouTube TV OS Server
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/opt/youtubetv-os
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
sudo systemctl enable youtubetv-os.service

# Configure boot to desktop
echo "🖥️ Configuring boot to desktop..."
sudo systemctl set-default graphical.target

# Set GPU memory split for better video performance
echo "🎮 Optimizing GPU memory..."
echo "gpu_mem=128" | sudo tee -a /boot/config.txt

echo "✅ Setup complete!"