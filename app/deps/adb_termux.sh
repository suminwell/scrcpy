#!/usr/bin/env bash
set -ex
. "$(dirname "$0")"/_init

# Download and build adb from nmeum/android-tools for Termux
# This compiles adb from AOSP source using Android NDK

ANDROID_TOOLS_VERSION=35.0.2
ANDROID_TOOLS_SHA256=d2c3222280315f36d8bfa5c02d7632b47e365bfe2e77e99a3564fb6576f04097

# Get architecture parameter
ARCH="$1"
if [[ -z "$ARCH" ]]; then
    echo "Usage: $0 <arch>"
    echo "  arch: arm64, arm, x86_64, x86"
    exit 1
fi

# Map Termux architecture names to Android NDK architecture names
case "$ARCH" in
    arm64)
        NDK_ARCH=aarch64
        NDK_ABI=arm64-v8a
        ;;
    arm)
        NDK_ARCH=armv7a
        NDK_ABI=armeabi-v7a
        ;;
    x86_64)
        NDK_ARCH=x86_64
        NDK_ABI=x86_64
        ;;
    x86)
        NDK_ARCH=i686
        NDK_ABI=x86
        ;;
    *)
        echo "Unknown architecture: $ARCH"
        exit 1
        ;;
esac

ANDROID_TOOLS_TARBALL="android-tools-${ANDROID_TOOLS_VERSION}.tar.xz"
ANDROID_TOOLS_URL="https://github.com/nmeum/android-tools/releases/download/${ANDROID_TOOLS_VERSION}/${ANDROID_TOOLS_TARBALL}"

cd "$WORK_DIR"

# Download tarball if not already downloaded
if [[ ! -f "$ANDROID_TOOLS_TARBALL" ]]; then
    wget "$ANDROID_TOOLS_URL"
    echo "$ANDROID_TOOLS_SHA256  $ANDROID_TOOLS_TARBALL" | sha256sum -c
fi

# Extract
ANDROID_TOOLS_DIR="android-tools-${ANDROID_TOOLS_VERSION}-${ARCH}"
rm -rf "$ANDROID_TOOLS_DIR"
mkdir -p "$ANDROID_TOOLS_DIR"
tar -xf "$ANDROID_TOOLS_TARBALL" -C "$ANDROID_TOOLS_DIR" --strip-components=1

cd "$ANDROID_TOOLS_DIR"

# Setup Android NDK
NDK_VERSION=r27d
NDK_DIR="$WORK_DIR/android-ndk-$NDK_VERSION"

if [[ ! -d "$NDK_DIR" ]]; then
    echo "Error: Android NDK not found at $NDK_DIR"
    echo "Please run release/setup_android_ndk.sh first"
    exit 1
fi

# Setup build directory
BUILD_DIR="build-${ARCH}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure CMake for cross-compilation to Android
cmake .. \
    -DCMAKE_SYSTEM_NAME=Android \
    -DCMAKE_SYSTEM_VERSION=21 \
    -DCMAKE_ANDROID_ARCH_ABI="$NDK_ABI" \
    -DCMAKE_ANDROID_NDK="$NDK_DIR" \
    -DCMAKE_ANDROID_STL_TYPE=c++_shared \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$WORK_DIR/install/adb-termux-${ARCH}"

# Build only adb (not fastboot or other tools)
make -j"$(nproc)" adb

# Install
make install

echo "adb for Termux $ARCH built successfully at $WORK_DIR/install/adb-termux-${ARCH}"

