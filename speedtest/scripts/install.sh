#!/bin/bash
# mmwx-speedtester 一键安装并运行脚本
# 用法: curl -fsSL <url>/install.sh | bash -s -- -master https://主控地址 -token <令牌> -name <名称>
# 或下载后: bash install.sh -master https://主控地址 -token <令牌> -name <名称>
set -e

REPO="MMWOrg/mmwX-plugins"
BINARY_NAME="mmwx-speedtester"
INSTALL_DIR="."

# 解析参数
MASTER=""
TOKEN=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -master) MASTER="$2"; shift 2 ;;
    -token) TOKEN="$2"; shift 2 ;;
    *) echo "未知参数: $1"; exit 1 ;;
  esac
done

if [ -z "$MASTER" ] || [ -z "$TOKEN" ]; then
  echo "用法: bash install.sh -master <主控地址> -token <令牌>"
  exit 1
fi

# 检测操作系统和架构
detect_platform() {
  OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
  ARCH="$(uname -m)"

  case "$OS" in
    linux) OS="linux" ;;
    darwin) OS="darwin" ;;
    mingw*|msys*|cygwin*) OS="windows" ;;
    *) echo "不支持的操作系统: $OS"; exit 1 ;;
  esac

  case "$ARCH" in
    x86_64|amd64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) echo "不支持的架构: $ARCH"; exit 1 ;;
  esac
}

# 获取最新 release 中匹配的下载 URL
get_download_url() {
  local asset_name="${BINARY_NAME}-${OS}-${ARCH}"
  if [ "$OS" = "windows" ]; then
    asset_name="${asset_name}.exe"
  fi

  echo "正在查询最新版本..."
  local release_url="https://api.github.com/repos/${REPO}/releases/latest"
  local release_json
  release_json=$(curl -fsSL "$release_url") || {
    echo "获取 release 信息失败"; exit 1
  }

  DOWNLOAD_URL=$(echo "$release_json" | grep -o "\"browser_download_url\": *\"[^\"]*${asset_name}\"" | head -1 | cut -d'"' -f4)
  if [ -z "$DOWNLOAD_URL" ]; then
    echo "未找到匹配 ${asset_name} 的下载文���"
    echo "请访问 https://github.com/${REPO}/releases/latest 手动下载"
    exit 1
  fi

  VERSION=$(echo "$release_json" | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)
  echo "最新版本: ${VERSION}"
}

# 下载二进制
download_binary() {
  local output="${INSTALL_DIR}/${BINARY_NAME}"
  if [ "$OS" = "windows" ]; then
    output="${output}.exe"
  fi

  echo "下载 ${BINARY_NAME} (${OS}/${ARCH})..."
  curl -fsSL -o "$output" "$DOWNLOAD_URL" || {
    echo "下载失败"; exit 1
  }
  chmod +x "$output"
  echo "已下载到: ${output}"
  BINARY_PATH="$output"
}

# 运行
run_binary() {
  echo ""
  echo "========================================"
  echo "主控地址: ${MASTER}"
  echo "========================================"
  echo ""
  exec "$BINARY_PATH" -master "$MASTER" -token "$TOKEN"
}

detect_platform
get_download_url
download_binary
run_binary
