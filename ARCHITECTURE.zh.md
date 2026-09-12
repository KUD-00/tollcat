# 架构

[English](ARCHITECTURE.md) · 中文

本文件是**依赖关系的合约**。代码可以商量，这里的依赖方向不可以。
产品行为见 [docs/SPEC.md](docs/SPEC.md)。

## 一句话

一个薄得不能再薄的 Xcode 工程壳（iOS App + iOS Widget + Mac App + Mac Widget），逻辑与 UI 都在本地 Swift Package `MeterKit` 里。Android 另有一个 Compose 壳，Windows 另有一个 WinUI 3 壳，都只画界面：折算、取数、格式化、目录、猫气泡选句都链接同一份 Swift（`MeterCore` + `MeterProviders` + `MeterFormat` + 平台中立的 `MeterBridge`；Android 经 JNI，Windows 经 C ABI / P/Invoke）。跨端的纯数据（品牌 glyph、猫几何、API 契约、桥文案表）在 `shared/*.json` 单源，生成物提交进仓库。

## 为什么这么切

1. **`.pbxproj` 不该被 agent 编辑。** 工程文件由 `project.yml`（XcodeGen）生成，加文件不用改它——SPM 按目录自动发现源文件。
2. **依赖方向即产品约束。** 规格第 09 节要求"Widget 不能自己调 API"。与其写注释提醒，不如让 Widget target **根本不链接 `MeterProviders`**——想违规都编译不过。
3. **折算逻辑必须能脱离 UI 和网络单独测。** `MeterCore` 零依赖、纯函数，规格第 02 节那张折算表逐行对应一个测试用例。
4. **`MeterCore` 必须能编到 Android。** 零依赖的第二个、也更硬的理由：四种钱的折算
   是这个产品真正的资产，它不该和 Apple 平台绑死，也不该再译一份 Kotlin。
   Android 界面走 Compose（`Android/`），折算走官方 Swift Android SDK 编出来的同一份
   `MeterCore`。时间一律从参数注入；**`MeterCore` 里出现任何 Apple 专有 API 都算破坏架构**。

## 目录

```
cost/
├── shared/                     # 跨端事实源（JSON）。改这里，跑 scripts/generate-shared.py
├── project.yml                 # XcodeGen 工程定义：iOS / iPadOS（架构合约，改前先想清楚）
├── project-mac.yml             # 同上，macOS 直发版。Sparkle 只写在这一份里
├── project-common.yml          # 两份 spec 共用的选项与 base settings（团队 ID、版本号）
├── TollCat.xcodeproj           # 生成物，提交进仓库
├── TollCatMac.xcodeproj        # 同上，Mac 那一份
├── TollCat.xcworkspace         # 手写的一小段 XML。只为在 Xcode 里同时开两份工程
│                               # ——本地包 MeterKit 只被加载一次，否则后开的那个报
│                               # Missing package product。命令行仍各自 -project
├── App/                        # iOS 壳:入口 + 组装,不放业务逻辑
│   ├── TollCatApp.swift
│   ├── AppEnvironment.swift    # composition root:唯一 new 具体实现的地方
│   └── Resources/
├── Mac/                        # macOS 壳: WindowGroup + MenuBarExtra。组装复用 AppEnvironment
├── Widget/                     # Widget 源码。iOS / Mac 两个 extension target 各编一份
├── Android/                    # Compose 壳 + JNI。算账、说钱、目录都是 Packages 里那份 Swift
│   ├── app/                    # Kotlin UI + Keystore/SQLite 适配器。不算账、不自己格式化金额
│   └── native/                 # SwiftPM：symlink MeterCore + MeterProviders + MeterFormat + MeterBridge，产出 libMeterCoreJNI.so
│                               #   MeterBridge 是平台中立 JSON 进出；MeterCoreJNI 只剩 JNI 皮
├── Windows/                    # WinUI 3 壳 + C ABI。算账、说钱、目录都是同一份 Swift
│   ├── app/                    # C# UI + 凭据管理器 / JSON 账本。不算账、不自己发 HTTP
│   └── native/                 # SwiftPM：symlink 同上，产出 MeterCoreCLR.dll
├── Packages/MeterKit/
│   ├── Package.swift           # 依赖方向在这里强制,不要放宽
│   ├── Sources/
│   │   ├── MeterCore/          # 领域模型 + 折算 + 厂商身份（ProviderIdentity）。零依赖
│   │   ├── MeterDesign/        # 设计系统。不认识任何领域类型
│   │   ├── MeterFormat/        # 领域值 → 用户可见字符串。只依赖 Core，Widget 和 Features 共用
│   │   ├── MeterProviders/     # 取数。依赖 Core
│   │   ├── MeterPersistence/   # SwiftData + Keychain。依赖 Core
│   │   ├── MeterTips / MeterInbox / MeterFeedback / MeterUsage
│   │   │                       # 叶子：打赏 / 信箱 / 反馈 / 匿名页面计数。不链接 Providers
│   │   ├── MeterModules/       # 仪表盘模块：视图 + 值 + 折算它们的 builder
│   │   │                       # 只依赖 Core/Design/Format —— widget 链得到
│   │   └── MeterFeatures/      # 界面。依赖以上全部
│   └── Tests/
│       ├── MeterCoreTests/     # 重点在这里
│       └── MeterProvidersTests/
├── worker/                     # api.tollcat.app。不碰账单凭据
├── ops/                        # 本机 TUI：用 wrangler 权限看反馈 / 打赏 / 信箱 / 用量 / 迁移
└── docs/SPEC.md
```

