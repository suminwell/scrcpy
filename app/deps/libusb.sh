#!/usr/bin/env bash
set -ex
. $(dirname ${BASH_SOURCE[0]})/_init
process_args "$@"

VERSION=1.0.29
URL="https://github.com/libusb/libusb/archive/refs/tags/v$VERSION.tar.gz"
SHA256SUM=7c2dd39c0b2589236e48c93247c986ae272e27570942b4163cb00a060fcf1b74

PROJECT_DIR="libusb-$VERSION"
FILENAME="$PROJECT_DIR.tar.gz"

cd "$SOURCES_DIR"

if [[ -d "$PROJECT_DIR" ]]
then
    echo "$PWD/$PROJECT_DIR" found
else
    get_file "$URL" "$FILENAME" "$SHA256SUM"
    tar xf "$FILENAME"  # First level directory is "$PROJECT_DIR"
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

    # Disable udev for Termux (Android doesn't have udev)
    if [[ "$HOST" == termux-* ]]
    then
        conf+=(
            --disable-udev
        )
    fi

    "$SOURCES_DIR/$PROJECT_DIR"/bootstrap.sh
    "$SOURCES_DIR/$PROJECT_DIR"/configure "${conf[@]}"
fi

make -j
make install-strip
