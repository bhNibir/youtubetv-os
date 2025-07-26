# YouTube TV OS for Raspberry Pi 3B+

Transform your Raspberry Pi 3B+ into a dedicated YouTube TV streaming device using DietPi! This project creates a kiosk-mode setup that boots directly into YouTube TV with Android TV user agent for the best experience.

## 🚀 One-Command Installation

Since DietPi's Wi-Fi is already configured before SSH login, installation is super simple:

### Option 1: Using curl
```bash
curl -sSL https://raw.githubusercontent.com/bhNibir/youtubetv-os/main/install.sh | bash
```

### Option 2: Using wget
```bash
wget -qO- https://raw.githubusercontent.com/bhNibir/youtubetv-os/main/install.sh | bash
```

## 📋 What This Script Does

1. **System Update** - Updates all DietPi packages
2. **Software Installation** - Installs:
   - Chromium browser
   - X11 display server
   - Bluetooth support
   - ALSA audio system
   - NetworkManager
   - Matchbox on-screen keyboard
3. **Kiosk Configuration** - Sets up Chromium to:
   - Launch in fullscreen kiosk mode
   - Use Android TV user agent
   - Hide mouse cursor
   - Disable screen blanking
   - Load YouTube TV automatically
4. **Auto-login Setup** - Configures automatic root login
5. **Bluetooth Enable** - Enables Bluetooth for remote controls
6. **Auto-reboot** - Reboots into YouTube TV mode

## 🎯 Features

- ✅ **No Wi-Fi Configuration Needed** - Uses DietPi's pre-configured network
- ✅ **Android TV Experience** - Proper user agent for YouTube TV interface
- ✅ **Bluetooth Support** - Connect wireless keyboards/remotes
- ✅ **On-Screen Keyboard** - Touch-friendly input method
- ✅ **Auto-Start** - Boots directly into YouTube TV
- ✅ **Power Efficient** - Optimized for Raspberry Pi 3B+

## 🔧 Prerequisites

- Raspberry Pi 3B+ with microSD card (16GB+ recommended)
- DietPi OS installed and configured with Wi-Fi
- SSH access to your Pi

## 📱 Usage

After installation and reboot:
1. Your Pi will automatically boot into YouTube TV
2. Use a Bluetooth keyboard/remote for navigation
3. Touch the screen to bring up the on-screen keyboard if needed
4. Enjoy your dedicated YouTube TV streaming device!

## 🛠️ Manual Installation

If you prefer to run the script manually:

1. Download the script:
   ```bash
   wget https://raw.githubusercontent.com/bhNibir/youtubetv-os/main/install.sh
   ```

2. Make it executable:
   ```bash
   chmod +x install.sh
   ```

3. Run it:
   ```bash
   sudo ./install.sh
   ```

## 🔄 Reverting Changes

To return to normal DietPi desktop:
```bash
sudo dietpi-autostart 2  # LXDE Desktop
sudo reboot
```

## 📞 Support

- **Issues**: Open an issue on this GitHub repository
- **DietPi Documentation**: https://dietpi.com/docs/
- **YouTube TV**: https://tv.youtube.com/

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

**Made with ❤️ for the Raspberry Pi community**