## 依赖图（唯一合法方向）

```
        MeterCore  ←──────────────┐
          ↑   ↑                   │
          │   └── MeterProviders  │   （MeterDesign 谁都不依赖）
          │            ↑          │
   MeterPersistence    │     MeterDesign
          ↑            │          ↑
          │            │     MeterModules ──→ Core + Design + Format
          ↑            │          ↑
          └──── MeterFeatures ────┘
                     ↑
                App target        Widget target ──→ Core + Design + Format + Modules + Persistence
                Mac target        Mac Widget        （不含 Providers）
                     │            同一份 Widget/ 源码，各用各的 App Group
                     │
                     │  JNI / C ABI，同一份 Core + Providers + Format + MeterBridge
                     ▼
               Android/app（Compose）    Windows/app（WinUI 3）
```

硬规则：

- `MeterCore` **不 import 任何东西**（Foundation 除外）。不 import SwiftUI、不 import SwiftData、不 import Security。
- **墙钟进 `MeterCore` 只有一个入口：`MeterClock.swift`。** 折算、账本、模块一律拿注入的 `MeterClock` / `now` / `calendar`，别的文件一处 `Date()` / `Calendar.current` 都不许有（闸和 `ArchitectureGuardrailTests` 按这一条扫）。时钟以前住在 Features，字面上守住了「Core 无 `Date()`」，代价是 Modules / Persistence / Widget 拿不到它、各自去捡系统时区——真正的漏在那里。
- `MeterDesign` **不 import 任何 `Meter*` 模块**——它不知道什么是 Provider、什么是 Snapshot，组件收到的是已格式化的字符串和 `0...1` 的比例，不是领域对象。系统的 UI 框架照用（SwiftUI、Charts、CoreGraphics、位图导出要的 ImageIO / CoreImage / UniformTypeIdentifiers、`os`，以及动态 `Color(light:dark:)` 要碰的 UIColor / NSColor；Features 不许直接碰后者）。
- `MeterProviders` 不 import SwiftUI、不 import SwiftData。
- Widget target 不链接 `MeterProviders`（见上文原因 2）。
- 反向依赖一律不允许；需要回调就定协议，具体实现在 `AppEnvironment` 注入。
- **展示路径不持有快照日志。** `Snapshot` 是事件流不是读模型：每次刷新每家写一条，于是「八月花了多少」的成本会正比于**你在八月刷新了多少次**。视图和它的 model 收到的是 `LedgerView`（物化读模型），问的是有名字的问题；原始读数只从门上那个明确开的口出来——`DashboardModel.readings(for:since:)`，而那是一条带范围的查询：**连 `DashboardModel` 自己也不持有日志**，读口在 `MeterPersistence/SnapshotLog`。`check-source-invariants.py` 的 `LEDGER_ALLOWED` 和 `LedgerBoundaryTests` 守这条，**那份名单只减不增**。见 [docs/LEDGER.md](docs/LEDGER.md)。
- **日历日落盘只存分量。** 日桶的键、账本行的月份是日历上的位置，不是某个时区的零点那一刻：`DailySpendCodec` 存 `yyyy-MM-dd`，`MonthlyRollupRecord` 存年 + 月，`SubscriptionRecord` 存年 / 月 / 日，读时按此刻的日历还原（`MeterCore/CalendarKeys.swift` 的 `DayKey` / `MonthKey`）。存时间戳的话换一次时区整张表错一天、同一天被算两遍。
- **`DashboardStore` 的读一律 `throws`。** 读失败长什么样由 `DashboardModel.loadFromPersistence` 一处决定（保留上一份、亮 `PersistenceStatus.didFailToRead`）；下面一层不许把它吞成空数组——那会让一次读错误变成「没有服务」再变成一份空账本。

## 各模块的职责

### MeterCore — 领域模型与折算

零依赖、纯函数、100% 可测。

