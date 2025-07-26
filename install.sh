#!/bin/bash

echo "📺 Setting up YouTube TV OS on DietPi for Raspberry Pi 3B+..."

# Step 1: System update
echo "🔄 Updating system packages..."
apt update && apt upgrade -y

# Step 2: Install required DietPi software
echo "📦 Installing required software packages..."
dietpi-software install 9   # Chromium
dietpi-software install 16  # X11
dietpi-software install 170 # Bluetooth
dietpi-software install 193 # ALSA
dietpi-software install 188 # NetworkManager
dietpi-software install 141 # Matchbox-keyboard

# Step 3: Set autostart to Chromium kiosk
echo "⚙️ Configuring autostart..."
sed -i 's/^AUTO_START_INDEX=.*/AUTO_START_INDEX=9/' /var/lib/dietpi/dietpi-autostart

# Step 4: Create Chromium Kiosk launcher
echo "🚀 Creating Chromium kiosk launcher..."
AUTOSTART_SCRIPT="/DietPi/dietpi/.chromium-autostart.sh"
cat <<EOF > $AUTOSTART_SCRIPT
#!/bin/bash
xset s off
xset -dpms
xset s noblank
unclutter -idle 0.5 -root &  # Hide mouse
matchbox-keyboard &         # On-screen keyboard
chromium \\
  --user-agent="Mozilla/5.0 (Linux; Android 9; SHIELD Android TV) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.81 Safari/537.36" \\
  --noerrdialogs --kiosk https://www.youtube.com/tv \\
  --disable-restore-session-state --no-first-run
EOF

chmod +x $AUTOSTART_SCRIPT

# Step 5: Enable and start Bluetooth
echo "📶 Configuring Bluetooth..."
systemctl enable bluetooth
systemctl start bluetooth

# Step 6: Autologin root on boot
echo "🔐 Setting up autologin..."
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat <<EOF > /etc/systemd/system/getty@tty1.service.d/autologin.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I \$TERM
EOF

# Step 7: Ensure autostart is set
echo "✅ Finalizing autostart configuration..."
dietpi-autostart 9

echo "✅ Setup Complete! Rebooting into YouTube TV Kiosk Mode..."
sleep 3
reboot