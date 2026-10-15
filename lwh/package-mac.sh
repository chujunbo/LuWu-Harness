#!/bin/sh
# LuWu Harness — 从源码构建并打包（macOS）
#
# 用法（在仓库根目录）：
#   bash lwh/package-mac.sh
#
# 产物：
#   apps/desktop/.desktop-build/targets/mac-arm64/artifacts/
#     ├── mac-arm64/LuWu Harness.app                     未压缩应用（lwh/make-dmg.sh 用它做 DMG）
#     └── deepseek-harness-<版本>-mac-arm64.zip          可分发压缩包
#
# 本机构建使用「本地未签名」模式（DSH_DESKTOP_LOCAL_UNSIGNED=1）：
#   · 跳过 Apple 签名 / 公证 / 签名后校验（没有开发者证书也能出包）
#   · 跳过 packaged-runtime 冒烟自检（该自检在本类环境下会因原生模块加载失败而中断，
#     应用正确性改由「实际启动」验证）
# 有 Apple 开发者证书时不要设该变量，走官方签名 + 公证流程。

set -e

REPO_ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd -P)"
export LWH_REPO_ROOT="$REPO_ROOT"
cd "$REPO_ROOT"
# shellcheck disable=SC1091
. "$REPO_ROOT/lwh/env.sh"

export DSH_DESKTOP_LOCAL_UNSIGNED=1
export ELECTRON_BUILDER_CACHE="${ELECTRON_BUILDER_CACHE:-$LWH_RUNTIME_DIR/electron-builder-cache}"
# 受限网络下可指向镜像；默认不设置，走官方源。
#   export ELECTRON_BUILDER_BINARIES_MIRROR=https://registry.npmmirror.com/-/binary/electron-builder-binaries/

TARGET="${1:-mac-arm64}"

echo "==> 打包 $TARGET（首次约 6–10 分钟）"
pnpm --filter @deepseek-ai/dsh-desktop run "package:$TARGET"

echo ""
echo "==> 产物："
ls -la "$REPO_ROOT/apps/desktop/.desktop-build/targets/$TARGET/artifacts" 2>/dev/null \
  | grep -E "\.app|\.zip|\.dmg" || true
echo ""
echo "下一步（可选）：生成 DMG →  bash lwh/make-dmg.sh"