- `ProviderID`（厂商）、`ProviderMembership`（这家加没加进服务列表）、`AccountID`（一份用量身份：钥匙、快照、刷新；同一厂商可有多份）、`ProviderKind`（`.usage` / `.prepaid` / `.subscription` / `.freeTier`）
- `Money`：USD 金额值类型。**不要在业务里用裸 `Double`。** 展示货币是 `MoneyPresentation`，只在写出字的时候折，不进账本。
  - **明写的例外只有一个：`HistoryChartMath`。** 它出的是**图表几何**（柱高、折线取值、段落做差），要直接喂给 Swift Charts，而 `Plottable` 只吃 `Double`。转换只往这一个方向做——这里算出来的数不许回流进账本。文件头也写着这一条。
  - `Money(roundedUSD:)` 会在**构造时**按分四舍五入（`0.004 → 0`）。它只给夹具和比例用；厂商适配器一律走 `FlexibleDecimal → Money(usd: Decimal)`，一分不丢。名字里带 `rounded` 就是为了让这件事在调用点上看得见——它以前叫 `init(usd: Double)`，和另外两条重载长得一模一样。
  - 金额**怎么写成字**（`$1,234.56`）留在 MeterCore：符号、分位、小数位是 `Money` 自己的事，而且必须**不跟系统区域**（中文 locale 会把美元写成 `US$`，和设计稿对不上）。MeterCore 出**数**，不出**话**：`String(localized:)`、`NumberFormatter`、`DateFormatter`、`Locale.current` / `.autoupdatingCurrent` 一个都不许出现（闸按正则扫，隐式成员写法也算）。跟语言、跟系统区域有关的一切在 `MeterFormat`。
    - **豁免一个文件：`MeterClock.swift`。** 它带 locale 不是为了产出话，是因为「历法 + 时区 + locale」三样合起来才是格式化缓存的钥匙——时钟少一样，两个 locale 下会共用同一份格式化器。名单在 `check-source-invariants.py` 的 `LOCALE_EXEMPT_CORE_FILES` 和 `ArchitectureGuardrailTests.meterCoreStaysPure`，两边一起改。
- `Confidence`：`.exact` / `.estimated` / `.partial`
- `Snapshot`：见 SPEC 第 10 节，字段一一对应
- `MonthToDate`：折算结果
- `MonthToDateCalculator.compute(snapshots:subscriptions:now:calendar:) -> MonthToDate`
  - **时间必须作为参数传入**，模块内不许出现 `Date()` / `Date.now`。否则没法测。

**confidence 是模型算出来的，但不再产出 `≈` 号。** `MonthToDate.confidence` 照旧合并计算（任一家估算则总数是估算），估算的解释走 `estimatedAccounts` 的可查路径（provider 详情页）；金额格式化不输出任何约等标记。

### MeterDesign — 设计系统

规格里那张设计稿的所有视觉决定都落在这里，**只落在这里**。Features 不许出现字面色值、不许出现魔法数字间距。

- `MeterColor`：从设计稿的 CSS 变量原样搬（ground / surface / surface2 / ink / ink2 / ink3 / rule / ruleSoft / accent / accentBright / accentSoft / good / warn / crit + 八家 provider 色），**light + dark 两套**
- `MeterFont`：body（系统字体）/ mono（SF Mono，用于 caption、字段标签、金额）。
  **没有 serif** —— 设计规格文档自己的标题用了 serif，但手机 mockup 内部没有一处设
  `font-family`，全部继承 `-apple-system`。App 用系统字体，金额一律 `.monospacedDigit()`。
- 设计稿那台手机宽 292px 代表 393pt 屏幕，约 1.35×。**不要照抄 px**，优先用 iOS 语义字号。
- `MeterSpacing`、`MeterRadius`
- 组件：`GaugeArc`、`SegmentBar`、`ModuleCard`、`ProviderRow`、`StepList`、`CopyBox`、`CredentialFieldRow`、`FillProgressButton`、`FieldRow`、`PrimaryButton` / `GhostButton`、`StatusPill`
- 每个组件配 `#Preview`，light/dark 各一个

**Liquid Glass 纪律**（SPEC 第 04 节）：玻璃只在系统导航层。本模块**不许**出现 `.ultraThinMaterial` 之类的手搓玻璃。

### MeterProviders — 取数

```swift
protocol HTTPClient: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

protocol BillingProvider: Sendable {
    static var descriptor: ProviderDescriptor { get }
    func fetch(credential: Credential) async throws -> Snapshot
}
```

- `ProviderDescriptor`：静态元数据（id / displayName / kind / colorKey / **billingURL** /
  **credentialSetupURL** / costsMoneyToRefresh / supportsDailyGranularity /
  **minimumRefreshInterval** / **accessStatus**）。
  `minimumRefreshInterval` 给「对方按天限流、或数据按天才更新」的家。
  自动刷新和手动下拉都走 `RefreshCadence`；接入测试和历史回填不走。
  `accessStatus == .declined` 的家目录里留身份和图标，iOS / Android 添加列表和落地页都滤掉。
  **两个 URL 都永远编译进 App，绝不来自远程目录**（SPEC 第 07 节安全红线）：
  `billingURL` 是官网账单页，`credentialSetupURL` 是直达创建 token 的那一页——
  向导要深链到创建页而不是首页（SPEC 第 06 节第一条规则）。
