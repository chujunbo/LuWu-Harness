# LuWu Harness

[English](README.md) | 中文

LuWu Harness（简称 LWH）是基于开源项目 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)
（MIT 许可）构建的**私有品牌、自托管发行版**。它保留上游的插件化架构与完整的 agent 能力，改造的是私有
部署真正需要的部分：产品标识、首次启动流程、数据默认去向、以及打包链路。

当前版本：**1.0.0**（内核：上游 `dsh-v0.2.0-rc.2`）。

## 这是什么

agent 能做的所有事情都来自上游且未作改动——agent 循环、工具、沙箱、技能、子代理、工作流、会话格式、
模型适配器与已发布内核逐字节一致。本发行版改动的是：

| 方面 | 上游 | LuWu Harness |
| --- | --- | --- |
| 品牌标识 | DeepSeek 字标与文案 | LuWu Harness 虎头标志、图标、菜单、对话框 |
| 首次启动 | 登录 / 添加 API Key | **进入** / 添加 API Key —— 没有登录控件 |
| 用户目录 | `~/.dsh` | **`~/.lwh`**（不共用 profile、会话、凭据） |
| 桌面端口 | 19387 | **19388**（可与已安装的官方版并存） |
| 遥测上报 | 开 | **默认关闭** |
| 会话日志上传 | 开 | **默认关闭** |
| 反馈问卷 | 原厂商表单 | 已移除（占位地址，可指向你自己的表单） |
| 代码签名 | 签名 + 公证 | 未签名（首次启动需手动放行一次） |

账号相关插件仍然加载——只是界面入口被移除。直接禁用它们会导致启动挂起，因为有六个插件在消费账号服务。

## 运行环境

| 组件 | 版本 | 说明 |
| --- | --- | --- |
| 操作系统 | macOS 13+ | 打包目标为 `mac-arm64` 与 `mac-x64` |
| Node.js | `^22.19 \|\| >=24` | **推荐 24** |
| pnpm | `11.7.0` | 必须与根 `package.json` 的 `packageManager` 一致 |

**不要**用已发布的 `DeepSeek Harness.app` 内置的 Node 构建：它以 hardened runtime 运行并强制 library
validation，会拒绝本仓库安装的 ad-hoc 签名原生模块。

## 构建与运行

`lwh/env.sh` 负责准备 Node、pnpm 与仓库外的 pnpm store。下面所有命令都假设已先引入它。

### 安装依赖

```sh
. lwh/env.sh
pnpm install
```

### 开发运行

```sh
. lwh/env.sh
pnpm run build          # build runtime and client artifacts
pnpm run dev:desktop    # build, then launch the desktop application
pnpm run dev:web        # build, then serve the Web UI and rebuild client bundles on edit
```

`pnpm run build` 的产物会被后续的 `pnpm dsh web` 或 `pnpm run start:desktop` 直接复用，无需重新构建。

### 打包分发

```sh
bash lwh/package-mac.sh            # build + package (local unsigned)
bash lwh/make-dmg.sh               # optional: turn the packaged .app into a drag-to-install DMG
```

产物：

| 路径 | 内容 |
| --- | --- |
| `apps/desktop/.desktop-build/targets/mac-arm64/artifacts/mac-arm64/LuWu Harness.app` | 打包后的应用 |
| `apps/desktop/.desktop-build/targets/mac-arm64/artifacts/deepseek-harness-<版本>-mac-arm64.zip` | 可分发压缩包 |
| `dist/LuWu-Harness-<版本>-macOS-arm64.dmg` | 由 `lwh/make-dmg.sh` 生成 |

两个脚本都以未签名模式运行（`DSH_DESKTOP_LOCAL_UNSIGNED=1`），会跳过 Apple 签名、公证与打包后运行时
冒烟自检。有 Apple 开发者证书时，不要设置该变量，改走上游的签名流程。`hdiutil` 必须在沙箱之外运行——
受限 shell 会报「操作不被允许」。

## 版本号

318 个成员包与 5 个应用共用**同一个**版本号。**不要手工改** manifest，请使用仓库自带的发布工具：它会
重写全部 manifest 与 lockfile，并且只提交这些文件。

```sh
. lwh/env.sh
pnpm run release:dsh 1.0.0 --dry-run                    # preview the whole member list
pnpm run release:dsh 1.0.0                              # bump + commit
npx tsx scripts/release/verify.ts --family dsh          # verify the baseline
```

`apps/desktop/package.json` 的版本会进入产物的 `CFBundleShortVersionString`。**稳定版**的构建版本必须
带 `test` 预发布字段（`1.0.0-test.<日期>.<序号>`），由 `desktopBuildVersionPrefix()` 推导。

## 目录结构

