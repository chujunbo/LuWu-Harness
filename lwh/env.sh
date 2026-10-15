#!/bin/sh
# LuWu Harness — 本地构建环境
#
# 用法（必须在仓库根目录引入）：
#   cd "/path/to/LuWu Harness"
#   . lwh/env.sh
#   pnpm install
#
# 提供：Node 24、pnpm 11.7.0，以及放在仓库之外的 pnpm store/cache。
#
# 注意：本文件会被 source，而 POSIX 下 source 不会改变 $0，因此仓库根取自
#      $LWH_REPO_ROOT 或当前目录，并做存在性校验；脚本调用方请先导出 LWH_REPO_ROOT。

# ---- 仓库根：优先 LWH_REPO_ROOT，否则取当前目录，并校验 ----
LWH_REPO_ROOT="${LWH_REPO_ROOT:-$PWD}"
if [ ! -f "$LWH_REPO_ROOT/pnpm-workspace.yaml" ] || [ ! -f "$LWH_REPO_ROOT/package.json" ]; then
  echo "lwh/env.sh: 请在仓库根目录引入：cd <repo> && . lwh/env.sh" >&2
  return 1 2>/dev/null || exit 1
fi
export LWH_REPO_ROOT

# ---- Node：需要 ^22.19 || >=24；优先 24 ----
# 说明：不要用已发布应用内置的 Node —— 它以 hardened runtime + 固定 TeamID 运行且仅有
#      allow-jit 权限，强制 library validation，会拒绝 ad-hoc 签名的原生模块
#      （例如 koffi 预编译二进制加载失败）。
LWH_NODE=""
for candidate in \
  "${LWH_NODE:-}" \
  "$HOME/.nvm/versions/node/v24.22.0/bin/node" \
  "$HOME/.nvm/versions/node/v24.21.0/bin/node" \
  "$LWH_REPO_ROOT/.lwh-runtime/node24/bin/node"
do
  if [ -n "$candidate" ] && [ -x "$candidate" ]; then LWH_NODE="$candidate"; break; fi
done
if [ -z "$LWH_NODE" ]; then
  resolved="$(command -v node 2>/dev/null || true)"
  if [ -n "$resolved" ]; then
    major="$("$resolved" -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
    [ "$major" -ge 24 ] 2>/dev/null && LWH_NODE="$resolved"
  fi
fi
if [ -z "$LWH_NODE" ]; then
  echo "lwh/env.sh: 需要 Node 24（未找到）。任选其一：" >&2
  echo "  nvm install 24                      然后重开终端" >&2
  echo "  LWH_NODE=/path/to/node24/bin/node . lwh/env.sh" >&2
  return 1 2>/dev/null || exit 1
fi
export LWH_NODE
PATH="$(dirname -- "$LWH_NODE"):$PATH"
export PATH

# ---- pnpm：需要 11.7.0（匹配根 package.json 的 packageManager） ----
# 两种来源：PATH 上的 pnpm；或已安装应用内置的 pnpm.cjs（纯 JS，对宿主 Node 无签名要求）。
# 后者路径含空格，因此分别保存 node 与 cjs 路径，不做命令字符串拼接。
LWH_PNPM_KIND=""
LWH_PNPM_BIN=""
LWH_PNPM_CJS=""
BUNDLED_PNPM="/Applications/DeepSeek Harness.app/Contents/Resources/runtime/primary-runtime/dependencies/pnpm/bin/pnpm.cjs"
if command -v pnpm >/dev/null 2>&1; then
  LWH_PNPM_KIND="bin"; LWH_PNPM_BIN="$(command -v pnpm)"
elif [ -f "$BUNDLED_PNPM" ]; then
  LWH_PNPM_KIND="cjs"; LWH_PNPM_CJS="$BUNDLED_PNPM"
else
  echo "lwh/env.sh: 需要 pnpm 11.7.0（未找到）。安装：npm i -g pnpm@11.7.0" >&2
  return 1 2>/dev/null || exit 1
fi
export LWH_PNPM_KIND LWH_PNPM_BIN LWH_PNPM_CJS

pnpm() {
  if [ "$LWH_PNPM_KIND" = "cjs" ]; then "$LWH_NODE" "$LWH_PNPM_CJS" "$@"; else "$LWH_PNPM_BIN" "$@"; fi
}
node24() { "$LWH_NODE" "$@"; }

# ---- store / cache：默认放仓库同级，避免写入 $HOME；同级已有则复用 ----
if [ -z "${LWH_RUNTIME_DIR:-}" ]; then
  sibling="$(cd -- "$LWH_REPO_ROOT/.." 2>/dev/null && pwd -P)/.lwh"
  if [ -d "$sibling/pnpm-store" ]; then LWH_RUNTIME_DIR="$sibling"; else LWH_RUNTIME_DIR="$LWH_REPO_ROOT/.lwh-runtime"; fi
fi
export LWH_RUNTIME_DIR
mkdir -p "$LWH_RUNTIME_DIR/pnpm-store" "$LWH_RUNTIME_DIR/pnpm-cache" 2>/dev/null || true
export npm_config_store_dir="$LWH_RUNTIME_DIR/pnpm-store"
export npm_config_cache_dir="$LWH_RUNTIME_DIR/pnpm-cache"

if [ "$LWH_PNPM_KIND" = "cjs" ]; then pnpm_version="$("$LWH_NODE" "$LWH_PNPM_CJS" --version 2>/dev/null)"; else pnpm_version="$("$LWH_PNPM_BIN" --version 2>/dev/null)"; fi
echo "lwh: node $("$LWH_NODE" -v) | pnpm ${pnpm_version:-?} | store $npm_config_store_dir"