- `HTTPClient` 是传输层接缝。`BillingProvider` 的构造一律吃一个 `HTTPClient`。
  App 注入 `LiveHTTPTransport`；单测注入 `StubHTTPClient`，调用方不用改。
- 有公开只读账单接口的各占一个文件，一家一个 struct，互不知道对方存在。
  没有接口的（AWS Cost Explorer 按次收费、Anthropic 个人账号、信箱四家 Fly / Clerk / Render / Expo）不进取数 map。

#### 测试替身只许打在传输层

1. **传输层** — 注入 `HTTPClient`，返回罐装 HTTP 响应。`URLSessionHTTPClient` 是真实现；
   `StubHTTPClient` 从官方 API 形状的 fixture 读罐装响应。URL 拼装、JSON 解析、状态码映射都真的跑。
2. **provider 层替掉 `fetch`** — 不许。没有 `MockBillingProvider`。
3. **持久层直塞当运行时取数** — 不许。Preview / 演示种子可以写入 SPEC 第 04 节设计稿快照，
   和用户点刷新不是同一条路。

### MeterPersistence — 存储

- SwiftData `@Model`：`SnapshotRecord`（永不删除）、`SubscriptionRecord`、`ProviderConfigRecord`（用量身份）、`ProviderMembershipRecord`（厂商门口）
- **容器从第一天就建在 App Group 里**（SPEC 第 09 节：后期再改会很痛）
- `CredentialStore` 协议 + `KeychainCredentialStore`（`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`）+ `InMemoryCredentialStore`（测试与 Preview 用）
- **SwiftData 里绝不出现密钥本身**，只存 Keychain 引用标识
- 跨设备迁移的加解密和 Keychain 读写在这里。载荷模型在 `MeterCore`（纯 `Codable`，不 import CryptoKit）；AES-GCM + PBKDF2 不许下沉到 Core，也不许进 `MeterProviders`
- `CatalogSource` 协议 + `BundledCatalogSource` + `RemoteCatalogSource`。调用方只认协议。
- `CatalogResolver` 负责三层兜底：打包副本、上次拉成功的缓存、网上最新。启动后台拉一次，失败静默。汇率是目录字段，不另开牌价网络。

### MeterTips / MeterInbox / MeterFeedback / MeterUsage — Worker 叶子

四个模块各自打 `api.tollcat.app` 的一条路，互不 import，也都不链接
`MeterProviders`。见 SPEC 第 12.5 节：有服务端 ≠ 可以用服务端。账单凭据和
账单数据永远不许经过这条链路。Worker 的源码在仓库根目录的 `worker/`。

- `MeterTips`：StoreKit 2 消耗型 IAP + 打赏留言。只依赖 Foundation 与 StoreKit
- `MeterInbox`：读数信箱。依赖 MeterCore（产出 Snapshot），不认识目录
- `MeterFeedback`：应用内反馈。连 MeterCore 都不依赖，拿不到 `Money`
- `MeterUsage`：匿名页面计数。连 MeterCore 都不依赖。只上报允许名单里的
  页面名、平台、UTC 日是否第一次打开。不留设备标识

### MeterModules — 仪表盘的模块

模块的 view、它们读的值（`XxxModuleContent`），以及**把账本折算成这些值的 builder**
（`DashboardContentsBuilder` 是唯一入口）。`DashboardModel`、页面和导航仍在 MeterFeatures。

**有几块由 `DashboardModuleID` 说了算，文档里不写死数字。**写死过一次「12 块」，
下架「即将扣款」之后三处全成了错的——而这种错没有任何一步会发现。
提交闸扫 `N 块模块` / `N dashboard modules` 这两种写法。

**builder 里的规则不在这一层——纯计算的那半在 `MeterCore`。**
`HeatmapMonths`、`CategoryShares`、`SuperlativeSelection`、`BudgetGauge`、`SpendGrouping`：
哪几个月有格子、1 号落在第几格，类别怎么加、为什么整数百分比必须凑够 100，
「涨得最多」挑谁、三块按什么顺序排，预算条什么时候变色，明细怎么分桶、
超出几组折成「其他」。这一层的 builder 只负责把值写成句子。

理由是 Android 和 Windows：它们的桥**链不了这个 target**（经 MeterDesign 带进 SwiftUI），
所以在拆开之前，`ProductDashboardModules.swift` 把其中五个 builder 又实现了一遍——
而且已经漂了。本月之最的顺序不一样，还把整月的涨跌幅安在了构成里第一家头上；
按类别构成各段自己四舍五入，一列数字能加成 99。**两端都需要的规则，
就该放在两端都已经在编的那个零依赖层里。**

