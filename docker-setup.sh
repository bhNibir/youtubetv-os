 apt install -y build-essential wget ninja-build cmake pkg-config libegl1-mesa-dev libxkbcommon-dev meson checkinstall


    wget -q https://wpewebkit.org/releases/libwpe-1.16.2.tar.xz
    tar -xf libwpe-1.16.2.tar.xz
    cd libwpe-1.16.2


    rm -rf build pkgroot
    meson setup build
    ninja -C build
    mkdir -p pkgroot
    
    DESTDIR=$PWD/pkgroot ninja -C build install

    cd pkgroot
    checkinstall --pkgname=libwpe \
    --pkgversion=1.16.2 \
    --pkgrelease=1 \
    --arch=arm64 \
    --maintainer="biplob.asanibir@gmail.com" \
    --pkglicense=MIT \
    --pakdir=/attcth \
    --nodoc \
    --install=no bash -c "true"

    #instll for system:

    ninja -C build install

# for install
# if use apt
#use for avoid error
# chmod 644 /home/nibir/libwpe_1.16.2-1_arm64.deb
# or use 
# sudo dpkg -i libwpe_1.16.2-1_arm64.deb
# docker copy cmd
# docker cp 8d65bb22f158:/attcth/libwpebackend-fdo_1.16.0-1_arm64.deb ./libwpebackend-fdo_1.16.0-1_arm64.deb
#  scp .\libwpebackend-fdo_1.16.0-1_arm64.deb nibir@raspberrypi.local:/home/nibir/



#for fdo

 apt update -y && apt install -y libwayland-dev libepoxy-dev g++ libglib2.0-dev

 wget -q https://wpewebkit.org/releases/wpebackend-fdo-1.16.0.tar.xz
    tar -xf wpebackend-fdo-1.16.0.tar.xz
    cd wpebackend-fdo-1.16.0

 rm -rf build pkgroot
    meson setup build
    ninja -C build install


    
 checkinstall --pkgname=libWPEBackend-fdo \
    --pkgversion=1.16.0 \
    --pkgrelease=1 \
    --arch=arm64 \
    --maintainer="biplob.asanibir@gmail.com" \
    --pkglicense=MIT \
    --pakdir=/attcth \
    --nodoc \
    --install=no bash -c "true"\
    --description="libWPEBackend-fdo"





#wpe webkit
 
    apt update -y &&  apt install -y ruby libglib2.0-dev libharfbuzz-dev
    wget -q https://wpewebkit.org/releases/wpewebkit-2.48.4.tar.xz
    tar -xf wpewebkit-2.48.4.tar.xz
    cd wpewebkit-2.48.4

    rm -rf build pkgroot
    mkdir build && cd build

    cmake -DPORT=WPE -DCMAKE_BUILD_TYPE=RelWithDebInfo -GNinja ..
    ninja
    ninja install









#cog


    wget -q https://wpewebkit.org/releases/cog-0.18.5.tar.xz
    tar -xf cog-0.18.5.tar.xz
    cd cog-0.18.5

    rm -rf build pkgroot
    meson setup build
    ninja -C build install

    checkinstall --pkgname=cog \
    --pkgversion=0.18.5 \
    --pkgrelease=1 \
    --arch=arm64 \
    --maintainer="biplob.asanibir@gmail.com" \
    --pkglicense=MIT \
    --pakdir=/attcth \
    --nodoc \
    --install=no bash -c "true"