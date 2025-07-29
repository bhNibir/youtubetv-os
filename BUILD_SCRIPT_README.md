# WPE WebKit Manual Build Script

This script allows you to build WPE WebKit, libwpe, and wpebackend-fdo manually on Ubuntu and generate .deb packages for ARM64 (Raspberry Pi).

## Prerequisites

- Ubuntu 20.04 or later
- At least 20GB of free disk space
- Internet connection for downloading dependencies and source code
- sudo privileges

## Quick Start

1. **Download the script:**
   ```bash
   wget https://raw.githubusercontent.com/your-repo/youtubetv-os/main/build-wpewebkit-manual.sh
   ```

2. **Make it executable:**
   ```bash
   chmod +x build-wpewebkit-manual.sh
   ```

3. **Run the script:**
   ```bash
   ./build-wpewebkit-manual.sh
   ```

## Usage Options

### Build Everything (Default)
```bash
./build-wpewebkit-manual.sh
```
This will:
- Install all dependencies
- Build libwpe
- Build wpebackend-fdo
- Build WPE WebKit
- Generate .deb packages

### Build Only Dependencies
```bash
./build-wpewebkit-manual.sh --deps-only
```
This will only build libwpe and wpebackend-fdo.

### Build Only WebKit
```bash
./build-wpewebkit-manual.sh --webkit-only
```
This will only build WPE WebKit (requires dependencies to be already built).

### Clean Build
```bash
./build-wpewebkit-manual.sh --clean
```
This will clean all build artifacts and start fresh.

### Show Help
```bash
./build-wpewebkit-manual.sh --help
```

## What the Script Does

### 1. Dependency Installation
- Adds ARM64 architecture support
- Installs cross-compilation toolchain
- Installs all required development libraries
- Sets up Python and GObject Introspection

### 2. Build Environment Setup
- Configures ccache for faster rebuilds
- Sets up environment variables for cross-compilation
- Configures pkg-config for ARM64

### 3. Building Components

#### libwpe
- Downloads libwpe 1.16.2 source
- Configures with CMake for ARM64
- Builds with Ninja
- Creates .deb package

#### wpebackend-fdo
- Downloads wpebackend-fdo 1.16.0 source
- Configures with Meson for ARM64
- Builds with Ninja
- Creates .deb package

#### WPE WebKit
- Downloads WPE WebKit 2.48.4 source
- Configures with CMake for ARM64
- Builds with Ninja (uses all CPU cores)
- Creates .deb package

### 4. Package Generation
Each component generates a .deb package:
- `libwpe-aarch64-rpi3b-v1.16.2.deb`
- `wpebackend-fdo-aarch64-rpi3b-v1.16.0.deb`
- `wpewebkit-aarch64-rpi3b-v2.48.4.deb`

## Output Files

After successful build, you'll have:
```
libwpe-aarch64-rpi3b-v1.16.2.deb
wpebackend-fdo-aarch64-rpi3b-v1.16.0.deb
wpewebkit-aarch64-rpi3b-v2.48.4.deb
```

## Installing on Raspberry Pi

Copy the .deb files to your Raspberry Pi and install:

```bash
# On Raspberry Pi
sudo dpkg -i *.deb
sudo apt-get install -f  # Fix any dependency issues
```

## Troubleshooting

### Disk Space Issues
The script checks for available disk space and warns if less than 20GB is available. WebKit builds can be very large.

### Permission Issues
Make sure you're not running the script as root. It will use sudo when needed.

### Build Failures
- Check that all dependencies are installed
- Ensure you have enough disk space
- Try running with `--clean` to start fresh

### Network Issues
The script downloads several large files. Ensure you have a stable internet connection.

## Build Time

Typical build times on a modern system:
- Dependencies installation: 5-10 minutes
- libwpe: 2-5 minutes
- wpebackend-fdo: 2-5 minutes
- WPE WebKit: 30-60 minutes

Total time: 1-2 hours depending on your system.

## System Requirements

- **CPU**: Multi-core processor (4+ cores recommended)
- **RAM**: 8GB minimum, 16GB recommended
- **Disk Space**: 20GB minimum free space
- **OS**: Ubuntu 20.04 or later

## Features

- **Colored output** for better readability
- **Progress indicators** for each build step
- **Disk space monitoring** to prevent failures
- **Caching** with ccache for faster rebuilds
- **Error handling** with detailed error messages
- **Cleanup** of temporary files after each build
- **Statistics** showing build cache and package sizes

## Customization

You can modify the script to:
- Change versions of components
- Add/remove build options
- Modify package names
- Change build directories

## Support

If you encounter issues:
1. Check the error messages
2. Ensure all prerequisites are met
3. Try running with `--clean` option
4. Check disk space and system resources