单独一个 target 只有一个理由：**widget 链得到**。Widget 不能链 MeterFeatures
（那会把三十多家账单适配器拖进扩展，SPEC 第 09 节也不许 widget 自己调 API）。
折算之所以能一起下来，是因为它要的只有「这家叫什么、什么色、什么类」——
那是 `MeterCore/ProviderIdentity.swift`（生成物，权威在 `ProviderCatalog.swift`），
不是取数。依赖表（Core / Design / Format）就是「widget 会链进什么」的安全说明书，
`ArchitectureGuardrailTests` 和 `check-source-invariants.py` 各扫一遍。

于是主屏上的数字和 App 里的数字是**同一份代码从同一份数据算出来的**，
不是 widget 自己攒的一套简版——后者漂了不会有任何编译期信号。

同一份模块视图要出现在很多壳里：iPhone 列表行、宽壳 bento 卡、iPad/Mac 侧栏卡、
分享卡、iOS / macOS widget。版式差异只由**三根正交的轴**决定：

| 轴 | 取值 | 管什么 | 谁定 |
|---|---|---|---|
| `ModuleWidth` | compact / regular / wide / expanded | 横向排布：图和列表并排还是上下叠、分不分两列 | 容器声明，断点在 `shared/module-size.json` |
| `ModuleHeight` | tight / regular / tall / unbounded | 纵向预算：起头那个大数字要不要、图表多大、列表列几行 | 同上 |
| `ModuleContainer` | listRow / card / snapshot | chrome 与交互：chevron 谁画、行高谁补、能不能点 | 容器声明 |

三根一起给：`.meterModuleStyle(width:height:container:)`。

为什么不能少：一根 bool（「在不在卡里」）表达不了 `systemLarge` 的 widget——它很宽，
但没有 `List`、也点不进任何一行。而高度也不能塞进容器档：widget 的 `systemMedium`
和 `systemLarge` 都是 `.snapshot`、内容宽都约 300，高度却差 2.5 倍。

**模块一律不许自己量尺寸。** 量自身尺寸再据此改版式是「量 → 改内容 → 内容改变理想尺寸」
的反馈环，仪表盘实验室第一版就是这样把主线程转死的（列宽 12pt 一步涨到无限）。
容器全都已经知道自己多大（bento 行算得出卡宽、widget 量得到自己那块地方、分享卡是定宽），
所以这条限制不花代价。闸：`MeterModules` 下出现 `GeometryReader` / `onGeometryChange` 即红。

模块也不知道怎么推页：它只发出路线（`ModuleLink` + `DashboardRoute`），
推法由壳注入（`dashboardModuleLinks()`；widget 注入的是 `Link(destination:)`，
URL 表在 `DashboardDeepLink`）。没人注入时链接退化成纯文字——分享卡要的正是这个。

### Widget — 主屏上的一块仪表盘模块

一格 widget 就是仪表盘上的一块，用户在 widget 配置里挑哪一块
（`TollCatWidgetIntent`，选项直接来自 `DashboardModuleID`）。**不许在 widget 这边
另攒一份模块清单**：画什么由 `DashboardModuleFactory` 那一个 switch 说了算，
选单由 `DashboardModuleID.defaultOrder` 说了算。两道闸盯着：
`check_widget_module_list` 和 `DashboardLayoutTests.widgetDoesNotKeepItsOwnModuleList`
——Widget/ 里出现第二个模块名就红。

Widget 读 App Group 里的原始读数（`SharedStoreReader`），自己跑一遍
`DashboardContentsBuilder`。取景框只跟订阅口径（`SharedStoreContents.widgetFilter`），
永远是「本月 · 全部账号」。

**Android 的主屏小组件是「同一份 builder」这条的一个写下来的例外。** Glance 在广播里
渲染，那里加载 `libMeterCoreJNI.so` 的代价比这块小组件本身还大——所以由 App 每次重算之后
落一份只读文件（`WidgetSnapshot`），小组件只画它。两个代价是明知故犯的：数字最新只到
App 上一次运行（跨月单独处理了，预测值不会自己往前走），以及「构成按厂商卷」是第二份
简版实现。它**不做**的事是调 API 或链 `MeterProviders`——SPEC 第 09 节仍然成立。
取景框仍是同一个 `widgetFilter`：本月、全部账号、只跟订阅口径。

### MeterFeatures — 界面

按功能分子目录：`Dashboard/`、`Services/`、`Setup/`、`Settings/`。

