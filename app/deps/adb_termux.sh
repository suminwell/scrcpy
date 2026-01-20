#!/usr/bin/env bash
set -ex
. "$(dirname "$0")"/_init

# Download precompiled adb from Termux official repository
# This is much simpler than compiling from source!

ANDROID_TOOLS_VERSION=35.0.2
ANDROID_TOOLS_REVISION=7

# Get architecture parameter
ARCH="$1"
if [[ -z "$ARCH" ]]; then
    echo "Usage: $0 <arch>"
    echo "  arch: arm64, arm, x86_64, x86"
    exit 1
fi

# Map architecture names to Termux package architecture names
case "$ARCH" in
    arm64)
        TERMUX_ARCH=aarch64
        ;;
    arm)
        TERMUX_ARCH=arm
        ;;
    x86_64)
        TERMUX_ARCH=x86_64
        ;;
    x86)
        TERMUX_ARCH=i686
        ;;
    *)
        echo "Unknown architecture: $ARCH"
        exit 1
        ;;
esac

DEB_FILE="android-tools_${ANDROID_TOOLS_VERSION}-${ANDROID_TOOLS_REVISION}_${TERMUX_ARCH}.deb"
DEB_URL="https://packages.termux.dev/apt/termux-main/pool/main/a/android-tools/${DEB_FILE}"

cd "$WORK_DIR"

# Download .deb file
if [[ ! -f "$DEB_FILE" ]]; then
    wget "$DEB_URL"
fi

# Extract .deb file
EXTRACT_DIR="adb-termux-${ARCH}-extract"
rm -rf "$EXTRACT_DIR"
mkdir -p "$EXTRACT_DIR"

# .deb files are ar archives containing data.tar.xz
ar x "$DEB_FILE" --output="$EXTRACT_DIR"
cd "$EXTRACT_DIR"

# Extract data.tar.xz which contains the actual files
tar -xf data.tar.xz

# Install to standard location
INSTALL_DIR="$WORK_DIR/install/adb-termux-${ARCH}"
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/bin"

# Copy adb binary (it's in data/data/com.termux/files/usr/bin/adb)
cp data/data/com.termux/files/usr/bin/adb "$INSTALL_DIR/bin/"

echo "adb for Termux $ARCH extracted successfully to $INSTALL_DIR"

