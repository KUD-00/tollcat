# UI 冒烟（Maestro）

iOS 模拟器和 Android 模拟器共用这几份 YAML。断言和点击全部按 id，不按文字，所以三语都能跑。

- id 的唯一权威是 `shared/ui-test-ids.json`，生成 `UITestID.swift`（`.accessibilityIdentifier`）和
  `UITestId.kt`（`Modifier.testTag`，根上开了 `testTagsAsResourceId`）。改表跑 `python3 scripts/generate-shared.py`。
  流程里用了没登记的 id、或表里有没人引用的 id，生成器都会红。平台自带的 id（iOS `BackButton`）登记在 `system` 里，只放行不生成。
- 跑：`bash scripts/maestro-smoke.sh`（iOS）/ `bash scripts/maestro-smoke.sh android`。CI 只跑 iOS 模拟器那一份。
- 装 Maestro：`curl -fsSL https://get.maestro.mobile.dev | bash`，装到 `~/.maestro`。它是开发工具，不进 target。
- 启动参数两套键都传：iOS 认 argv（`-seed-demo`），Android 认 intent extra（`seed_demo`），各端只看自己的。

只放冒烟：启动、跳引导、种子出数、进服务、开向导、切一个设置。图表、猫、菜单栏、Mac、Windows
不在这里——黑盒定位不稳，Maestro 也不支持桌面端。
