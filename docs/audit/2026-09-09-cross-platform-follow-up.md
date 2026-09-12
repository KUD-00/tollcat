# 跨端跟进：按目录点头

| 字段 | 值 |
|---|---|
| 状态 | 已落地。操作说明见 [`docs/FOLLOW-UP.md`](../FOLLOW-UP.md) |
| 日期 | 2026-09-09 |
| 对标 | [`docs/RELEASE.md`](../RELEASE.md)、[`ARCHITECTURE.md`](../../ARCHITECTURE.md) 事实源注册表 |

## 一句话

盖戳记的是「这个 Apple 目录自上次点头之后改过，某跟随端的人看过 diff」。不发明「能力」，不维护跨语言依赖表。Apple 先合。没点头不等于 iOS 不能发，只表示那一端还不能声称跟进完成。

按文件盖戳太碎；按能力盖戳要多养一套分类账。按**已经存在的目录**盖戳，发现和归属跟大家加文件的方式相同。

## 戳在记什么

不是「这条 Kotlin 对应那条 Swift」。

是：从上次该端点头到现在，这个 Apple 目录里（排除名单之外）的源码内容变了。有人看过 canonical diff，选了下面之一，才算这端跟上了这一摊：

| 决策 | 意思 |
|---|---|
| `reviewed` | 看过；该改的改了，或不需要改 |
| `n/a` | 这端没有这一摊（例如 Android 没有分享卡、CLI 没有 GUI） |
| `deferred` | 这端以后做；债仍列出来，不算跟上 |

看完改哪、改不改，仍是人的事。机制不编码依赖。

## 看哪些目录

只盯 Apple 侧已经存在的文件夹。右边「跟随端往哪看」是给人的提示，**闸不核对**——提示过时，人仍看得到 Apple diff；闸只对 Apple 目录的内容哈希负责。

| id | Apple 目录 | Android 提示 | Windows 提示 | CLI |
|---|---|---|---|---|
| `dashboard` | `Packages/MeterKit/Sources/MeterFeatures/Dashboard/` | `Android/.../dashboard/`、`DashboardScreen.kt` | `Views/DashboardPage.cs` | `n/a` |
| `modules` | `Packages/MeterKit/Sources/MeterModules/` | 同上（模块载荷；Android 不链这个 target，只渲染桥 JSON） | 同上 | `n/a` |
| `services` | `Packages/MeterKit/Sources/MeterFeatures/Services/` | `services/`、`ServicesScreen.kt`、`ProviderDetailScreen.kt`、`AddProviderScreen.kt` | `ServicesPage.cs`、`ProviderDetailPage.cs`、`AddProviderPage.cs` | `n/a` |
| `setup` | `Packages/MeterKit/Sources/MeterFeatures/Setup/` | `setup/`、`OnboardingScreen.kt` | `SetupWizardPage.cs` | `n/a` |
| `settings` | `Packages/MeterKit/Sources/MeterFeatures/Settings/` | `settings/`、`SettingsScreen.kt` | `SettingsPage.cs` | `n/a` |
| `developer` | `Packages/MeterKit/Sources/MeterFeatures/Developer/` | `developer/` | `n/a`（无画廊） | `n/a` |
| `share` | `Packages/MeterKit/Sources/MeterFeatures/Share/` | `n/a` | `n/a` | `n/a` |
| `shell` | `MeterFeatures/` 根上的 `.swift`（不含子目录） | `TollCatApp.kt`、`MainActivity.kt` | `MainWindow.xaml.cs` | `n/a` |
| `bridge` | `Android/native/Sources/MeterBridge/*.swift` | `CatalogModels.kt`、`MeterCoreNative.kt`、`TollCatSession.kt` | `Models/CatalogModels.cs`、`Native/`、`Services/Session.cs` | CLI 落地后必看 |

新文件丢进其中一个目录，自动进该目录的哈希。新目录极少见：加一行到这张表，并在 `scripts/follow-up.json` 的 `watches` 里加一条。

`MeterFeatures/Resources/`（xcstrings）不看：三语已有 `check-i18n-coverage.py` / `check-copy-freshness.py`。

## 排除名单（一年难得改）

和架构边界重合，不是另造分类：

- `MeterCore/`、`MeterProviders/`、`MeterFormat/`：同一份 Swift 编进 `.so` / `.dll` / CLI，不用点头
- 源文件带 `GENERATED` 头：已有 regenerate-diff
- `MeterDesign/`：Apple 视觉 token；猫几何 / 色板已生成，动效常数已有 `check_cat_motion_constants`
- 文件名匹配 `*Pad*`、`*Mac*`、`*MenuBar*`、`*Widget*`（含 `Onboarding*Widget*`）：那一端的皮
- `Packages/MeterKit/Tests/`、`App/`、`Mac/`、`Widget/`：Apple 壳与测试
- `MeterPersistence/`（除已在 `CORE_PATHS` 里的 Catalog）：SwiftData / Keychain，不跨端

哈希时丢掉注释和空行（复用 `scripts/_swift_scan.py` 抹注释）。`#Preview` 体仍算进去也无妨——目录级本来就会多报，代价是多看一眼 diff。不在 v1 剥 Preview、不剥 import。

## 发现 / 依赖 / 维护

