# 使用 Docker 编译 scrcpy for Termux

## 前提条件

- 安装 Docker Desktop (macOS/Windows) 或 Docker Engine (Linux)
- 至少 10GB 可用磁盘空间（用于 Docker 镜像和构建缓存）

## 快速开始

### 交互式编译（推荐）

```bash
# 运行脚本
./docker-build.sh

# 根据提示选择架构
请选择要编译的架构:

  1) arm64    - ARM64-v8a (最常见的 Android 设备)
  2) arm      - ARMv7a (老的 32 位 ARM 设备)
  3) x86_64   - 64 位 x86 设备
  4) x86      - 32 位 x86 设备
  5) all      - 编译所有架构

请输入选项 [1-5]: 1
```

### 命令行编译

```bash
# 编译单个架构
./docker-build.sh arm64

# 编译所有架构
./docker-build.sh all
```

## 详细说明

### 支持的架构

- `arm64` - ARM64-v8a (最常见，推荐)
- `arm` - ARMv7a (老设备)
- `x86_64` - 64位 x86
- `x86` - 32位 x86

### 构建产物位置

编译完成后，产物在项目根目录的 `dist/` 文件夹：

```
./dist/
└── scrcpy-termux-arm64-v3.3.4.tar.gz  # 完整的发布包
```

解压后的内容：
```
scrcpy-termux-arm64-v3.3.4/
├── scrcpy              # scrcpy 二进制文件
├── adb                 # adb 二进制文件
├── scrcpy-server       # scrcpy 服务端
├── icon.png            # 图标
└── scrcpy.1            # man page
```

### 完整示例

```bash
# 1. 运行构建脚本
./docker-build.sh

# 2. 选择架构（例如选择 1 - arm64）
请输入选项 [1-5]: 1

# 3. 等待构建完成（约 10-30 分钟）
# 构建过程：
#   - 构建 Docker 镜像
#   - 编译 scrcpy-server
#   - 编译 scrcpy 客户端
#   - 打包成 tar.gz

# 4. 查看产物
ls -lh dist/
# 输出: scrcpy-termux-arm64-v3.3.4.tar.gz

# 5. 传输到 Termux 并使用
# 在 Termux 中：
tar xzf scrcpy-termux-arm64-v3.3.4.tar.gz
cd scrcpy-termux-arm64-v3.3.4/
./scrcpy
```

## 清理

```bash
# 删除构建产物
rm -rf dist/

# 删除 Docker 镜像
docker rmi scrcpy-termux-builder

# 清理所有 Docker 缓存
docker system prune -a
```

**注意：** 构建过程会自动清理中间文件，容器也会自动删除。

## 故障排除

### Docker 镜像构建失败

```bash
# 清理并重新构建
docker rmi scrcpy-termux-builder
docker build -t scrcpy-termux-builder -f Dockerfile.termux .
```

### 编译失败

```bash
# 进入容器调试
./docker-shell.sh

# 在容器中手动运行构建步骤
release/setup_android_ndk.sh  # 已在 Dockerfile 中完成
release/build_termux.sh arm64
```

### 磁盘空间不足

Docker 镜像约 2GB，构建过程需要额外 5-8GB 空间。

```bash
# 清理 Docker 缓存
docker system prune -a
```

## 优势

✅ **环境隔离** - 不污染本机环境  
✅ **可重复构建** - 每次构建环境一致  
✅ **跨平台** - macOS/Windows/Linux 都可以用  
✅ **易于调试** - 可以进入容器手动调试  

## 与 GitHub Actions 的区别

| 特性 | Docker 本地构建 | GitHub Actions |
|------|----------------|----------------|
| 速度 | 快（本地网络） | 慢（下载 NDK） |
| 调试 | 容易（可交互） | 困难（只能看日志） |
| 成本 | 免费 | 免费（有限额） |
| 适用场景 | 开发调试 | 正式发布 |

