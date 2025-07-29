#!/bin/bash
set -e
echo ">>> Cloning WebKit @ branch ${WEBKIT_BRANCH}"
git clone --branch "${WEBKIT_BRANCH}" https://github.com/WebKit/WebKit.git

cd WebKit
echo ">>> Installing dependencies for WPE"
Tools/wpe/install-dependencies

echo ">>> Bootstrapping the build system"
YES | Tools/Scripts/update-webkitwpe-libs

echo ">>> Invoking build-webkit for WPE"
Tools/Scripts/build-webkit --wpe --release
