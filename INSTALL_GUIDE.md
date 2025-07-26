# Installation Guide for YouTube TV OS

## Step-by-Step Installation

### 1. Prepare Your Raspberry Pi

1. **Flash Raspberry Pi OS Lite** to your SD card using Raspberry Pi Imager
2. **Enable SSH** (optional, for remote setup):
   - Create an empty file named `ssh` in the boot partition
3. **Configure WiFi** (optional, for headless setup):
   - Create `wpa_supplicant.conf` in the boot partition with your WiFi credentials
4. **Boot your Pi** and connect via SSH or directly with keyboard/monitor

### 2. Run the Installation

**Option A: One-Command Install (Recommended)**
```bash
curl -sSL https://raw.githubusercontent.com/bhNibir/youtubetv-os/main/install.sh | bash
```

**Option B: Manual Install**
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Clone repository
git clone https://github.com/bhNibir/youtubetv-os.git
cd youtubetv-os

# Make scripts executable
chmod +x install.sh setup.sh scripts/*.sh

# Run installer
sudo ./install.sh
```

### 3. Post-Installation

After the system reboots:
1. The YouTube TV OS interface will start automatically
2. Use your TV remote or keyboard to navigate
3. Configure WiFi and Bluetooth as needed
4. Click "YouTube TV" to start streaming

## File Structure

```
youtubetv-os/
├── web/                    # Web interface files
│   ├── index.html         # Main HTML interface
│   ├── app.js            # JavaScript application logic
│   ├── styles.css        # Main stylesheet
│   └── virtual-keyboard.css # Virtual keyboard styles
├── scripts/               # System management scripts
│   ├── wifi-manager.sh   # WiFi management utilities
│   └── bluetooth-manager.sh # Bluetooth management utilities
├── config/               # Configuration files
│   └── settings.json     # System settings
├── server.js            # Node.js web server
├── package.json         # Node.js dependencies
├── install.sh          # Main installation script
├── setup.sh            # System setup script
├── deploy.sh           # Deployment preparation script
└── README.md           # Project documentation
```

## Customization

### Adding Custom Apps
Edit `config/settings.json` to add more streaming services:

```json
{
  "defaultApps": [
    {
      "name": "Your App",
      "url": "https://your-app.com",
      "icon": "🎬",
      "color": "#ff6b6b"
    }
  ]
}
```

### Changing Themes
The system supports dark and light themes. You can customize colors by editing the CSS variables in `web/styles.css`.

### Remote Control Configuration
Most TV remotes work automatically via HDMI-CEC. For custom remotes, modify the key mappings in the settings.

## Troubleshooting

### Common Commands
```bash
# Check service status
sudo systemctl status youtubetv-os

# Restart service
sudo systemctl restart youtubetv-os

# View logs
journalctl -u youtubetv-os -f

# Access web interface directly
curl http://localhost:8080
```

### Reset to Defaults
```bash
cd /opt/youtubetv-os
sudo cp config/settings.json.backup config/settings.json
sudo systemctl restart youtubetv-os
```

## Performance Optimization

### For Raspberry Pi 3B+
- Ensure GPU memory split is set to 128MB or higher
- Use a fast SD card (Class 10 or better)
- Consider overclocking for better video performance

### For Raspberry Pi 4
- Increase GPU memory to 256MB for 4K video
- Enable hardware acceleration in Chromium
- Use USB 3.0 for external storage if needed

## Security Notes

- The system runs a web server on port 8080
- WiFi passwords are stored in plain text (standard Linux behavior)
- Bluetooth pairing follows standard security protocols
- The system is designed for local network use

## Updates and Maintenance

### Updating the System
```bash
cd /opt/youtubetv-os
sudo git pull
sudo systemctl restart youtubetv-os
```

### Backing Up Settings
```bash
sudo cp /opt/youtubetv-os/config/settings.json ~/settings-backup.json
```

### Factory Reset
```bash
sudo rm -rf /opt/youtubetv-os
# Then run the installer again
```

This YouTube TV OS provides a complete, ready-to-use smart TV experience for your Raspberry Pi. Enjoy streaming!