| 问题 | 答案 |
|---|---|
| 新能力怎么发现？ | 不发现能力。文件进了哪个目录，就进哪一摊的 diff。 |
| 依赖怎么知道？ | 不知道。`show` 列出该目录相对上次戳变动的文件。人看。 |
| 维护什么？ | 上面那张目录表 + 排除名单。不维护 276 份文件的对应，也不维护「筛选 / 向导 / 提醒」条目。 |

粗的代价：`Dashboard/` 里只改了猫的位置，筛选没变，整个 `dashboard` 戳仍过期。接受。比养能力表便宜。

## 三条命令

```bash
python3 scripts/check-follow-up.py due --platform android
python3 scripts/check-follow-up.py show dashboard --platform android
python3 scripts/check-follow-up.py stamp dashboard android --decision reviewed --note "取景框仍只送 monthsBack，这轮只动了猫位置"
```

- `due`：该端每个 watch 的当前哈希 vs 戳；无戳或哈希不同且决策不是 `n/a`，即未跟上。
- `show`：对该 id 打出相对上次戳的 canonical diff（无戳则打目录现状）。这是看的入口，不是盖戳的前置令牌。
- `stamp`：写入该端该 id 的当前哈希、决策、说明、日期。`n/a` 的 id（表里整端都是 n/a）可以预置，不必每次盖。

过程数据放 `scripts/follow-up.json`（`watches` + `excludes` + `stamps`），不进 `shared/`。JSON 按 id 排序，便于并行改不同目录时合并。不承诺无冲突。

## 闸什么时候红

和 [`docs/RELEASE.md`](../RELEASE.md) 的 `WAVE_LAG=2` 一致：**不挡 Apple 提交。** 禁止做成文案闸那种「改 Swift 必须同一次 commit 改完 Kotlin」。

| 时机 | 行为 |
|---|---|
| 预提交 / CI 静态闸 | 只红：JSON 坏了、watch 路径 404、stamp 指向不存在的 id。**过期戳不红。** |
| `due`（人跑、发版时跑） | 列出未点头的 `(platform, id)` |
| `scripts/release-status.sh` | 在原有「该不该考虑发」之外加一行「未点头：dashboard, setup」。不把未点头折叠进原来的 `due`（那是班车启发式，不看 `MeterFeatures` / `MeterBridge`）。v1 **不**用未点头拦住打 tag——跟进完成和能不能发是两句话 |

不防看了但不懂，也不防乱写 note。发版时人读 `due` 列表，和现在 Environment 审批是同一层。

## 硬事实仍走现有那种小闸，不塞进盖戳

盖戳回答「看过没有」。下面这种「两个数字必须一致」继续写成 `check-source-invariants.py` 里那种十几行的检查，各管各的：

- JNI schema **版本号**（已有 `check_jni_schema`）
- 账本版本常数（Android `SqliteLedgerStore` `VERSION = 6` vs Windows `JsonLedgerStore` `Version = 4`：今天已经分叉；要闸的话单独加一条，不要靠 `bridge` 目录戳去间接抓住）
- 生成物、三语、猫动效、catalog symlink、出站域名：不动

桥 JSON 加了字段、旧 Kotlin 没送——`show bridge` 会把 `ProductDashboard.swift` 的 diff 摊开。v1 靠人看。不要在盖戳里做字段库存。

## Linux / CLI

没有第三套 GUI。[`docs/cli/SPEC.md`](../cli/SPEC.md)：Linux 原生是终端 `tollcat`。跟随端 id 叫 `cli`，不是 `linux`。

`CLI/` 不存在时：所有 GUI 目录隐式 `n/a`，`bridge` 也可以先 `n/a`。`CLI/` 落地的那次改动必须给 `bridge` 盖 `reviewed`（CLI 直接链 MeterBridge），GUI 目录保持 `n/a`。

## 明确不做

- 不按 Swift 文件盖戳
- 不按「筛选 / 向导 / 提醒」这种能力盖戳（调研过，要多养一张会烂的表）
- 不要求 Apple UI 与 Android 同一次 commit
- 不把 `check-design-lint.py` 套到 Android / Windows
- 不把 MeterBridge 塞进 `release-status.sh` 的 `CORE_PATHS`
- 不编辑 `.pbxproj`，不引入第三方库，预提交保持秒级静态

## 落地（一刀）

一个 PR 就够：

- `docs/FOLLOW-UP.md`（本文缩短后的操作说明）
- `scripts/follow-up.json`（上表九条 watch + 排除 glob + 空 `stamps` 或预置的 `n/a`）
- `scripts/check-follow-up.py`（`due` / `show` / `stamp` / `check`）
- `scripts/_swift_scan.py` 如需给「只抹注释、保留字符串」留一个入口，给哈希用
- `pre-commit-gate.sh` 只跑 `check`（合法性，不过期）
- `scripts/release-status.sh` 人读输出加「未点头」一行；`--json` 加 `followUp.unacked` 数组，不改变现有 `due` 含义

验收：只改 `DashboardFilterSheet.swift`，预提交绿，`due --platform android` 列出 `dashboard`；`show dashboard` 能看到那份 diff；stamp 之后 due 清空；只改 `MeterCore` 或带 `GENERATED` 头的文件，due 不动。
