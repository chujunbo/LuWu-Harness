# LuWu Harness

English | [中文](README.zh.md)

LuWu Harness (`LWH`) is a **privately branded, self-hosted distribution** built from the open-source
[DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) agent harness (MIT). It keeps the
upstream plugin architecture and the complete agent capability set, and changes what a private
deployment needs: the product identity, the first-run flow, the default data destinations, and the
packaging chain.

Current version: **1.0.0** (kernel: upstream `dsh-v0.2.0-rc.2`).

## What this is

Everything an agent can do is upstream and unchanged — the agent loop, tools, sandbox, skills,
subagents, workflows, session format, and model adapters are byte-for-byte the released kernel. What
this distribution changes:

| Area | Upstream | LuWu Harness |
| --- | --- | --- |
| Identity | DeepSeek wordmark and copy | LuWu Harness tiger mark, icons, menus, dialogs |
| First run | Sign in / add API key | **Enter** / add API key — no sign-in control |
| Harness home | `~/.dsh` | **`~/.lwh`** (never shares profiles, sessions, or credentials) |
| Desktop port | 19387 | **19388** (runs beside a released install) |
| Telemetry export | on | **off by default** |
| Session-log upload | on | **off by default** |
| Contact questionnaire | vendor form | removed (placeholder; point it at your own form) |
| Code signature | signed + notarized | unsigned (first launch needs one manual allow) |

Account plugins are still loaded — only their UI entry point is gone. Disabling them outright hangs
startup, because six other rows consume the account service.

## Requirements

| Component | Version | Notes |
| --- | --- | --- |
| OS | macOS 13+ | The packaging targets are `mac-arm64` and `mac-x64` |
| Node.js | `^22.19 \|\| >=24` | **24 recommended** |
| pnpm | `11.7.0` | Must match `packageManager` in the root `package.json` |

Do **not** build with the Node.js bundled inside a released `DeepSeek Harness.app`: it runs under a
hardened runtime with library validation enforced, and rejects the ad-hoc signed native modules this
repository installs.

## Build and run

`lwh/env.sh` prepares Node, pnpm, and an out-of-tree pnpm store. Source it first — every command
below assumes it.

### Install dependencies

```sh
. lwh/env.sh
pnpm install
```

### Run in development

```sh
. lwh/env.sh
pnpm run build          # build runtime and client artifacts
pnpm run dev:desktop    # build, then launch the desktop application
pnpm run dev:web        # build, then serve the Web UI and rebuild client bundles on edit
```

`pnpm run build` writes the artifacts a later `pnpm dsh web` or `pnpm run start:desktop` reuses
without rebuilding.

### Package a distributable

```sh
bash lwh/package-mac.sh            # build + package (local unsigned)
bash lwh/make-dmg.sh               # optional: turn the packaged .app into a drag-to-install DMG
```

Outputs:

| Path | Contents |
| --- | --- |
| `apps/desktop/.desktop-build/targets/mac-arm64/artifacts/mac-arm64/LuWu Harness.app` | the packaged application |
| `apps/desktop/.desktop-build/targets/mac-arm64/artifacts/deepseek-harness-<version>-mac-arm64.zip` | distributable archive |
| `dist/LuWu-Harness-<version>-macOS-arm64.dmg` | DMG created by `lwh/make-dmg.sh` |

Both scripts run unsigned (`DSH_DESKTOP_LOCAL_UNSIGNED=1`), which skips Apple signing, notarization,
and the packaged-runtime smoke check. With an Apple Developer certificate, unset that variable and
build through the upstream signed path instead. `hdiutil` must run outside a sandbox — a restricted
shell fails it with "operation not permitted".

## Versioning

All 318 member packages and 5 applications share **one** synchronized version. Never edit the
manifests by hand; use the repository's release tool, which rewrites every manifest plus the
lockfile and commits only those files:

```sh
. lwh/env.sh
pnpm run release:dsh 1.0.0 --dry-run                    # preview the whole member list
pnpm run release:dsh 1.0.0                              # bump + commit
npx tsx scripts/release/verify.ts --family dsh          # verify the baseline
```