```
LuWu Harness/
├── lwh/                     # this distribution's build entry points
│   ├── env.sh               # Node + pnpm + pnpm store
│   ├── package-mac.sh       # build and package the desktop application
│   └── make-dmg.sh          # packaged .app -> drag-to-install DMG
├── apps/
│   ├── desktop/             # Electron shell: windows, welcome page, packaging scripts
│   ├── desktop-host/        # desktop host process (port, CLI shim)
│   ├── cli/                 # `dsh` command line
│   └── web/                 # Web shell entry and static assets
├── packages/                # 318 workspace packages, grouped by role
│   ├── core/  shell/  fs/  sandbox/  llm/  web/  workflow/  skill/  subagent/ ...
│   ├── client/              # browser half of the Web GUI (slots, components, locales)
│   └── bundle/              # profile bundles: which plugins a profile composes
├── docs/                    # upstream design and user documentation
├── native/  python/         # native addon and Python runtime sources
├── scripts/                 # gates, generators, release tooling
└── package.json             # workspace root: scripts, engine range, packageManager
```

构建产物不进入版本库：`lib/`、`apps/web/dist/`、`apps/desktop/.desktop-build/`、`.lwh-runtime/` 均已被忽略。

## 配置与数据

应用把所有可变文件放在自己的用户目录 `~/.lwh` 下，因此绝不会影响已安装的官方 DeepSeek Harness。可通过
设置 `DSH_HOME` 改变位置。

| 路径 | 内容 |
| --- | --- |
| `~/.lwh/.credentials.yaml` | API Key 与已保存凭据（文件型存储） |
| `~/.lwh/profiles/desktop/cordis.patch.yml` | 设置界面写入的 profile 补丁 |
| `~/.lwh/storages/` | 工作区与插件存储 |
| `~/.lwh/sessions/` | 会话日志 |

在**设置 → 模型**里配置模型：

- **线上 API** —— 填入对应服务商的 API Key；默认路由为 `deepseek-official`。
- **本地模型** —— 添加自定义 provider：`Base URL http://127.0.0.1:11434/v1`、OpenAI 兼容协议、
  模型 id 例如 `llama3.1`（需先运行 `ollama serve`）。

替换应用不会影响 `~/.lwh`，所以升级后配置仍在。若要保持这一点，不要修改 `productName`，也不要改动
`apps/desktop/src/main.ts` 中 `DSH_HOME` 的默认值。

## 隐私默认值

三条外发通道在 **profile bundle 层**（而非本地覆盖）默认关闭：

| 插件行 | 所在 bundle | 效果 |
| --- | --- | --- |
| `session-log-deepseek` | `packages/bundle/base` | 官方 API 请求不再附带会话日志后缀 |
| `session-telemetry-otel` | `packages/bundle/base` | 不再向厂商 collector 上报 OTel 数据 |
| `desktop-product-telemetry` | `packages/bundle/web-app` | 产品分析全部关闭（含桌面档） |

反馈问卷地址在 `packages/client/ui-settings-account/src/contact-config.ts` 中默认为占位地址；可通过
profile 补丁覆盖 `contactFormUrl` 指向你自己的表单。

请验证**组合后的配置**而不是源码：

```sh
DSH_HOME=/tmp/lwh-check "$PWD/apps/desktop/.desktop-build/targets/mac-arm64/artifacts/mac-arm64/LuWu Harness.app/Contents/Resources/runtime/cli/bin/dsh" \
  --profile web --dump-config | grep -B1 -A2 'id: session-telemetry-otel'
```

## 测试

```sh
. lwh/env.sh
pnpm run typecheck
pnpm run test
```

有两点需要注意：

- 部分用例会分配 PTY、派生子进程或嵌套 `sandbox-exec`。在受限 shell 中这些会以
  `EPERM: operation not permitted` 失败——这是环境限制，不是回归。
- 请用 `pnpm` 而不是 `npx` 运行：少数用例会通过 `npm_execpath` 调用 `pnpm pack`。

## 常见问题

| 现象 | 原因与处理 |
| --- | --- |
| `webserver (required): listen EADDRINUSE 127.0.0.1:19387` | 该端口被已安装的官方版占用。LuWu Harness 默认 19388；可用 `DSH_DESKTOP_PORT` 覆盖 |
| 首次启动提示「无法验证开发者」 | 构建未签名。右键 →「打开」，或执行 `xattr -dr com.apple.quarantine "/Applications/LuWu Harness.app"` |
| 设置里看不到原有配置 | 当前生效的是另一个 `DSH_HOME`；配置在 `~/.lwh` |
| `koffi` 安装失败 | 使用了官方应用内置的 Node。请用 `lwh/env.sh` 提供的 Node 24 |
| `hdiutil: create failed` | 在沙箱内运行了 `lwh/make-dmg.sh`。请在普通终端运行 |

## 许可证

[MIT](LICENSE)，继承自 DeepSeek Harness。第三方依赖及其许可证见
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

上游项目：<https://github.com/deepseek-ai/deepseek-harness> —— 引用方式：

```bibtex
@misc{deepseek-harness2026,
  title={DeepSeek Harness: Everything is a Plugin},
  author={DeepSeek-AI},
  year={2026},
  publisher={GitHub},
  howpublished={\url{https://github.com/deepseek-ai/deepseek-harness}},
}
```