- 状态用 `@Observable` model，一个屏幕一个，命名 `XxxModel`
- View 不直接 new 依赖，全部构造器注入
- **干活的另有其人。**`DashboardModel` 只是个门面，真正有语义的几件事各自成型：
  `RefreshPipeline`（取数、落盘、成败记账）、`DashboardStore`（SwiftData 读写）、
  `RefreshCoordinator`（并发闸）、`LedgerSync`（账本编排：什么时候折、折完那份还算不算数）、
  `PresentationRebuilder`（什么时候把重算好的内容换上屏）。有并发语义的那两件
  （后两个）必须能单独测——它们从模型里抽出来之前是五个互相咬合的字段，零测试
- 仪表模块是数据驱动的列表：`DashboardModule` 枚举/协议 + 各自的 view，加模块不改容器（SPEC 第 05 节）
- 每个屏幕都要有可工作的 `#Preview`，用 mock 数据

## 事实源注册表

跨端重复的教训（2026-08 普查）：同一事实手抄两三份，一定漂。每类事实只有一个权威，
其余全是生成物（带 `GENERATED` 头，提交进仓库，和 xcodeproj 同一哲学）。
`scripts/check-source-invariants.py` 里有 regenerate-diff 闸：改了权威不跑生成器、或手改生成物，提交闸红。

| 事实 | 权威 | 生成物 | 命令 |
|---|---|---|---|
| 钱的折算 / 取数 | `MeterCore` / `MeterProviders`（Swift 源码） | Android / Windows 侧同一份源码经 symlink 双编 | `scripts/android-run.sh`；Windows 见 `Windows/native/build.ps1` |
| provider 视觉身份（Simple Icons path、light/dark 品牌色、fill、evenOdd、letterReason） | `shared/providers.json` | `ProviderGlyphArtwork.swift/.kt/.cs`、`ProviderPalette.swift`、`ProviderColors.kt`、`ProviderPalette.cs`、`site/src/providers.ts` | `scripts/generate-shared.py` |
| provider 接入分层（完全支持 / 理论支持 / 读数信箱 / 不接入） | `ProviderCatalog.swift` 的 `accessStatus` 与 `supportsInboxIngest` | `site/src/supportTiers.ts` | 同上 |
| 落地页服务详情（计费种类、凭据字段、套餐、官方 URL） | `ProviderCatalog.swift` + `Catalog/catalog.json` | `site/src/catalogEntries.ts` | 同上 |
| 猫的几何（图层 path、锚点、剪影分段控制点） | `shared/cat.json`（原稿 `docs/assets/tollcat.svg`） | `CatArtwork.swift/.kt/.cs` 全文件 | 同上 |
| 猫的动效常数 | 三端手写（平台渲染归属） | —（`check_cat_motion_constants` 闸强制数值一致） | — |
| 用户可见文案 | 各模块 `Localizable.xcstrings`（zh 源串 + en/ja） | Android `values-en/`、`values-ja/`；Windows `en-US`/`ja-JP` resw。独有句分别在 `strings-android-only.json` / `strings-windows-only.json` | `scripts/generate-android-strings.py`；`scripts/generate-windows-strings.py` |
| 桥出口的文案 | `shared/jni-copy.json` 选键，译文取自 xcstrings | `Android/native/Sources/MeterBridge/JNICopy.swift`（三语表编进动态库） | `scripts/generate-shared.py` |
| API 契约（字段上限、类别枚举、匿名页面名单） | `shared/api-contract.json` | `worker/src/contract.ts`、`TipFieldLimits.swift`、`FeedbackFieldLimits.swift`、`UsageAnalyticsScreen.swift`、`UsageFieldLimits.swift`、`UsageScreens.kt`、`UsageScreens.cs`、site 表单（补丁式） | 同上 |
| 接入目录（教程、套餐、汇率） | `Packages/.../MeterPersistence/Catalog/catalog.json`（中文规范字段；`en` / `ja` 为可选 overlay，展示时解析，缺列回落中文） | worker、Android 桥、Windows 壳资源均为 symlink（`check_catalog_sync` 闸） | — |
| 品牌图标（App 图标、favicon、Android launcher、BrandMark.astro） | `scripts/render-app-icon.py`（猫几何取自 `shared/cat.json`） | App/site/docs/Android 全部槽位 | `python3 scripts/render-app-icon.py` |
| 系统权限用途说明 | `project.yml` 的 `INFOPLIST_KEY_NS*UsageDescription`（中文）+ `App/Resources/InfoPlist.xcstrings`（en / ja） | 系统弹窗 | — |
| 落地页 SNS 图 | `.github/readme/hero-{zh,en,ja}.png` | `site/public/og-{locale}.png`（Astro 启动时拷贝） | 换 README 横幅后 `pnpm build` |
| UI 冒烟锚点（iOS accessibilityIdentifier / Android testTag） | `shared/ui-test-ids.json` | `MeterDesign/UITestID.swift`、`Android/.../ui/UITestId.kt`；`maestro/*.yaml` 只能引用表里的 id，表里的 id 必须有流程在用 | `scripts/generate-shared.py` |
| 仪表盘模块的尺寸档（宽 / 高断点、每档说明） | `shared/module-size.json` | `MeterDesign/ModuleSize.swift`（Android 接这几根轴时从同一份生成 Kotlin，别另抄） | `scripts/generate-shared.py` |
| 厂商身份（显示名、色键、类别、市占档、刷新是否要钱） | `ProviderCatalog.swift`（和接入分层同一处） | `MeterCore/ProviderIdentity.swift`；生成器顺带核对它和 `shared/providers.json` 的名字一致 | 同上 |
| 用户可见版本号 X.Y.Z | `shared/version.json` | `project-common.yml` MARKETING_VERSION（两份 spec 共用）、`build.gradle.kts` versionName、`TollCat.csproj`、`Package.appxmanifest`、`TollCat.appinstaller`、winget 清单（补丁式）；build 号由 CI run number 填 | `scripts/generate-shared.py` |
| 更新说明（App 抽屉、落地页 `/changelog`、商店文案） | `shared/changelog.json`（中文是规范字段，`en` / `ja` 是就地 overlay，和 `catalog.json` 同一写法） | `site/src/changelog.ts`、`WhatsNewCatalog.swift/.kt/.cs`、`docs/release/notes.md`、`docs/release/appcast-notes/*.html`（Sparkle 的 `<description>`）、`docs/release/store-notes/*.txt`（ASC 的「此版本新增」）、`Android/app/distribution/whatsnew/*` | `scripts/generate-shared.py` |
| 桥 JSON schema | 三端手写（`JNISchema.version` ↔ Kotlin / C# `EXPECTED_JNI_SCHEMA`） | —（`check_jni_schema` 闸强制数字一致） | — |
| 换机迁移信封（magic、头布局、PBKDF2 工作因子与上下限、密钥 / salt / nonce / tag 长度、转移码位数、文件有效期） | `MeterPersistence/TransferFileFormat.swift` + `TransferKeyDeriver.swift` + `MeterCore/TransferCode.swift` | `DeviceTransfer.kt` 里再手写一份（各端走各自的系统密码学实现）——`check_transfer_envelope` 闸强制数字一致；对不上要到用户换机那天才会知道 | — |
| 哪条读数算数（对某个月、对「此刻」） | 折叠：`LedgerFolder` + `AccountLatest.reduce` | —（`check_ledger_boundary` 闸不让展示路径再判第二遍；`LedgerSelfCheck` 证明折叠和全量重算逐项相同） | — |

