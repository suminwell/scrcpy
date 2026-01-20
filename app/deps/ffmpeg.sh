#!/usr/bin/env bash
set -ex
. $(dirname ${BASH_SOURCE[0]})/_init
process_args "$@"

VERSION=7.1.1
URL="https://ffmpeg.org/releases/ffmpeg-$VERSION.tar.xz"
SHA256SUM=733984395e0dbbe5c046abda2dc49a5544e7e0e1e2366bba849222ae9e3a03b1

PROJECT_DIR="ffmpeg-$VERSION"
FILENAME="$PROJECT_DIR.tar.xz"

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

if [[ -d "$DIRNAME" ]]
then
    echo "'$PWD/$DIRNAME' already exists, not reconfigured"
    cd "$DIRNAME"
else
    mkdir "$DIRNAME"
    cd "$DIRNAME"

    if [[ "$HOST" == win* ]]
    then
        # -static-libgcc to avoid missing libgcc_s_dw2-1.dll
        # -static to avoid dynamic dependency to zlib
        export CFLAGS='-static-libgcc -static'
        export CXXFLAGS="$CFLAGS"
        export LDFLAGS='-static-libgcc -static'
    elif [[ "$HOST" == "macos" ]]
    then
        export PKG_CONFIG_PATH="/opt/homebrew/opt/zlib/lib/pkgconfig"
    fi

    # For non-ARM64 Linux builds, set PKG_CONFIG_PATH
    # For ARM64 Linux, we'll use PKG_CONFIG_LIBDIR instead (see below)
    if [[ "$HOST" != "linux-arm64" ]]
    then
        export PKG_CONFIG_PATH="$INSTALL_DIR/$DIRNAME/lib/pkgconfig:$PKG_CONFIG_PATH"
    fi

    conf=(
        --prefix="$INSTALL_DIR/$DIRNAME"
        --pkg-config-flags="--static"
        --extra-cflags="-O2 -fPIC"
        --disable-programs
        --disable-doc
        --disable-swscale
        --disable-postproc
        --disable-avfilter
        --disable-network
        --disable-everything
        --disable-vulkan
        --disable-vaapi
        --disable-vdpau
        --enable-swresample
        --enable-libdav1d
        --enable-decoder=h264
        --enable-decoder=hevc
        --enable-decoder=av1
        --enable-decoder=libdav1d
        --enable-decoder=pcm_s16le
        --enable-decoder=opus
        --enable-decoder=aac
        --enable-decoder=flac
        --enable-decoder=png
        --enable-protocol=file
        --enable-demuxer=image2
        --enable-parser=png
        --enable-zlib
        --enable-muxer=matroska
        --enable-muxer=mp4
        --enable-muxer=opus
        --enable-muxer=flac
        --enable-muxer=wav
    )

    if [[ "$HOST" == linux || "$HOST" == linux-arm64 ]]
    then
        conf+=(
            --enable-libv4l2
            --enable-outdev=v4l2
            --enable-encoder=rawvideo
        )
    else
        # libavdevice is only used for V4L2 on Linux
        conf+=(
            --disable-avdevice
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
            --enable-cross-compile
            --cross-prefix="${HOST_TRIPLET}-"
            --cc="${HOST_TRIPLET}-gcc"
        )

        case "$HOST" in
            win32)
                conf+=(
                    --target-os=mingw32
                    --arch=x86
                )
                ;;

            win64)
                conf+=(
                    --target-os=mingw32
                    --arch=x86_64
                )
                ;;

            linux-arm64)
                conf+=(
                    --target-os=linux
                    --arch=aarch64
                )
                # For ARM64 cross-compilation, use PKG_CONFIG_LIBDIR to specify all search paths
                # This includes both our compiled dependencies (dav1d) and system ARM64 libraries (libv4l2)
                # Note: When PKG_CONFIG_LIBDIR is set, PKG_CONFIG_PATH is ignored, so we must include
                # all paths in PKG_CONFIG_LIBDIR
                export PKG_CONFIG_LIBDIR="$INSTALL_DIR/$DIRNAME/lib/pkgconfig:/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/share/pkgconfig"
                ;;

            *)
                echo "Unsupported host: $HOST" >&2
                exit 1
        esac
    fi

    "$SOURCES_DIR/$PROJECT_DIR"/configure "${conf[@]}"
fi

make -j
make install
