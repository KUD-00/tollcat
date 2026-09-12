# 给写代码的 agent

## 你在做什么

一个 iOS 26 / macOS 26 原生 App，把八个云/AI 服务的账单加在一起算一个总数。SwiftUI，无后端，凭据只存本地 Keychain。Mac 是 `Mac/` 薄壳，不要 Mac Catalyst，也不要让 iOS 包在 Apple Silicon 上冒充 Mac 版。

必读，按顺序：

1. `ARCHITECTURE.md` —— 依赖方向的合约，**不可协商**
2. `docs/SPEC.md` —— 产品与视觉规格，唯一事实来源
3. `docs/DESIGN-BAR.md` —— **做到什么程度**。所有 UI 任务的验收关卡
4. `BRAND.md` —— 对外文字（`site/`、App 文案、商店页）的语气验收关卡。碰文案必读

目标是让人以为这是 Apple 自己出的 App。功能对了只是及格线，不是完成。

## 现在的阶段

**真实账单接口。** 有公开只读账单接口的走对应 `BillingProvider` + 真 HTTP。没有接口的不进取数 map。不要再引入 `MockBillingProvider`，也不要给运行时留 mock / live 开关。

单测只在传输层注入 `StubHTTPClient`。Preview / 演示种子可以用 SPEC 第 04 节那组设计稿数字（AWS 21.40 / Cloudflare 11.05 / OpenAI 7.62 / GitHub 4.00 / Neon 3.13 / Vercel 免费额度 34% / 合计 ≈47.20），那不是运行时取数。

## 不许做的事

- **不要编辑 `.pbxproj`。** 两份工程都由 XcodeGen 生成：`project.yml`（iOS）和 `project-mac.yml`（Mac），共用的部分在 `project-common.yml`。要加 target 或改 capability，改对应的 spec 然后 `nix shell nixpkgs#xcodegen -c xcodegen generate`（Mac 那份加 `--spec project-mac.yml`）。
- **不要放宽 `Package.swift` 里的依赖。** 觉得需要反向依赖，说明设计错了——定个协议，在 `AppEnvironment` 注入。
- **不要引入第三方库。** 一个都不要。唯一的既定例外是 Mac 直发版的自动更新框架 Sparkle：它只写在 `project-mac.yml` 里、只链进 `TollCatMac`、只在 `Mac/MacUpdater.swift` 里 import，不进 MeterKit，也不进 iOS 工程（SPM 的包解析是工程级的，写进 iOS 那份 spec 就等于 iOS 构建也要联网解析它——`check-source-invariants.py` 按这条扫）。别再加第二个。
- **不要手搓 Liquid Glass。** 玻璃是系统给的，见 SPEC 第 04 节。
- **不要在 `MeterCore` 里出现 `Date()`。** 时间从参数进来。
- **不要在 Features 里写字面色值和魔法间距。** 全走 `MeterDesign` 的 token。
- **不要手改带 `GENERATED` 头的文件。** 它们是 `shared/*.json` / xcstrings 的生成物
  （见 `ARCHITECTURE.md` 的「事实源注册表」）。改权威文件，然后跑对应生成器：
  `python3 scripts/generate-shared.py`（glyph / 猫 / JNI 文案 / API 契约）、
  `python3 scripts/generate-android-strings.py`（Android 的 en/ja）、
  `python3 scripts/render-app-icon.py`（品牌图标全部槽位）。
  提交闸的 regenerate-diff 会抓手改。
- **不要提交 secrets**，也不要在代码或 fixtures 里放任何真实 key。
- **不要用 `git commit --no-verify` 绕过 hook。** 闸红了就补译文或改清单，不要关闸。
- **不要碰 git 的破坏性命令**：`checkout` / `restore` / `reset` / `stash` / `clean` 一律不许用。
  工作区里有不属于你的改动是正常的——可能是别的 agent 在并行写另一个模块，也可能是
  人在改文档。**看到就绕开，不要"清理"。** 提交也不要做，由验收方统一提交。

## 做完一件事的标准

不是"写完了"，是这四条同时成立：

