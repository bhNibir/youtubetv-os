# YouTube TV OS for Raspberry Pi 3B+

A minimal, web-based smart TV operating system designed specifically for Raspberry Pi 3B+. Transform your Pi into a dedicated YouTube TV streaming device with a beautiful control panel interface.

![YouTube TV OS Interface](https://via.placeholder.com/800x450/0f0f0f/ffffff?text=YouTube+TV+OS+Interface)

## ✨ Features

### 🎯 Core Functionality
- **YouTube TV Integration** - Direct access to YouTube TV with optimized interface
- **WiFi Management** - Scan, connect, and manage wireless networks
- **Bluetooth Support** - Connect wireless controllers, keyboards, and audio devices
- **Power Management** - Safe shutdown and reboot options
- **System Monitoring** - Real-time system information and status

### 🎨 User Interface
- **Modern TV-Optimized UI** - Clean, card-based interface designed for TV screens
- **Dark/Light Themes** - Switch between dark and light modes
- **TV Remote Navigation** - Full support for TV remote control navigation
- **Virtual Keyboard** - On-screen keyboard for text input
- **Responsive Design** - Works on various screen sizes

### 🔧 Smart Features
- **Web Browser Integration** - Search the web or navigate to any URL
- **Auto-Start** - Boots directly into the TV interface
- **Kiosk Mode** - Full-screen experience without desktop distractions
- **Settings Panel** - Customize system behavior and preferences

## 🚀 Quick Install

### One-Command Installation
Run this on a fresh **Raspberry Pi OS Lite** installation:

```bash
curl -sSL https://raw.githubusercontent.com/bhNibir/youtubetv-os/main/install.sh | bash
```

### What the installer does:
1. Updates system packages
2. Installs required dependencies (Node.js, Chromium, etc.)
3. Sets up the web server and interface
4. Configures auto-login and kiosk mode
5. Optimizes GPU memory for video playback
6. Reboots into the YouTube TV OS

## 📋 Requirements

### Hardware
- **Raspberry Pi 3B+** or newer (Pi 4 recommended for better performance)
- **MicroSD Card** - 16GB or larger, Class 10 recommended
- **HDMI Display** - TV or monitor with HDMI input
- **Power Supply** - Official Raspberry Pi power adapter
- **Internet Connection** - WiFi or Ethernet

### Software
- **Raspberry Pi OS Lite** (latest version)
- Fresh installation recommended for best results

## 🛠️ Manual Installation

If you prefer to install manually or want to customize the setup:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/bhNibir/youtubetv-os.git
   cd youtubetv-os
   ```

2. **Make scripts executable:**
   ```bash
   chmod +x install.sh setup.sh scripts/*.sh
   ```

3. **Run the installer:**
   ```bash
   sudo ./install.sh
   ```

## 🎮 Usage

### Navigation
- **TV Remote:** Use arrow keys for navigation, Enter to select, and Back/Escape to go back
- **Keyboard:** Arrow keys, Enter, Escape, and Tab for navigation
- **Mouse:** Click on any element (useful for setup)

### Control Panel Features

#### 📶 WiFi Management
- Scan for available networks
- Connect to secured and open networks
- View connection status and signal strength
- Disconnect from current network

#### 🔵 Bluetooth Management
- Scan for nearby Bluetooth devices
- Pair and connect devices (controllers, keyboards, speakers)
- Manage connected devices
- View device status

#### 🔍 Search & Browse
- Search the web using Google
- Navigate directly to any URL
- Built-in virtual keyboard for text input

#### ⚙️ Settings
- Toggle virtual keyboard on/off
- Switch between dark and light themes
- Configure auto-connect preferences
- System configuration options

#### ⏻ Power Management
- Safe system shutdown
- System reboot
- View system information (uptime, memory, CPU, temperature)

### Accessing YouTube TV
Click the **YouTube TV** card to navigate directly to `https://www.youtube.com/tv` for the full YouTube TV experience.

## 🔧 Configuration

### Settings File
The system settings are stored in `/opt/youtubetv-os/config/settings.json`:

```json
{
  "theme": "dark",
  "virtualKeyboard": true,
  "autoConnect": false,
  "screenTimeout": 0
}
```

### Custom Apps
You can add custom streaming apps by modifying the settings file to include additional app cards.

### Remote Control Setup
The system supports standard TV remote controls through HDMI-CEC. Most modern TVs will work automatically.

## 🐛 Troubleshooting

### Common Issues

**System won't boot to the interface:**
- Check that the installation completed successfully
- Verify the service is running: `sudo systemctl status youtubetv-os`
- Check logs: `journalctl -u youtubetv-os`

**WiFi not working:**
- Ensure your Pi has WiFi capability
- Check that the WiFi adapter is enabled: `sudo rfkill unblock wifi`
- Verify network credentials

**Bluetooth issues:**
- Make sure Bluetooth is enabled: `sudo systemctl enable bluetooth`
- Check Bluetooth status: `sudo bluetoothctl show`

**Performance issues:**
- Ensure GPU memory is set correctly in `/boot/config.txt`
- Consider using a faster SD card (Class 10 or better)
- Use a Pi 4 for better performance

### Getting Help
- Check the system logs: `journalctl -u youtubetv-os -f`
- Restart the service: `sudo systemctl restart youtubetv-os`
- Access the web interface directly: `http://localhost:8080`

## 🔄 Updates

To update the YouTube TV OS:

```bash
cd /opt/youtubetv-os
sudo git pull
sudo systemctl restart youtubetv-os
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Setup
1. Clone the repository
2. Install dependencies: `npm install`
3. Run in development mode: `npm run dev`
4. Access at `http://localhost:8080`

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built for the Raspberry Pi community
- Inspired by modern smart TV interfaces
- Uses open-source technologies: Node.js, Express, Socket.IO

## 📞 Support

If you encounter any issues or have questions:
1. Check the troubleshooting section above
2. Search existing GitHub issues
3. Create a new issue with detailed information about your setup and the problem

---

**Made with ❤️ for the Raspberry Pi community**