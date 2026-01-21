#!/bin/bash
# Docker 构建脚本 - 在容器中编译 scrcpy for Termux

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== scrcpy Termux Docker 构建脚本 ===${NC}"
echo ""

# 交互式选择架构
if [[ $# -eq 0 ]]; then
    echo -e "${BLUE}请选择要编译的架构:${NC}"
    echo ""
    echo "  1) arm64    - ARM64-v8a (最常见的 Android 设备)"
    echo "  2) arm      - ARMv7a (老的 32 位 ARM 设备)"
    echo "  3) x86_64   - 64 位 x86 设备"
    echo "  4) x86      - 32 位 x86 设备"
    echo "  5) all      - 编译所有架构"
    echo ""
    read -p "请输入选项 [1-5]: " choice

    case $choice in
        1) ARCH="arm64" ;;
        2) ARCH="arm" ;;
        3) ARCH="x86_64" ;;
        4) ARCH="x86" ;;
        5) ARCH="all" ;;
        *)
            echo -e "${RED}无效选项！${NC}"
            exit 1
            ;;
    esac
else
    ARCH="$1"
fi

echo ""
echo -e "${YELLOW}选择的架构: $ARCH${NC}"
echo ""

# 构建 Docker 镜像
echo -e "${GREEN}步骤 1/3: 构建 Docker 镜像...${NC}"
docker build -t scrcpy-termux-builder -f Dockerfile.termux . -q

# 清理旧的 dist 目录
echo -e "${GREEN}步骤 2/4: 清理旧的构建产物...${NC}"
rm -rf dist/
rm -rf release/output/
rm -rf release/work/

# 构建 scrcpy-server
echo -e "${GREEN}步骤 3/4: 构建 scrcpy-server...${NC}"
docker run --rm \
    -v "$(pwd):/workspace" \
    -w /workspace \
    -e GRADLE=gradle \
    scrcpy-termux-builder \
    bash -c "release/build_server.sh"

# 运行构建
echo -e "${GREEN}步骤 4/4: 在 Docker 容器中编译客户端...${NC}"
echo ""

if [[ "$ARCH" == "all" ]]; then
    # 编译所有架构
    for arch in arm64 arm x86_64 x86; do
        echo -e "${YELLOW}>>> 正在编译: termux-$arch${NC}"
        docker run --rm \
            -v "$(pwd):/workspace" \
            -w /workspace \
            scrcpy-termux-builder \
            bash -c "release/build_termux.sh $arch && release/package_client.sh termux-$arch tar.gz"
    done
else
    # 编译单个架构
    echo -e "${YELLOW}>>> 正在编译: termux-$ARCH${NC}"
    docker run --rm \
        -v "$(pwd):/workspace" \
        -w /workspace \
        scrcpy-termux-builder \
        bash -c "release/build_termux.sh $ARCH && release/package_client.sh termux-$ARCH tar.gz"
fi

# 移动产物到 dist 目录
echo ""
echo -e "${GREEN}整理构建产物...${NC}"
mkdir -p dist/
if [[ -d release/output ]]; then
    mv release/output/* dist/ 2>/dev/null || true
fi

# 清理中间文件
echo -e "${GREEN}清理中间文件...${NC}"
rm -rf release/work/

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     🎉 构建完成！                      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}构建产物位置: ${GREEN}./dist/${NC}"
echo ""

if [[ -d dist ]]; then
    ls -lh dist/
    echo ""
    echo -e "${YELLOW}文件说明:${NC}"
    echo "  scrcpy-termux-*.tar.gz - 完整的发布包"
    echo ""
    echo -e "${YELLOW}使用方法:${NC}"
    echo "  1. 将 .tar.gz 文件传输到 Termux"
    echo "  2. tar xzf scrcpy-termux-*.tar.gz"
    echo "  3. cd scrcpy-termux-*/"
    echo "  4. ./scrcpy"
fi

echo ""
echo -e "${GREEN}容器已自动删除 ✓${NC}"

