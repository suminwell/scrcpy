#!/bin/bash
# 进入 Docker 容器的交互式 shell

set -e

echo "=== 启动 scrcpy Termux 构建容器 ==="
echo ""

# 构建镜像（如果不存在）
if ! docker images | grep -q scrcpy-termux-builder; then
    echo "Docker 镜像不存在，正在构建..."
    docker build -t scrcpy-termux-builder -f Dockerfile.termux .
fi

echo "启动容器..."
echo ""
echo "在容器中，你可以运行:"
echo "  release/build_termux.sh arm64    # 编译 ARM64"
echo "  release/build_termux.sh arm      # 编译 ARM"
echo "  release/build_termux.sh x86_64   # 编译 x86_64"
echo "  release/build_termux.sh x86      # 编译 x86"
echo ""

docker run --rm -it \
    -v "$(pwd):/workspace" \
    -w /workspace \
    scrcpy-termux-builder \
    /bin/bash

