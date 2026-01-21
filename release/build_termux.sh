#!/bin/bash
# Build scrcpy for Termux (Android)
# This uses Android NDK instead of standard Linux cross-compiler
set -ex
cd "$(dirname ${BASH_SOURCE[0]})"
. build_common
cd .. # root project dir

if [[ $# != 1 ]]
then
    echo "Syntax: $0 <arch>" >&2
    echo "  arch: arm64, arm, x86_64, x86" >&2
    exit 1
fi

ARCH="$1"
TERMUX_BUILD_DIR="$WORK_DIR/build-termux-$ARCH"

# Build dependencies using Android NDK
app/deps/adb_termux.sh $ARCH
app/deps/sdl.sh termux-$ARCH cross static
app/deps/dav1d.sh termux-$ARCH cross static
app/deps/ffmpeg.sh termux-$ARCH cross static
app/deps/libusb.sh termux-$ARCH cross static

DEPS_INSTALL_DIR="$PWD/app/deps/work/install/termux-$ARCH-cross-static"
ADB_INSTALL_DIR="$PWD/app/deps/work/install/adb-termux-$ARCH"

rm -rf "$TERMUX_BUILD_DIR"
meson setup "$TERMUX_BUILD_DIR" \
    --cross-file=cross_termux_$ARCH.txt \
    --pkg-config-path="$DEPS_INSTALL_DIR/lib/pkgconfig" \
    -Dc_args="-I$DEPS_INSTALL_DIR/include" \
    -Dc_link_args="-L$DEPS_INSTALL_DIR/lib -lOpenSLES -llog -landroid" \
    --buildtype=release \
    --strip \
    -Db_lto=true \
    -Dcompile_server=false \
    -Dportable=true \
    -Dstatic=true \
    -Dv4l2=false
ninja -C "$TERMUX_BUILD_DIR"

# Group intermediate outputs into a 'dist' directory
mkdir -p "$TERMUX_BUILD_DIR/dist"
cp "$TERMUX_BUILD_DIR"/app/scrcpy "$TERMUX_BUILD_DIR/dist/"
cp app/data/icon.png "$TERMUX_BUILD_DIR/dist/"
cp app/scrcpy.1 "$TERMUX_BUILD_DIR/dist/"
cp -r "$ADB_INSTALL_DIR"/. "$TERMUX_BUILD_DIR/dist/"

