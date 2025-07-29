ARG WEBKIT_BRANCH
FROM mcr.microsoft.com/vscode/devcontainers/base:debian

RUN apt-get update && apt-get install -y \
    build-essential ninja-build cmake pkg-config git python3 python3-distro python3-venv \
    ruby unifdef g++-aarch64-linux-gnu gcc-aarch64-linux-gnu qemu-user-static \
    libglib2.0-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    libharfbuzz-dev libjpeg-dev libpng-dev libwebp-dev wget ca-certificates \
    readline-devel libsqlite3-dev libwoff2-1 \
    && apt-get clean

ENV CC=aarch64-linux-gnu-gcc
ENV CXX=aarch64-linux-gnu-g++
ENV AR=aarch64-linux-gnu-ar
ENV STRIP=aarch64-linux-gnu-strip
ENV HOST=aarch64-linux-gnu

WORKDIR /workspace