### 加一家要动哪几处

这一份**不是生成物**，也不该是：`tierReason` 那种逐家写的话、控制台 URL 那种
安全红线（SPEC 第 07 节），都得人写。能自动的是「漏了哪一处当场说出来」——
下面标 ✅ 的由 `check_provider_wiring` 守着。

| 改哪 | 写什么 | 漏了会怎样 |
|---|---|---|
| `MeterCore/ProviderID.swift` | rawValue | 编译不过（唯一一处编译期能挡的） |
| `MeterProviders/ProviderCatalog.swift` | descriptor（显示名、类别、档位、URL、关键词……） | 搜不到、加不进来 |
| `MeterProviders/ProviderAssembly.swift` | `liveRESTProviderIDs` **和** switch 分支 ✅ | 只写一半：那家永远不取数，界面上只是「暂无读数」，不报错 |
| `MeterProviders/OutboundHosts.swift` | 每个 URL 的域名 ✅ | 出站白名单挡下来，错得像「这家接口坏了」 |
| `Catalog/catalog.json` | 接入说明（三语） ✅ | 向导第二步一片空白 |
| `shared/providers.json` | 品牌色 + 图标 path | 生成器红（`check_declined_providers` / 生成物 diff 闸） |
| `MeterProviders/Fixtures/<id>.json` | 设计稿 / 演示读数 | 只影响演示种子和截图，**不是每家都要** |


刻意**不**统一的：M3 bento 与 iOS inset-grouped 的间距/圆角/字体（平台各自设计）、
site 的版式与营销文案、SQLite/Keystore 等平台适配器、图表的渲染层（数据决策已共享）。

## 工程约定

