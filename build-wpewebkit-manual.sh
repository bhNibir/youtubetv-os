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
    
    # Install Python dependencies
    sudo apt-get install -y python3-setuptools python3-pip python3-gi python3-gi-cairo
    pip3 install --upgrade pip setuptools wheel pygobject
    
    # Install GObject Introspection
    sudo apt-get install -y gobject-introspection libgirepository1.0-dev
    
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
        libfontconfig1-dev:arm64
    
    print_success "Dependencies installed successfully"
}

# Function to setup build environment
setup_build_environment() {
    print_status "Setting up build environment..."
    
    # Set up ccache
    export CCACHE_DIR=~/.cache/ccache
    export CCACHE_MAXSIZE=10G
    export CCACHE_COMPRESS=1
    export CCACHE_COMPRESSLEVEL=6
    
    # Create ccache directory if it doesn't exist
    mkdir -p ~/.cache/ccache
    
    # Set up environment variables
    export PKG_CONFIG_PATH="/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/share/pkgconfig"
    export PKG_CONFIG_LIBDIR="/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/share/pkgconfig"
    export GI_SCANNER_DISABLE_CACHE=1
    export GI_CROSS_LAUNCHER=qemu-aarch64-static
    export GI_CROSS_COMPILER=aarch64-linux-gnu-gcc
    export GI_CROSS_PKG_CONFIG_PATH="/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/share/pkgconfig"
    export PYTHONPATH="/usr/lib/python3/dist-packages:$PYTHONPATH"
    export PYTHONUNBUFFERED=1
    export PYTHONDONTWRITEBYTECODE=1
    export GI_SCANNER_EXTRA_ARGS="--no-libtool"
    export GI_SCANNER_QUIET=1
    export GI_SCANNER_WARN_ALL=1
    export GI_SCANNER_WARN_ERROR=1
    
    print_success "Build environment configured"
}

# Function to build libwpe
build_libwpe() {
    print_status "Building libwpe..."
    
    if [ -f "libwpe-aarch64-rpi3b-v1.16.2.deb" ]; then
        print_warning "libwpe .deb already exists, skipping build..."
        return 0
    fi
    
    # Download and extract libwpe
    wget -q https://wpewebkit.org/releases/libwpe-1.16.2.tar.xz
    tar -xf libwpe-1.16.2.tar.xz
    cd libwpe-1.16.2
    
    # Configure and build
    mkdir build && cd build
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
        -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ \
        -DCMAKE_C_COMPILER_LAUNCHER=ccache \
        -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
        -GNinja
    
    ninja
    sudo ninja install
    cd ../..
    
    # Create .deb package
    mkdir -p libwpe-deb-root/DEBIAN
    mkdir -p libwpe-deb-root/usr/lib/aarch64-linux-gnu
    mkdir -p libwpe-deb-root/usr/include
    mkdir -p libwpe-deb-root/usr/lib/aarch64-linux-gnu/pkgconfig
    
    cat <<EOF > libwpe-deb-root/DEBIAN/control
Package: libwpe-1.0
Version: 1.16.2
Section: libs
Priority: optional
Architecture: arm64
Maintainer: bhNibir <nibir@example.com>
Description: WPE (WebKit Port for Embedded) library for Raspberry Pi 3B+
EOF
    
    sudo cp -r /usr/lib/aarch64-linux-gnu/libwpe* libwpe-deb-root/usr/lib/aarch64-linux-gnu/
    sudo cp -r /usr/include/wpe-1.0 libwpe-deb-root/usr/include/
    sudo cp -r /usr/lib/aarch64-linux-gnu/pkgconfig/wpe* libwpe-deb-root/usr/lib/aarch64-linux-gnu/pkgconfig/
    
    fakeroot dpkg-deb --build libwpe-deb-root libwpe-aarch64-rpi3b-v1.16.2.deb
    
    # Cleanup
    rm -rf libwpe-1.16.2
    rm -rf libwpe-deb-root
    
    print_success "libwpe built and packaged successfully"
}

# Function to build wpebackend-fdo
build_wpebackend_fdo() {
    print_status "Building wpebackend-fdo..."
    
    if [ -f "wpebackend-fdo-aarch64-rpi3b-v1.16.0.deb" ]; then
        print_warning "wpebackend-fdo .deb already exists, skipping build..."
        return 0
    fi
    
    # Download and extract wpebackend-fdo
    wget -q https://wpewebkit.org/releases/wpebackend-fdo-1.16.0.tar.xz
    tar -xf wpebackend-fdo-1.16.0.tar.xz
    cd wpebackend-fdo-1.16.0
    
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
    
    # Configure and build
    mkdir build && cd build
    meson setup .. \
        --buildtype=release \
        --prefix=/usr \
        --cross-file=../cross-file.txt
    
    ninja
    sudo ninja install
    cd ../..
    
    # Create .deb package
    mkdir -p wpebackend-deb-root/DEBIAN
    mkdir -p wpebackend-deb-root/usr/lib/aarch64-linux-gnu
    mkdir -p wpebackend-deb-root/usr/include
    mkdir -p wpebackend-deb-root/usr/lib/pkgconfig
    
    cat <<EOF > wpebackend-deb-root/DEBIAN/control
Package: wpebackend-fdo
Version: 1.16.0
Section: libs
Priority: optional
Architecture: arm64
Maintainer: bhNibir <nibir@example.com>
Description: WPE Backend for FreeDesktop.org for Raspberry Pi 3B+
EOF
    
    sudo cp -r /usr/lib/libWPEBackend* wpebackend-deb-root/usr/lib/aarch64-linux-gnu/
    sudo cp -r /usr/include/wpe-fdo-1.0 wpebackend-deb-root/usr/include/
    sudo cp -r /usr/lib/pkgconfig/wpebackend-fdo-1.0.pc wpebackend-deb-root/usr/lib/pkgconfig/
    
    fakeroot dpkg-deb --build wpebackend-deb-root wpebackend-fdo-aarch64-rpi3b-v1.16.0.deb
    
    # Cleanup
    rm -rf wpebackend-fdo-1.16.0
    rm -rf wpebackend-deb-root
    
    print_success "wpebackend-fdo built and packaged successfully"
}

