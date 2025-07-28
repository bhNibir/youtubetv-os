# YouTube TV OS for Raspberry Pi 3B+

Transform your Raspberry Pi 3B+ into a dedicated YouTube TV streaming device using Raspberry Pi OS Lite! This project creates a lightweight kiosk-mode setup that boots directly into YouTube TV using WPE WebKit and Cog browser for optimal performance.

## 🚀 One-Command Installation

Run this command on your Raspberry Pi OS Lite system (as the 'pi' user):

### Option 1: Using curl
```bash
curl -sSL https://raw.githubusercontent.com/bhNibir/youtubetv-os/main/install.sh | bash
```

### Option 2: Using wget
```bash
wget -qO- https://raw.githubusercontent.com/bhNibir/youtubetv-os/main/install.sh | bash
```

## 📋 What This Script Does

1. **System Update** - Updates all Raspberry Pi OS packages
2. **Software Installation** - Installs:
   - Cog browser (WPE WebKit-based)
   - WPE WebKit libraries
   - GStreamer multimedia framework
   - Hardware acceleration support
3. **Boot Configuration** - Optimizes `/boot/config.txt` for:
   - KMS video driver (vc4-kms-v3d)
   - GPU memory allocation (256MB)
   - Disabled splash screen for faster boot
4. **Kiosk Setup** - Creates systemd service that:
   - Launches Cog browser in fullscreen
   - Uses Smart TV user agent for YouTube TV
   - Enables hardware-accelerated media playback
   - Waits for network connectivity
   - Auto-restarts on crashes
5. **Auto-reboot** - Reboots into YouTube TV kiosk mode

## 🎯 Features

- ✅ **Lightweight & Fast** - WPE WebKit is optimized for embedded devices
- ✅ **Hardware Acceleration** - Full GPU acceleration for smooth video playback
- ✅ **Smart TV Experience** - Proper user agent for YouTube TV interface
- ✅ **Auto-Start** - Boots directly into YouTube TV kiosk mode
- ✅ **Network Resilient** - Waits for connectivity and auto-restarts
- ✅ **Power Efficient** - Minimal resource usage, perfect for Pi 3B+
- ✅ **No X11 Overhead** - Direct DRM rendering for better performance

## 🔧 Prerequisites

- Raspberry Pi 3B+ with microSD card (16GB+ recommended)
- Raspberry Pi OS Lite (Bookworm 64-bit) installed and configured
- Wi-Fi or Ethernet connection configured
- SSH access to your Pi (run as 'pi' user, not root)

## 📱 Usage

After installation and reboot:
1. Your Pi will automatically boot into YouTube TV kiosk mode
2. Use a USB keyboard/mouse or Bluetooth remote for navigation
3. The system will automatically restart the browser if it crashes
4. Enjoy smooth, hardware-accelerated YouTube TV streaming!

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

To disable the YouTube TV kiosk and return to normal CLI:
```bash
sudo systemctl disable youtube-kiosk.service
sudo systemctl stop youtube-kiosk.service
sudo reboot
```

To re-enable:
```bash
sudo systemctl enable youtube-kiosk.service
sudo reboot
```

## 📞 Support

- **Issues**: Open an issue on this GitHub repository
- **Raspberry Pi Documentation**: https://www.raspberrypi.org/documentation/
- **WPE WebKit**: https://wpewebkit.org/
- **YouTube TV**: https://tv.youtube.com/

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

**Made with ❤️ for the Raspberry Pi community**