- Swift 6，strict concurrency 全开。跨 actor 的类型该标 `Sendable` 就标，不要用 `@unchecked` 糊过去
- iOS 26.0 / macOS 26.0 最低版本。iPhone 用原生 `TabView` / `NavigationStack`；横屏 iPad 和 Mac 的服务 / 设置用 `NavigationSplitView`，不要手搓分栏。Mac 设置走主窗口侧栏第三项，⌘, 切过去，不要 `Settings` 场景。sheet 在 iPad / Mac 走系统 form / page，不要把 iPhone 的 detent 抽屉拉到宽壳上。不要 Mac Catalyst，也不要让 iOS 包在 Apple Silicon 上冒充 Mac 版
- 测试用 Swift Testing（`import Testing`，`@Test`），不用 XCTest
- **Tests 目录增删文件必须重跑 xcodegen 并把两份 `.xcodeproj` 一起提交。** `.pbxproj` 显式列文件，不是同步目录——不重跑的话新测试根本不会被编译，而且 `xcodebuild` 照样打印绿。这条对 `Sources/` 不成立（SPM 按目录发现），只对 `Tests/` 成立
- 不引入任何第三方依赖。这个 App 不需要。例外只写在这里，别处不再有：
  - **Sparkle**：Mac 直发版的自动更新框架，只链进 `TollCatMac`，只在 `Mac/MacUpdater.swift` 出现（沙盒里替换正在运行的 .app 只能靠它的 XPC 安装服务，自己写等于重做一个安装器）。
  - **AndroidX Glance** 和 **Play Billing**：Android 壳上的 WidgetKit 与 StoreKit。主屏小组件和内购离了它们写不出来，和 Sparkle 同一个道理。这不等于那一端可以随便拉通用第三方库。

  这条规矩真正针对的是「App 自己能做的事却去拉一个库」。有一样我们不会拉：密码学库。
  `MeterProviders` 要给厂商请求签名（SigV4、TC3、EdgeGrid…），而它**必须能为 Android 交叉编译**，
  那边没有 `CryptoKit`——所以摘要写在 `MeterCore/MeterDigest.swift` + `MeterHMAC.swift`，
  纯 Swift，用公开测试向量钉住。
- 文案一律中文；代码标识符一律英文
- 注释只写"为什么"，不写"是什么"

## 命令

```bash
# 在 Xcode 里同时开两端（分别打开两个 .xcodeproj 会互相抢本地包）
open TollCat.xcworkspace

# 生成工程（改了任一 spec、或者 Tests/ 增删了文件之后。两份都是提交进仓库的生成物）
# XcodeGen 2.46.0。`brew install xcodegen`，或者下 release 里那份 zip 解到 ~/.local。
xcodegen generate
xcodegen generate --spec project-mac.yml

# 构建
xcodebuild -project TollCat.xcodeproj -scheme TollCat \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

xcodebuild -project TollCatMac.xcodeproj -scheme TollCatMac \
  -destination 'platform=macOS' build

# 跑测试
xcodebuild -project TollCat.xcodeproj -scheme TollCat \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test

# Android 验收屏（同一份 MeterCore → JNI → Compose）
bash scripts/android-run.sh

# 该不该发版、发哪些端（节奏见 docs/RELEASE.md）
bash scripts/release-status.sh

# 跨端跟进（按 Apple 目录点头；过期不挡提交，见 docs/FOLLOW-UP.md）
python3 scripts/check-follow-up.py due --platform android
python3 scripts/check-follow-up.py show dashboard --platform android
# python3 scripts/check-follow-up.py stamp dashboard android --decision reviewed --note "…"

# UI 冒烟（Maestro，按 id 不按文字，两端同一份 maestro/*.yaml；CI 只跑 iOS 模拟器）
bash scripts/maestro-smoke.sh            # iOS
bash scripts/maestro-smoke.sh android    # Android，要先有 android-run.sh 编出的 jniLibs

# shared/*.json 改动之后：铺生成物（--check 是提交闸用的比对模式）
python3 scripts/generate-shared.py

# xcstrings 改动之后：铺 Android 的 en/ja
python3 scripts/generate-android-strings.py

# 铺 Windows 的 en-US / ja-JP resw
python3 scripts/generate-windows-strings.py

# 品牌图标改动之后：铺 App / site / docs / Android launcher 全部槽位
python3 scripts/render-app-icon.py

# 权限 / 隐私清单 / App 图标 / App Group：送审能在源码里卡住的那几条
python3 scripts/check-app-store-invariants.py

# 本机看 api.tollcat.app 上要处理的事（wrangler login，Ink + bun）
bash scripts/ops
```

MeterKit 声明 `platforms: [.iOS(.v26), .macOS(.v26)]`。包本身应能在 Mac 宿主
上 `swift build --package-path Packages/MeterKit`。测试仍走上面的 `xcodebuild test`，
由 Xcode 的 `MeterKitTests` target 在 iOS 模拟器上跑（栅格化、相册、键盘附件
那些还是 UIKit）。Mac 壳用 `TollCatMac` scheme 编过即验收。

多个 agent 并行时各自加 `-derivedDataPath .derived/dd-<模块名>`，否则抢同一个
DerivedData 会互相报错。`.derived/` 已在 `.gitignore` 里。每份 DerivedData 约 1G，
任务结束后 `rm -rf` 掉自己那份，别攒在磁盘上。
