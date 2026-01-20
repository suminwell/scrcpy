#!/bin/bash
# Setup Android NDK for cross-compilation to Android ARM64 (Termux)
set -ex

NDK_VERSION="r27d"
NDK_DIR="$HOME/android-ndk-${NDK_VERSION}"

if [[ -d "$NDK_DIR" ]]; then
    echo "Android NDK already installed at $NDK_DIR"
else
    echo "Downloading Android NDK ${NDK_VERSION}..."
    cd "$HOME"
    wget "https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-linux.zip"
    unzip -q "android-ndk-${NDK_VERSION}-linux.zip"
    rm "android-ndk-${NDK_VERSION}-linux.zip"
fi

# Export NDK environment variables
export ANDROID_NDK_HOME="$NDK_DIR"
export NDK_TOOLCHAIN="$NDK_DIR/toolchains/llvm/prebuilt/linux-x86_64"
export PATH="$NDK_TOOLCHAIN/bin:$PATH"

# Export to GitHub Actions environment if running in CI
if [[ -n "$GITHUB_ENV" ]]; then
    echo "ANDROID_NDK_HOME=$ANDROID_NDK_HOME" >> "$GITHUB_ENV"
    echo "NDK_TOOLCHAIN=$NDK_TOOLCHAIN" >> "$GITHUB_ENV"
    echo "$NDK_TOOLCHAIN/bin" >> "$GITHUB_PATH"
fi

echo "Android NDK setup complete"
echo "ANDROID_NDK_HOME=$ANDROID_NDK_HOME"
echo "NDK_TOOLCHAIN=$NDK_TOOLCHAIN"