# Function to build WPE WebKit
build_wpewebkit() {
    print_status "Building WPE WebKit..."
    
    if [ -f "wpewebkit-aarch64-rpi3b-v2.48.4.deb" ]; then
        print_warning "WPE WebKit .deb already exists, skipping build..."
        return 0
    fi
    
    # Download and extract WPE WebKit
    wget -q https://wpewebkit.org/releases/wpewebkit-2.48.4.tar.xz
    tar -xf wpewebkit-2.48.4.tar.xz
    mv wpewebkit-2.48.4 wpewebkit
    
    # Configure and build
    mkdir -p wpewebkit/build
    cd wpewebkit/build
    
    # Set up environment variables
    export CC=ccache
    export CXX=ccache
    export AR=aarch64-linux-gnu-ar
    export STRIP=aarch64-linux-gnu-strip
    export RANLIB=aarch64-linux-gnu-ranlib
    export LD=aarch64-linux-gnu-ld
    export PKG_CONFIG=aarch64-linux-gnu-pkg-config
    
    # Configure with CMake
    cmake .. \
        -DPORT=WPE \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
        -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ \
        -DCMAKE_C_COMPILER_LAUNCHER=ccache \
        -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
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
        -GNinja
    
    # Build
    ninja -j$(nproc) -l$(nproc)
    DESTDIR=../../deb-root ninja install
    cd ../..
    
    # Create .deb package
    mkdir -p deb-root/DEBIAN
    mkdir -p deb-root/usr/lib/aarch64-linux-gnu
    mkdir -p deb-root/usr/include
    mkdir -p deb-root/usr/bin
    mkdir -p deb-root/usr/share
    
    cat <<EOF > deb-root/DEBIAN/control
Package: wpewebkit
Version: 2.48.4
Section: web
Priority: optional
Architecture: arm64
Maintainer: bhNibir <nibir@example.com>
Description: WPE WebKit 2.48.4 built for Raspberry Pi 3B+
EOF
    
    # Copy files
    sudo cp -r deb-root/usr/lib/* deb-root/usr/lib/
    sudo cp -r deb-root/usr/include/* deb-root/usr/include/
    sudo cp -r deb-root/usr/bin/* deb-root/usr/bin/
    sudo cp -r deb-root/usr/share/* deb-root/usr/share/
    
    fakeroot dpkg-deb --build deb-root wpewebkit-aarch64-rpi3b-v2.48.4.deb
    
    # Cleanup
    rm -rf wpewebkit
    rm -rf deb-root
    
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
    echo "  --clean          Clean all build artifacts and start fresh"
    echo "  --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Build everything"
    echo "  $0 --deps-only        # Build only dependencies"
    echo "  $0 --webkit-only      # Build only WebKit"
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

# Main function
main() {
    echo "=========================================="
    echo "WPE WebKit Manual Build Script"
    echo "=========================================="
    echo ""
    
    # Parse command line arguments
    DEPS_ONLY=false
    WEBKIT_ONLY=false
    CLEAN_BUILD=false
    
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
            --clean)
                CLEAN_BUILD=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        print_error "Please do not run this script as root"
        exit 1
    fi
    
    # Check disk space
    check_disk_space
    
    # Clean if requested
    if [ "$CLEAN_BUILD" = true ]; then
        clean_build
    fi
    
    # Check and fix repository configuration
    check_repository_config
    
    # Install dependencies if not building WebKit only
    if [ "$WEBKIT_ONLY" = false ]; then
        install_dependencies
        setup_build_environment
    fi
    
    # Build dependencies
    if [ "$WEBKIT_ONLY" = false ]; then
        build_libwpe
        build_wpebackend_fdo
    fi
    
    # Build WebKit
    if [ "$DEPS_ONLY" = false ]; then
        build_wpewebkit
    fi
    
    # Show statistics
    show_statistics
    
    print_success "Build completed successfully!"
    echo ""
    echo "Generated packages:"
    ls -la *.deb 2>/dev/null || echo "No packages generated"
    echo ""
    echo "You can now install these packages on your Raspberry Pi:"
    echo "  sudo dpkg -i *.deb"
}

# Run main function
main "$@"