`apps/desktop/package.json` supplies the version that reaches the bundle's
`CFBundleShortVersionString`. A **stable** version needs the `test` prerelease field in a build
version (`1.0.0-test.<date>.<n>`); `desktopBuildVersionPrefix()` derives it.

## Repository layout

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

Build output stays out of the tree: `lib/`, `apps/web/dist/`, `apps/desktop/.desktop-build/`, and
`.lwh-runtime/` are all ignored.

## Configuration and data

The application keeps every mutable file under its own home, `~/.lwh`, so a released DeepSeek
Harness installation is never touched. Set `DSH_HOME` to relocate it.

| Path | Contents |
| --- | --- |
| `~/.lwh/.credentials.yaml` | API keys and stored credentials (file-backed) |
| `~/.lwh/profiles/desktop/cordis.patch.yml` | the profile patch the Settings UI edits |
| `~/.lwh/storages/` | workspace and plugin storage |
| `~/.lwh/sessions/` | session logs |

Configure models in **Settings → Models**:

- **Hosted API** — enter the provider's API key; the default route is `deepseek-official`.
- **Local model** — add a custom provider: `Base URL http://127.0.0.1:11434/v1`, OpenAI-compatible
  protocol, model id such as `llama3.1` (run `ollama serve` first).

Replacing the application never touches `~/.lwh`, so an upgrade keeps its configuration. Do not
change `productName` or the `DSH_HOME` default in `apps/desktop/src/main.ts` if you want that to
hold.

## Privacy defaults

Three outbound paths ship disabled, in the profile bundles rather than in a local override:

| Row | Bundle | Effect |
| --- | --- | --- |
| `session-log-deepseek` | `packages/bundle/base` | no session-log suffix on official API requests |
| `session-telemetry-otel` | `packages/bundle/base` | no OTel export to the vendor collector |
| `desktop-product-telemetry` | `packages/bundle/web-app` | no product analytics, desktop included |

The contact questionnaire URL defaults to a placeholder in
`packages/client/ui-settings-account/src/contact-config.ts`; override `contactFormUrl` from a profile
patch to use your own form.

Verify the composed result rather than the source:

```sh
DSH_HOME=/tmp/lwh-check "$PWD/apps/desktop/.desktop-build/targets/mac-arm64/artifacts/mac-arm64/LuWu Harness.app/Contents/Resources/runtime/cli/bin/dsh" \
  --profile web --dump-config | grep -B1 -A2 'id: session-telemetry-otel'
```

## Testing

```sh
. lwh/env.sh
pnpm run typecheck
pnpm run test
```

Two caveats about this repository's suite:

- Some suites allocate PTYs, spawn child processes, or nest `sandbox-exec`. In a restricted shell
  those fail with `EPERM: operation not permitted` — an environment limit, not a regression.
- Run suites through `pnpm`, not `npx`: a few specs call `pnpm pack` through `npm_execpath`.

## Troubleshooting

| Symptom | Cause and fix |
| --- | --- |
| `webserver (required): listen EADDRINUSE 127.0.0.1:19387` | A released install holds that port. LuWu Harness defaults to 19388; override with `DSH_DESKTOP_PORT` |
| "Cannot verify the developer" on first launch | The build is unsigned. Right-click → Open, or `xattr -dr com.apple.quarantine "/Applications/LuWu Harness.app"` |
| Settings look empty | A different `DSH_HOME` is in effect; configuration lives in `~/.lwh` |
| `koffi` fails to install | Building with the Node bundled in the released app. Use Node 24 from `lwh/env.sh` |
| `hdiutil: create failed` | Running `lwh/make-dmg.sh` inside a sandbox. Run it in a normal terminal |

## License

[MIT](LICENSE), inherited from DeepSeek Harness. Third-party dependencies and their licenses are
disclosed in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

Upstream project: <https://github.com/deepseek-ai/deepseek-harness> — please cite it as

```bibtex
@misc{deepseek-harness2026,
  title={DeepSeek Harness: Everything is a Plugin},
  author={DeepSeek-AI},
  year={2026},
  publisher={GitHub},
  howpublished={\url{https://github.com/deepseek-ai/deepseek-harness}},
}
```