1. `swift test --package-path Packages/MeterKit` 全绿
2. `xcodebuild ... build` 过（命令见 `ARCHITECTURE.md` 末尾）
3. 新增的 View 都有能跑的 `#Preview`，light 和 dark 各看一眼
4. 改了用户可见文案：`python3 scripts/check-i18n-coverage.py` 必须绿。
   改 `L("…")` 的同时在**同一模块** `Resources/Localizable.xcstrings` 补 `en` / `ja`。
   只看中文界面不算做完。改的句子如果 Android 也在用（`values/strings*.xml` 的中文和
   xcstrings 同文），跑 `python3 scripts/generate-android-strings.py` 铺 Android 的 en/ja；
   Android 独有的句子把 en/ja 写进 `Android/app/strings-android-only.json`。
5. 动了模块边界、出站、取景框或迁移载荷字段：`python3 scripts/check-source-invariants.py`；动了列表行热区、主操作栏、键盘收起、sheet 关闭、抽屉 chrome、下拉刷新：`python3 scripts/check-design-lint.py`
   和 `bash scripts/check-outbound-hosts.sh` 必须绿。提交闸会跑这几条。
   动了权限、隐私清单、App 图标或 entitlements：`python3 scripts/check-app-store-invariants.py` 必须绿。
6. 改动只在本次任务的范围内——不要顺手重构别的模块
7. 改了 `MeterFeatures/<目录>`、`MeterModules/` 或 `MeterBridge`：不必同一次改 Android / Windows。
   跟进用 `python3 scripts/check-follow-up.py due/show/stamp`，说明见 `docs/FOLLOW-UP.md`。
   预提交只核地图合法性，过期戳不红。

然后停下来报告，别自己往下一个任务冲。

## 风格

- 源语言简体中文，英文标识符
- 用户可见文案一律走当前模块的 `L("中文")`（`LocalizedStringResource`，bundle 钉死 `Bundle.module`）。
  SwiftUI 的 `Text("…")` 默认查 `Bundle.main`，SPM 模块会静默回落成 key。
  非 `Text` 同样走 `L`：`Button`、`Label`、`navigationTitle`、`accessibilityLabel`、
  `confirmationDialog`、`ContentUnavailableView`。需要 `String` 时写
  `String(localized: L("…"))`。
- 新文案：代码里写中文源串，再在**该模块** `Resources/Localizable.xcstrings` 补 `en` / `ja`。
  提交前的闸和 CI 都跑 `scripts/check-i18n-coverage.py`（判据与 `LocalizationCoverageTests` 相同）。
  本机一次：`bash scripts/git-hooks/setup-hooks.sh`。闸里还有源码隔离、出站域名、
  App Store 权限/隐私清单（`scripts/check-app-store-invariants.py`）。
  再加一门语言只加 catalog 列，不动代码。
  Widget 不能自己声明 catalog（会改 pbxproj），走 `MeterDesignText.resource`。
  App 壳必须有一份 `App/Resources/Localizable.xcstrings`（哪怕只有显示名），
  否则主 bundle 没有 en/ja.lproj，`-AppleLanguages` 切语言时 SPM catalog
  会静默回落源语言。
  系统权限弹窗不走 `L()`：中文源串写在 `project.yml` 的
  `INFOPLIST_KEY_NS*UsageDescription`，en / ja 写在 `App/Resources/InfoPlist.xcstrings`。
  新申请一种权限，两边和对应 API 一起加，闸会核对。
- `ProviderDescriptor.searchKeywords` 是匹配数据，中英别名放同一个数组，**不进 catalog**。
- 注释写"为什么"，不写"是什么"。`// 计算总和` 这种删掉
- 一个类型一个文件，文件名 = 类型名
- 宁可多一个小类型，不要一个大 struct 兼职三种角色
- 命名跟着 SPEC 的中文概念走：`MonthToDate`、`Confidence`、`ProviderKind` —— 不要自创同义词
- 钥匙叫「凭据」。教程主按钮是「我拿到凭据了，下一步」。禁止项表在 `COPY_TERMS`（`LocalizationCoverageTests` 和 `scripts/check-source-invariants.py` 各一份，改了两边一起改）。

## 边界

拿不准就停下来问，不要猜着往下写。具体这几种情况必须问：

- SPEC 和 `ARCHITECTURE.md` 打架
- 需要新增一个 target、一个 capability、一个 entitlement
- 需要改 `Package.swift` 的依赖关系
- SPEC 第 13 节列的未决事项挡住了你
