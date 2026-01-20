#!/usr/bin/env bash
set -ex
. $(dirname ${BASH_SOURCE[0]})/_init
process_args "$@"

VERSION=2.32.8
URL="https://github.com/libsdl-org/SDL/archive/refs/tags/release-$VERSION.tar.gz"
SHA256SUM=dd35e05644ae527848d02433bec24dd0ea65db59faecf1a0e5d1880c533dac2c

PROJECT_DIR="sdl-$VERSION"
FILENAME="$PROJECT_DIR.tar.gz"

cd "$SOURCES_DIR"

if [[ -d "$PROJECT_DIR" ]]
then
    echo "$PWD/$PROJECT_DIR" found
else
    get_file "$URL" "$FILENAME" "$SHA256SUM"
    tar xf "$FILENAME"  # First level directory is "SDL-release-$VERSION"
    mv "SDL-release-$VERSION" "$PROJECT_DIR"
fi

mkdir -p "$BUILD_DIR/$PROJECT_DIR"
cd "$BUILD_DIR/$PROJECT_DIR"

export CFLAGS='-O2'
export CXXFLAGS="$CFLAGS"

# For Termux (Android), use NDK compilers
if [[ "$HOST" == termux-arm64 ]]
then
    export CC=aarch64-linux-android21-clang
    export CXX=aarch64-linux-android21-clang++
    export AR=llvm-ar
    export RANLIB=llvm-ranlib
    export STRIP=llvm-strip
elif [[ "$HOST" == termux-arm ]]
then
    export CC=armv7a-linux-androideabi21-clang
    export CXX=armv7a-linux-androideabi21-clang++
    export AR=llvm-ar
    export RANLIB=llvm-ranlib
    export STRIP=llvm-strip
elif [[ "$HOST" == termux-x86_64 ]]
then
    export CC=x86_64-linux-android21-clang
    export CXX=x86_64-linux-android21-clang++
    export AR=llvm-ar
    export RANLIB=llvm-ranlib
    export STRIP=llvm-strip
elif [[ "$HOST" == termux-x86 ]]
then
    export CC=i686-linux-android21-clang
    export CXX=i686-linux-android21-clang++
    export AR=llvm-ar
    export RANLIB=llvm-ranlib
    export STRIP=llvm-strip
fi

if [[ -d "$DIRNAME" ]]
then
    echo "'$PWD/$DIRNAME' already exists, not reconfigured"
    cd "$DIRNAME"
else
    mkdir "$DIRNAME"
    cd "$DIRNAME"

    conf=(
        --prefix="$INSTALL_DIR/$DIRNAME"
    )

    if [[ "$HOST" == linux ]]
    then
        conf+=(
            --enable-video-wayland
            --enable-video-x11
        )
    elif [[ "$HOST" == termux-* ]]
    then
        # For headless mode (--no-playback, --v4l2-sink), X11 is not needed
        # If you need X11 display in Termux, change --disable-video-x11 to --enable-video-x11
        conf+=(
            --disable-video-wayland
            --disable-video-x11
        )
    fi

    if [[ "$LINK_TYPE" == static ]]
    then
        conf+=(
            --enable-static
            --disable-shared
        )
    else
        conf+=(
            --disable-static
            --enable-shared
        )
    fi

    if [[ "$BUILD_TYPE" == cross ]]
    then
        conf+=(
            --host="$HOST_TRIPLET"
        )
    fi

    "$SOURCES_DIR/$PROJECT_DIR"/configure "${conf[@]}"
fi

make -j
# There is no "make install-strip"
make install
# Strip manually
if [[ "$LINK_TYPE" == shared && "$HOST" == win* ]]
then
    ${HOST_TRIPLET}-strip "$INSTALL_DIR/$DIRNAME/bin/SDL2.dll"
fi
