#!/bin/sh
# LuWu Harness — 生成可分发的 DMG 安装镜像（macOS）
#
# 用法（在仓库根目录）：
#   bash lwh/make-dmg.sh
#
# 前置：先跑过 lwh/package-mac.sh，让 .app 存在。
#
# 镜像布局是「LuWu Harness.app + Applications 快捷方式」：
# 打开 DMG 后把应用拖进 Applications 即安装完成。
#
# 注意：本脚本调用系统自带 hdiutil。若在受限环境（沙箱）里运行会报
#      「操作不被允许」，请在普通终端中运行。

set -e

REPO_ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd -P)"
TARGET="${1:-mac-arm64}"
case "$TARGET" in
  mac-arm64|mac-x64) APP_BUNDLE="LuWu Harness.app" ;;
  *) echo "lwh/make-dmg.sh: 不支持的 target: $TARGET" >&2; exit 1 ;;
esac

APP="$REPO_ROOT/apps/desktop/.desktop-build/targets/$TARGET/artifacts/$TARGET/$APP_BUNDLE"
VERSION="$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$REPO_ROOT/apps/desktop/package.json" | head -1)"
OUT_DIR="$REPO_ROOT/dist"
DMG_NAME="LuWu-Harness-${VERSION}-$( [ "$TARGET" = mac-arm64 ] && echo macOS-arm64 || echo macOS-x64 ).dmg"
DMG="$OUT_DIR/$DMG_NAME"

if [ ! -d "$APP" ]; then
  echo "找不到已打包的应用：$APP" >&2
  echo "请先执行：bash lwh/package-mac.sh $TARGET" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/lwh-dmg.XXXXXX")"
# shellcheck disable=SC2064
trap "rm -rf '$STAGE'" EXIT INT TERM

echo "==> 准备镜像内容（拷贝约 1 GB）"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

echo "==> 生成 DMG：$DMG"
rm -f "$DMG"
hdiutil create -volname "LuWu Harness" -srcfolder "$STAGE" -format UDZO -ov "$DMG"

echo "==> 校验"
hdiutil verify "$DMG" >/dev/null 2>&1 && echo "    镜像校验通过"
echo "    文件：$DMG"
echo "    大小：$(( $(stat -f %z "$DMG") / 1048576 )) MB"
