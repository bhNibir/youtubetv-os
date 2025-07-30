#!/bin/bash

# WPE WebKit Manual Build Script
# This script builds WPE WebKit, libwpe, and wpebackend-fdo on Ubuntu
# and generates .deb packages for ARM64 (Raspberry Pi)

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check disk space
check_disk_space() {
    local available_space=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$available_space" -lt 20 ]; then
        print_warning "Low disk space: ${available_space}G available. Recommended: 20G+"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Function to check and fix repository configuration
check_repository_config() {
    print_status "Checking repository configuration..."
    
    # Get Ubuntu version
    UBUNTU_VERSION=$(lsb_release -cs)
    echo "Ubuntu version: $UBUNTU_VERSION"
    
    # Completely reset apt configuration to bypass mirror system (same as GitHub workflow)
    print_status "Resetting apt configuration to bypass mirror system..."
    sudo rm -rf /etc/apt/sources.list.d/
    sudo mkdir -p /etc/apt/sources.list.d/
    sudo rm -f /etc/apt/sources.list
    sudo rm -f /etc/apt/apt-mirrors.txt
    sudo rm -f /etc/apt/apt.conf.d/*mirror*
    sudo rm -f /etc/apt/apt.conf.d/*Mirror*
    
    # Clear all apt caches and lists
    sudo apt-get clean
    sudo rm -rf /var/lib/apt/lists/*
    
    # Create AMD64 sources.list using echo (same as GitHub workflow)
    echo "deb [arch=amd64] http://archive.ubuntu.com/ubuntu/ $UBUNTU_VERSION main restricted universe multiverse" | sudo tee /etc/apt/sources.list
    echo "deb [arch=amd64] http://archive.ubuntu.com/ubuntu/ $UBUNTU_VERSION-updates main restricted universe multiverse" | sudo tee -a /etc/apt/sources.list
    echo "deb [arch=amd64] http://archive.ubuntu.com/ubuntu/ $UBUNTU_VERSION-backports main restricted universe multiverse" | sudo tee -a /etc/apt/sources.list
    echo "deb [arch=amd64] http://archive.ubuntu.com/ubuntu/ $UBUNTU_VERSION-security main restricted universe multiverse" | sudo tee -a /etc/apt/sources.list
    
    # Create ARM64 sources file using echo (same as GitHub workflow)
    echo "deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports/ $UBUNTU_VERSION main restricted universe multiverse" | sudo tee /etc/apt/sources.list.d/arm64.list
    echo "deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports/ $UBUNTU_VERSION-updates main restricted universe multiverse" | sudo tee -a /etc/apt/sources.list.d/arm64.list
    echo "deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports/ $UBUNTU_VERSION-backports main restricted universe multiverse" | sudo tee -a /etc/apt/sources.list.d/arm64.list
    echo "deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports/ $UBUNTU_VERSION-security main restricted universe multiverse" | sudo tee -a /etc/apt/sources.list.d/arm64.list
    
    # Force apt to use direct sources without mirrors (same as GitHub workflow)
    echo 'Acquire::http::Pipeline-Depth "0";' | sudo tee /etc/apt/apt.conf.d/99-direct-sources
    echo 'Acquire::http::No-Cache=True;' | sudo tee -a /etc/apt/apt.conf.d/99-direct-sources
    echo 'APT::Get::AllowUnauthenticated "false";' | sudo tee -a /etc/apt/apt.conf.d/99-direct-sources
    
    # Update package lists
    print_status "Updating package lists..."
    sudo apt-get update -qq
    
    # Fallback: If update fails, try with different approach (same as GitHub workflow)
    if [ $? -ne 0 ]; then
        print_warning "First apt update failed, trying alternative approach..."
        # Remove all apt configuration and start fresh
        sudo rm -f /etc/apt/sources.list
        sudo rm -f /etc/apt/sources.list.d/*
        sudo rm -f /etc/apt/apt.conf.d/99-direct-sources
        sudo mkdir -p /etc/apt/sources.list.d/
        
        # Use minimal sources with echo
        echo "deb [arch=amd64] http://archive.ubuntu.com/ubuntu/ $UBUNTU_VERSION main" | sudo tee /etc/apt/sources.list
        echo "deb [arch=amd64] http://archive.ubuntu.com/ubuntu/ $UBUNTU_VERSION-security main" | sudo tee -a /etc/apt/sources.list
        
        echo "deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports/ $UBUNTU_VERSION main" | sudo tee /etc/apt/sources.list.d/arm64.list
        echo "deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports/ $UBUNTU_VERSION-security main" | sudo tee -a /etc/apt/sources.list.d/arm64.list
        
        sudo apt-get clean
        sudo rm -rf /var/lib/apt/lists/*
        sudo apt-get update -qq
    fi
    
    # Third fallback: If still failing, try with environment variables (same as GitHub workflow)
    if [ $? -ne 0 ]; then
        print_warning "Second approach also failed, trying with environment variables..."
        # Set environment variables to bypass mirror system
        export APT_CONFIG=/dev/null
        export APT_CONFIG_FILE=/dev/null
        
        sudo rm -f /etc/apt/sources.list
        sudo rm -f /etc/apt/sources.list.d/*
        echo "deb [arch=amd64] http://archive.ubuntu.com/ubuntu/ $UBUNTU_VERSION main restricted universe multiverse" | sudo tee /etc/apt/sources.list
        echo "deb [arch=amd64] http://archive.ubuntu.com/ubuntu/ $UBUNTU_VERSION-security main restricted universe multiverse" | sudo tee -a /etc/apt/sources.list
        
        echo "deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports/ $UBUNTU_VERSION main restricted universe multiverse" | sudo tee /etc/apt/sources.list.d/arm64.list
        echo "deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports/ $UBUNTU_VERSION-security main restricted universe multiverse" | sudo tee -a /etc/apt/sources.list.d/arm64.list
        
        sudo apt-get clean
        sudo rm -rf /var/lib/apt/lists/*
        sudo apt-get update -qq
    fi
    
    # Clean up temporary apt configuration
    sudo rm -f /etc/apt/apt.conf.d/99-direct-sources
    
    print_success "Repository configuration completed"
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    # Add ARM64 architecture
    sudo dpkg --add-architecture arm64
    
    # Install essential build tools
    sudo apt-get install -y \
        ninja-build cmake build-essential \
        g++-aarch64-linux-gnu gcc-aarch64-linux-gnu \
        qemu-user-static \
        python3 ruby unifdef fakeroot meson bubblewrap xdg-dbus-proxy gperf ccache
    
    # Install Python dependencies and development libraries (host architecture)
    sudo apt-get install -y \
        python3-setuptools python3-pip python3-gi python3-gi-cairo \
        python3-dev python3-venv \
        libcairo2-dev libglib2.0-dev libgirepository1.0-dev \
        gobject-introspection libgirepository1.0-dev
    
    # Install ARM64 GObject Introspection packages for cross-compilation (with fallbacks)
    print_status "Installing ARM64 GObject Introspection packages..."
    
    # First try to install the basic ARM64 packages
    if sudo apt-get install -y python3-gi:arm64 python3-gi-cairo:arm64 libgirepository1.0-dev:arm64 libglib2.0-dev:arm64 libcairo2-dev:arm64; then
        print_success "ARM64 GObject packages installed successfully"
    else
        print_warning "Some ARM64 GObject packages failed, trying minimal set..."
        # Try minimal set without gobject-introspection:arm64
        sudo apt-get install -y libgirepository1.0-dev:arm64 libglib2.0-dev:arm64 libcairo2-dev:arm64 || true
    fi
    
    # Try to install gobject-introspection:arm64 separately (it might have dependency issues)
    if sudo apt-get install -y gobject-introspection:arm64; then
        print_success "gobject-introspection:arm64 installed successfully"
    else
        print_warning "gobject-introspection:arm64 has dependency issues, trying to fix..."
        # Try to install the missing dependencies
        if sudo apt-get install -y gobject-introspection-bin:arm64 gobject-introspection-bin-linux:arm64; then
            print_success "gobject-introspection dependencies installed"
            # Now try gobject-introspection:arm64 again
            sudo apt-get install -y gobject-introspection:arm64 || print_warning "gobject-introspection:arm64 still not available, will use host version"
        else
            print_warning "gobject-introspection:arm64 not available, will use host version"
            # The host gobject-introspection should work for cross-compilation
        fi
    fi
    
    # Install Python packages (with fallback if pip fails)
    print_status "Installing Python packages..."
    if pip3 install --upgrade pip setuptools wheel; then
        print_success "Python packages upgraded successfully"
    else
        print_warning "pip upgrade failed, continuing with system packages"
    fi
    
    # Try to install pygobject via pip, but don't fail if it doesn't work
    if pip3 install pygobject; then
        print_success "pygobject installed via pip"
    else
        print_warning "pygobject pip installation failed, using system package"
        # The system package python3-gi should be sufficient
    fi
    
    # Install ARM64 development libraries
    print_status "Installing ARM64 development libraries..."
    sudo apt-get install -y \
        libicu-dev:arm64 libharfbuzz-dev:arm64 \
        libglib2.0-dev:arm64 libgstreamer1.0-dev:arm64 \
        libgstreamer-plugins-base1.0-dev:arm64 \
        libjpeg-dev:arm64 libpng-dev:arm64 libwebp-dev:arm64 \
        libxml2-dev:arm64 libxslt1-dev:arm64 \
        libsqlite3-dev:arm64 libsoup-3.0-dev:arm64 \
        libepoxy-dev:arm64 libgcrypt20-dev:arm64 libtasn1-6-dev:arm64 \
        libxkbcommon-dev:arm64 \
        libwayland-dev:arm64 wayland-protocols \
        libdrm-dev:arm64 libgbm-dev:arm64 \
        libinput-dev:arm64 libudev-dev:arm64 \
        libavcodec-dev:arm64 libavformat-dev:arm64 libavutil-dev:arm64 \
        libgl1-mesa-dev:arm64 libegl1-mesa-dev:arm64 \
        libsystemd-dev:arm64 libsecret-1-dev:arm64 \
        libgirepository1.0-dev:arm64 \
        libgstreamer-plugins-bad1.0-dev:arm64 \
        libgstreamer-plugins-good1.0-dev:arm64 \
        pkg-config:arm64 linux-libc-dev:arm64 libatk1.0-dev:arm64 \
        libatk-bridge2.0-dev:arm64 flite1-dev:arm64 libjxl-dev:arm64 \
        libwoff-dev:arm64 libavif-dev:arm64 libseccomp-dev:arm64 \
        libfontconfig1-dev:arm64 libcairo2-dev:arm64
    
    # Clean up any broken packages
    print_status "Cleaning up package system..."
    sudo apt-get autoremove -y || true
    sudo apt-get autoclean || true
    
    print_success "Dependencies installed successfully"
}

# Function to set up build environment
setup_build_environment() {
    print_status "Setting up build environment..."
    
    # Set up ccache for faster rebuilds
    export CCACHE_DIR=~/.cache/ccache
    export CCACHE_MAXSIZE=5G
    export CCACHE_COMPRESS=1
    export CCACHE_COMPRESSLEVEL=9
    ccache -s
    
    # Set up pkg-config for cross-compilation
    export PKG_CONFIG_PATH="/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/share/pkgconfig"
    export PKG_CONFIG_LIBDIR="/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/share/pkgconfig"
    
    # Set up GObject Introspection for cross-compilation
    export GI_SCANNER_DISABLE_CACHE=1
    export GI_CROSS_LAUNCHER=qemu-aarch64-static
    export GI_CROSS_COMPILER=aarch64-linux-gnu-gcc
    export GI_CROSS_PKG_CONFIG_PATH="/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/share/pkgconfig"
    
    # Set up Python environment for cross-compilation
    # Check if ARM64 Python packages are available
    if [ -d "/usr/lib/aarch64-linux-gnu/python3/dist-packages" ]; then
        export PYTHONPATH="/usr/lib/python3/dist-packages:/usr/lib/aarch64-linux-gnu/python3/dist-packages:$PYTHONPATH"
        print_success "ARM64 Python packages found"
    else
        export PYTHONPATH="/usr/lib/python3/dist-packages:$PYTHONPATH"
        print_warning "ARM64 Python packages not found, using host packages"
    fi
    
    export GI_SCANNER_DEBUG=1
    export PYTHONUNBUFFERED=1
    export PYTHONDONTWRITEBYTECODE=1
    
    # Additional GObject Introspection environment variables
    export GI_SCANNER_EXTRA_ARGS="--no-libtool"
    export GI_SCANNER_QUIET=1
    export GI_SCANNER_WARN_ALL=1
    export GI_SCANNER_WARN_ERROR=1
    
    # Set up cross-compilation environment
    export CC=aarch64-linux-gnu-gcc
    export CXX=aarch64-linux-gnu-g++
    export AR=aarch64-linux-gnu-ar
    export STRIP=aarch64-linux-gnu-strip
    export RANLIB=aarch64-linux-gnu-ranlib
    export LD=aarch64-linux-gnu-ld
    export PKG_CONFIG=aarch64-linux-gnu-pkg-config
    
    # Set up ccache for cross-compilation (without prefix)
    # ccache will automatically detect the compiler from CC and CXX
    export CCACHE_CPP2=1
    export CCACHE_SLOPPINESS=file_macro,time_macros,include_file_mtime,include_file_ctime
    
    # Verify ARM64 GObject Introspection setup
    print_status "Verifying ARM64 GObject Introspection setup..."
    if [ -f "/usr/lib/aarch64-linux-gnu/libgirepository-1.0.so" ]; then
        print_success "ARM64 GObject Introspection library found"
    else
        print_warning "ARM64 GObject Introspection library not found, using host version"
    fi
    
    print_success "Build environment configured for ARM64 cross-compilation"
}

# Function to build libwpe
build_libwpe() {
    print_status "Building libwpe..."
    
    # Clean up any existing libwpe directory
    if [ -d "libwpe-1.16.2" ]; then
        print_status "Cleaning up existing libwpe directory..."
        rm -rf libwpe-1.16.2
    fi
    
    # Download and extract libwpe
    wget -q https://wpewebkit.org/releases/libwpe-1.16.2.tar.xz
    tar -xf libwpe-1.16.2.tar.xz
    cd libwpe-1.16.2
    
    # Create build directory
    mkdir build && cd build
    
    # Configure with CMake
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
        -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ \
        -DCMAKE_C_COMPILER_LAUNCHER=ccache \
        -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
        -GNinja
    
    # Build
    ninja
    
    # Install
    sudo ninja install
    
    # Create .deb package
    print_status "Creating libwpe .deb package..."
    cd ../..
    
    # Create package structure
    mkdir -p libwpe-deb-root/DEBIAN
    mkdir -p libwpe-deb-root/usr/lib/aarch64-linux-gnu
    mkdir -p libwpe-deb-root/usr/include
    mkdir -p libwpe-deb-root/usr/lib/aarch64-linux-gnu/pkgconfig
    
    # Create control file
    cat <<EOF > libwpe-deb-root/DEBIAN/control
Package: libwpe-1.0
Version: 1.16.2
Section: libs
Priority: optional
Architecture: arm64
Maintainer: bhNibir <nibir@example.com>
Description: WPE (WebKit Port for Embedded) library for Raspberry Pi 3B+
EOF
    
    # Copy files
    sudo cp -r /usr/lib/aarch64-linux-gnu/libwpe* libwpe-deb-root/usr/lib/aarch64-linux-gnu/
    sudo cp -r /usr/include/wpe-1.0 libwpe-deb-root/usr/include/
    sudo cp -r /usr/lib/aarch64-linux-gnu/pkgconfig/wpe* libwpe-deb-root/usr/lib/aarch64-linux-gnu/pkgconfig/
    
    # Fix permissions for dpkg-deb
    sudo chmod 755 libwpe-deb-root/DEBIAN
    sudo chmod 644 libwpe-deb-root/DEBIAN/control
    sudo chown -R root:root libwpe-deb-root
    
    # Create .deb package
    fakeroot dpkg-deb --build libwpe-deb-root libwpe-aarch64-rpi3b-v1.16.2.deb
    
    # Clean up
    sudo rm -rf libwpe-deb-root
    rm -rf libwpe-1.16.2
    
    print_success "libwpe built and packaged successfully"
}

# Function to build wpebackend-fdo
build_wpebackend_fdo() {
    print_status "Building wpebackend-fdo..."
    
    # Clean up any existing wpebackend-fdo directory
    if [ -d "wpebackend-fdo-1.16.0" ]; then
        print_status "Cleaning up existing wpebackend-fdo directory..."
        rm -rf wpebackend-fdo-1.16.0
    fi
    
    # Download and extract wpebackend-fdo
    wget -q https://wpewebkit.org/releases/wpebackend-fdo-1.16.0.tar.xz
    tar -xf wpebackend-fdo-1.16.0.tar.xz
    cd wpebackend-fdo-1.16.0
    
    # Create build directory
    mkdir build && cd build
    
    # Create cross-compilation configuration for Meson
    cat > cross-file.txt << 'EOF'
[binaries]
c = 'aarch64-linux-gnu-gcc'
cpp = 'aarch64-linux-gnu-g++'
ar = 'aarch64-linux-gnu-ar'
strip = 'aarch64-linux-gnu-strip'
pkgconfig = 'aarch64-linux-gnu-pkg-config'

[built-in options]
c_args = []
c_link_args = []
cpp_args = []
cpp_link_args = []

[host_machine]
system = 'linux'
cpu_family = 'aarch64'
cpu = 'aarch64'
endian = 'little'
EOF
    
    # Configure with Meson
    meson setup .. \
        --buildtype=release \
        --prefix=/usr \
        --cross-file=cross-file.txt
    
    # Build
    ninja
    
    # Install
    sudo ninja install
    
    # Create .deb package
    print_status "Creating wpebackend-fdo .deb package..."
    cd ../..
    
    # Create package structure
    mkdir -p wpebackend-deb-root/DEBIAN
    mkdir -p wpebackend-deb-root/usr/lib/aarch64-linux-gnu
    mkdir -p wpebackend-deb-root/usr/include
    mkdir -p wpebackend-deb-root/usr/lib/pkgconfig
    
    # Create control file
    cat <<EOF > wpebackend-deb-root/DEBIAN/control
Package: wpebackend-fdo
Version: 1.16.0
Section: libs
Priority: optional
Architecture: arm64
Maintainer: bhNibir <nibir@example.com>
Description: WPE Backend for FreeDesktop.org for Raspberry Pi 3B+
EOF
    
    # Copy files
    sudo cp -r /usr/lib/libWPEBackend* wpebackend-deb-root/usr/lib/aarch64-linux-gnu/
    sudo cp -r /usr/include/wpe-fdo-1.0 wpebackend-deb-root/usr/include/
    sudo cp -r /usr/lib/pkgconfig/wpebackend-fdo-1.0.pc wpebackend-deb-root/usr/lib/pkgconfig/
    
    # Fix permissions for dpkg-deb
    sudo chmod 755 wpebackend-deb-root/DEBIAN
    sudo chmod 644 wpebackend-deb-root/DEBIAN/control
    sudo chown -R root:root wpebackend-deb-root
    
    # Create .deb package
    fakeroot dpkg-deb --build wpebackend-deb-root wpebackend-fdo-aarch64-rpi3b-v1.16.0.deb
    
    # Clean up
    sudo rm -rf wpebackend-deb-root
    rm -rf wpebackend-fdo-1.16.0
    
    print_success "wpebackend-fdo built and packaged successfully"
}

# Function to build WPE WebKit
build_wpewebkit() {
    print_status "Building WPE WebKit..."
    
    # Clean up any existing wpewebkit directory
    if [ -d "wpewebkit" ]; then
        print_status "Cleaning up existing wpewebkit directory..."
        rm -rf wpewebkit
    fi
    
    # Download and extract WPE WebKit
    wget -q https://wpewebkit.org/releases/wpewebkit-2.48.4.tar.xz
    tar -xf wpewebkit-2.48.4.tar.xz
    mv wpewebkit-2.48.4 wpewebkit
    
    # Create build directory
    mkdir -p wpewebkit/build
    cd wpewebkit/build
    
    # Configure with CMake (optimized for memory usage)
    cmake .. \
        -DPORT=WPE \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
        -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ \
        -DCMAKE_PKG_CONFIG_EXECUTABLE=aarch64-linux-gnu-pkg-config \
        -DENABLE_DOCUMENTATION=OFF \
        -DENABLE_ENCRYPTED_MEDIA=ON \
        -DENABLE_WPE_PLATFORM=ON \
        -DENABLE_WPE_PLATFORM_DRM=ON \
        -DENABLE_WPE_PLATFORM_HEADLESS=ON \
        -DUSE_LIBBACKTRACE=OFF \
        -DCMAKE_CROSSCOMPILING=ON \
        -DCMAKE_SYSTEM_NAME=Linux \
        -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
        -DBWRAP_EXECUTABLE=/usr/bin/bwrap \
        -DDBUS_PROXY_EXECUTABLE=/usr/bin/xdg-dbus-proxy \
        -DCMAKE_CXX_FLAGS="-O2 -g -DNDEBUG -std=c++23 -fPIC -fvisibility=hidden -fvisibility-inlines-hidden -ffp-contract=off -pthread -fmax-errors=20" \
        -DCMAKE_C_FLAGS="-O2 -g -DNDEBUG -fPIC -fvisibility=hidden -fmax-errors=20" \
        -GNinja
    
    # Build with reduced parallelism to avoid memory issues
    # Use fewer parallel jobs and limit load average
    print_status "Building WPE WebKit (this may take a long time)..."
    
    # Calculate safe parallelism based on available memory
    AVAILABLE_MEMORY=$(free -m | awk 'NR==2{printf "%.0f", $7/1024}')
    if [ "$AVAILABLE_MEMORY" -gt 8 ]; then
        PARALLEL_JOBS=2
        LOAD_LIMIT=2
    else
        PARALLEL_JOBS=1
        LOAD_LIMIT=1
    fi
    
    print_status "Using $PARALLEL_JOBS parallel jobs with load limit $LOAD_LIMIT (available memory: ${AVAILABLE_MEMORY}GB)"
    
    # Build with memory-optimized settings
    ninja -j$PARALLEL_JOBS -l$LOAD_LIMIT
    
    # Install
    DESTDIR=$PWD/../deb-root ninja install
    
    # Create .deb package
    print_status "Creating WPE WebKit .deb package..."
    cd ../..
    
    # Create package structure
    mkdir -p deb-root/DEBIAN
    mkdir -p deb-root/usr/lib/aarch64-linux-gnu
    mkdir -p deb-root/usr/include
    mkdir -p deb-root/usr/bin
    mkdir -p deb-root/usr/share
    
    # Create control file
    cat <<EOF > deb-root/DEBIAN/control
Package: wpewebkit
Version: 2.48.4
Section: web
Priority: optional
Architecture: arm64
Maintainer: bhNibir <nibir@example.com>
Description: WPE WebKit 2.48.4 built for Raspberry Pi 3B+
EOF
    
    # Copy files from the install directory
    sudo cp -r wpewebkit/deb-root/usr/lib/* deb-root/usr/lib/
    sudo cp -r wpewebkit/deb-root/usr/include/* deb-root/usr/include/
    sudo cp -r wpewebkit/deb-root/usr/bin/* deb-root/usr/bin/ 2>/dev/null || true
    sudo cp -r wpewebkit/deb-root/usr/share/* deb-root/usr/share/ 2>/dev/null || true
    
    # Fix permissions for dpkg-deb
    sudo chmod 755 deb-root/DEBIAN
    sudo chmod 644 deb-root/DEBIAN/control
    sudo chown -R root:root deb-root
    
    # Create .deb package
    fakeroot dpkg-deb --build deb-root wpewebkit-aarch64-rpi3b-v2.48.4.deb
    
    # Clean up
    sudo rm -rf deb-root
    rm -rf wpewebkit
    
    print_success "WPE WebKit built and packaged successfully"
}

# Function to show build statistics
show_statistics() {
    print_status "Build Statistics:"
    echo "=================="
    
    # Show ccache statistics
    if command_exists ccache; then
        echo "ccache statistics:"
        ccache -s
        echo
    fi
    
    # Show disk usage
    echo "Disk usage:"
    df -h .
    echo
    
    # Show package sizes
    echo "Generated .deb packages:"
    ls -lh *.deb 2>/dev/null || echo "No .deb packages found"
    echo
    
    # Show total size
    if ls *.deb >/dev/null 2>&1; then
        total_size=$(du -ch *.deb | tail -1)
        echo "Total package size: $total_size"
    fi
}

# Function to show usage
show_usage() {
    echo "WPE WebKit Manual Build Script"
    echo "=============================="
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --deps-only      Build only dependencies (libwpe, wpebackend-fdo)"
    echo "  --webkit-only    Build only WPE WebKit (requires dependencies)"
    echo "  --test-deps      Test if dependencies are available"
    echo "  --clean          Clean all build artifacts and start fresh"
    echo "  --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Build everything"
    echo "  $0 --deps-only        # Build only dependencies"
    echo "  $0 --webkit-only      # Build only WebKit"
    echo "  $0 --test-deps        # Test dependency availability"
    echo "  $0 --clean            # Clean and build everything"
    echo ""
}

# Function to clean build artifacts
clean_build() {
    print_status "Cleaning build artifacts..."
    
    # Remove downloaded tarballs
    rm -f *.tar.xz
    
    # Remove build directories
    rm -rf libwpe-1.16.2
    rm -rf wpebackend-fdo-1.16.0
    rm -rf wpewebkit
    rm -rf deb-root
    rm -rf libwpe-deb-root
    rm -rf wpebackend-deb-root
    
    # Remove .deb packages
    rm -f *.deb
    
    # Clean ccache (optional)
    if [ -d ~/.cache/ccache ]; then
        print_warning "Cleaning ccache..."
        ccache -C
    fi
    
    print_success "Build artifacts cleaned"
}

# Function to test dependencies without installing
test_dependencies() {
    print_status "Testing dependency availability..."
    
    # Check if ARM64 architecture is added
    if dpkg --print-foreign-architectures | grep -q arm64; then
        print_success "ARM64 architecture is added"
    else
        print_warning "ARM64 architecture is not added"
    fi
    
    # Test ARM64 package availability
    print_status "Testing ARM64 package availability..."
    
    local packages=(
        "python3-gi:arm64"
        "libgirepository1.0-dev:arm64"
        "libglib2.0-dev:arm64"
        "libcairo2-dev:arm64"
        "gobject-introspection:arm64"
        "gobject-introspection-bin:arm64"
        "gobject-introspection-bin-linux:arm64"
    )
    
    for package in "${packages[@]}"; do
        if apt-cache policy "$package" | grep -q "Installed\|Candidate"; then
            print_success "$package is available"
        else
            print_warning "$package is not available"
        fi
    done
    
    # Test host packages
    print_status "Testing host package availability..."
    if command -v g-ir-scanner >/dev/null 2>&1; then
        print_success "g-ir-scanner is available"
    else
        print_warning "g-ir-scanner is not available"
    fi
    
    if [ -f "/usr/lib/x86_64-linux-gnu/libgirepository-1.0.so" ]; then
        print_success "Host GObject Introspection library exists"
    else
        print_warning "Host GObject Introspection library not found"
    fi
    
    # Check if ARM64 GObject Introspection is actually working
    print_status "Testing ARM64 GObject Introspection functionality..."
    if [ -f "/usr/lib/aarch64-linux-gnu/libgirepository-1.0.so" ]; then
        print_success "ARM64 GObject Introspection library exists"
    else
        print_warning "ARM64 GObject Introspection library not found"
    fi
    
    if [ -d "/usr/lib/aarch64-linux-gnu/python3/dist-packages" ]; then
        print_success "ARM64 Python packages directory exists"
    else
        print_warning "ARM64 Python packages directory not found"
    fi
    
    print_success "Dependency test completed"
}

# Function to check system resources
check_system_resources() {
    print_status "Checking system resources..."
    
    # Check available memory
    AVAILABLE_MEMORY=$(free -m | awk 'NR==2{printf "%.0f", $7/1024}')
    TOTAL_MEMORY=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
    
    print_status "Memory: ${AVAILABLE_MEMORY}GB available out of ${TOTAL_MEMORY}GB total"
    
    # Check available disk space
    AVAILABLE_DISK=$(df -BG . | awk 'NR==2{print $4}' | sed 's/G//')
    print_status "Disk space: ${AVAILABLE_DISK}GB available"
    
    # Check CPU cores
    CPU_CORES=$(nproc)
    print_status "CPU cores: $CPU_CORES"
    
    # Provide recommendations
    if [ "$AVAILABLE_MEMORY" -lt 4 ]; then
        print_warning "Low memory detected (${AVAILABLE_MEMORY}GB). WebKit build may fail."
        print_warning "Consider:"
        print_warning "  - Close other applications"
        print_warning "  - Use --webkit-only to skip dependency builds"
        print_warning "  - Build will use single-threaded compilation"
    elif [ "$AVAILABLE_MEMORY" -lt 8 ]; then
        print_warning "Moderate memory (${AVAILABLE_MEMORY}GB). Build will use limited parallelism."
    else
        print_success "Sufficient memory (${AVAILABLE_MEMORY}GB) for WebKit build"
    fi
    
    if [ "$AVAILABLE_DISK" -lt 10 ]; then
        print_warning "Low disk space (${AVAILABLE_DISK}GB). WebKit build may fail."
        print_warning "Consider cleaning up disk space before building."
    else
        print_success "Sufficient disk space (${AVAILABLE_DISK}GB) for WebKit build"
    fi
    
    echo ""
}

# Main function
main() {
    echo "=========================================="
    echo "WPE WebKit Manual Build Script"
    echo "=========================================="
    echo ""
    
    # Parse command line arguments
    DEPS_ONLY=false
    WEBKIT_ONLY=false
    TEST_DEPS=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --deps-only)
                DEPS_ONLY=true
                shift
                ;;
            --webkit-only)
                WEBKIT_ONLY=true
                shift
                ;;
            --test-deps)
                TEST_DEPS=true
                shift
                ;;
            --clean)
                clean_build
                exit 0
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Test dependencies if requested
    if [ "$TEST_DEPS" = true ]; then
        test_dependencies
        exit 0
    fi
    
    # Check system resources before building WebKit
    if [ "$WEBKIT_ONLY" = false ] && [ "$DEPS_ONLY" = false ]; then
        check_system_resources
    fi
    
    # Install dependencies (unless webkit-only mode)
    if [ "$WEBKIT_ONLY" = false ]; then
        check_repository_config
        install_dependencies
    fi
    
    # Exit if deps-only mode
    if [ "$DEPS_ONLY" = true ]; then
        print_success "Dependencies installation completed"
        exit 0
    fi
    
    # Set up build environment
    setup_build_environment
    
    # Build components
    if [ "$WEBKIT_ONLY" = false ]; then
        build_libwpe
        build_wpebackend_fdo
    fi
    
    build_wpewebkit
    
    # Show statistics
    show_statistics
    
    print_success "Build completed successfully!"
}

# Run main function
main "$@"