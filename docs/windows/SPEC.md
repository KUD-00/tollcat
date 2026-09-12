# Windows 版实装 SPEC

状态:**源码已铺齐，P0 待 Windows 11 真机验证**。桥的改造（MeterBridge）已落地；WinUI 3 壳、C ABI、生成器、闸都在仓库里。Swift-on-Windows 编 dll 和真实凭据拉数必须在 Windows 11 上做，本机 Mac 编不过。
执行前先读:`AGENTS.md`、`ARCHITECTURE.md`、`BRAND.md`。本文的「决策记录」是定案,
「未定项」之外不要开新的技术选型辩论。

## 一句话

Windows 版是「薄壳 + 共核」公式的第三次实例化:C# + WinUI 3 画 Fluent 的皮,
算账、取数、格式化、目录链接的仍是 `Packages/MeterKit` 里那份 Swift(交叉编译成
dll,经 C ABI 调用),`shared/*.json` 的生成器加吐一个 C# target。Android 怎么
复用核心,Windows 就怎么复用——连桥的形状都一样,只是 JNI 换成 P/Invoke。

## 决策记录(定案,不再议)

- **UI 栈:WinUI 3 + Windows App SDK(稳定通道)+ C# / .NET 当前 LTS。**
  不用 WPF(新项目没理由);不用 Compose Multiplatform(会把 Android 端的
  material3 锁到 JetBrains 跟随版,我们在用 1.5.0-alpha26 的 Expressive API,
  跟随版追不上;桌面上 Material 观感也违和);不用 Electron / WebView2(和
  「本机、轻、只读」的品牌立场相反)。
- **设计语言:Fluent,不搬 Bento、不搬 M3E、不搬 SwiftUI 版式。** 三端各说各的
  话是既有原则(Apple 说 SwiftUI,Android 说 Bento + M3E)。共用的是版式之下的
  东西:模块口径、图表语义、三语文案、猫。
- **核心复用走 Android 已验证的公式**:同一份 Swift 源码 symlink 进平台包交叉
  编译,平台皮只做序列化和进出参。Windows 上是 `.dll` + `@_cdecl` C ABI +
  C# `LibraryImport`(P/Invoke 源生成器)。
- **网络全部走 Swift 桥,C# 侧禁止直接发任何请求。** 这样 `check-outbound-hosts.sh`
  的出站闸自动覆盖 Windows 端,不用为 C# 再造一道闸。匿名计数 ping 也经桥发
  (平台字段 `windows`)。
- **分发:MSIX + 代码签名证书 + `.appinstaller` 自动更新,winget 收录。**
  不引 Sparkle 或任何第三方更新器——MSIX 自带。Microsoft Store 是二期再议。
- **第三方依赖默认为零。** 每引入一个都要在 `THIRD-PARTY-NOTICES.md` 记录并在
  PR 里写明为什么(对应主仓「Sparkle 是唯一例外」的纪律)。

## 非目标

- 不追求三端像素一致;不把 iOS/Mac 的界面「翻译」过来,信息架构对齐即可。
- 锁屏/主屏小组件没有 Windows 等价物,不做承诺;小组件面板(Widgets Board)
  是 P3 的可选项,单独评估。
- 不做 StoreKit 打赏的等价物(见未定项)。
- 一期只支持 Windows 11(Windows App SDK 稳定通道的基线)。

## 架构

### 目录

```
Windows/
  TollCat.sln
  app/                    # WinUI 3 壳(C# / XAML)
    strings-windows-only.json   # Windows 独有句子的三语(对照 Android 同名文件)
  native/                 # SwiftPM 包:Sources 里 symlink 复用主仓源码,编成 dll
    Package.swift
    Sources/
      MeterCore -> ../../../Packages/MeterKit/Sources/MeterCore
      MeterFormat -> ../../../Packages/MeterKit/Sources/MeterFormat
      MeterProviders -> ../../../Packages/MeterKit/Sources/MeterProviders
      MeterBridge -> (见下,桥改造后的平台中立层)
      MeterCoreCLR/       # @_cdecl 导出皮,Windows 独有
```

### 分层(依赖唯一合法方向)

```
shared/*.json + xcstrings ──scripts/generate-*──▶ Swift / Kotlin / TS / C# 生成物
MeterCore + MeterFormat + MeterProviders(同一份 Swift 源码)
        ▲
   MeterBridge(Product*:平台中立、JSON 进 JSON 出)
        ▲                                ▲
   JNI 皮(Android/native)          CDecl 皮(Windows/native/MeterCoreCLR)
        ▲                                ▲
   Compose 壳                        WinUI 3 壳
```

### 桥的改造(前置任务,先于 `Windows/` 目录动工)

`Android/native/Sources/MeterCoreJNI` 里的 `Product*`(Catalog / Fetch / Dashboard /
Format / HistoryChart / Rates / Seed / SnapshotCodec / Speech / Clock)加上
`JNICopy`,本身就是平台中立的 JSON 进出函数,只是被 `#if os(Android)` 包着、
和 JNI 皮(`JNIBridge` / `JNISupport` / `JNIAsync`)混在一个 target 里。改法:

1. `Product*` + `JNICopy` 挪进新的平台中立 target `MeterBridge`,去掉
   `#if os(Android)` 外壳(`FoundationNetworking` 的 import 条件保留)。
   `JNICopy.swift` 是生成物,同步改 `scripts/generate-shared.py` 的输出路径。
2. JNI 皮留在 `MeterCoreJNI`,依赖 `MeterBridge`。Kotlin 侧零改动。
3. Windows 侧新增 `MeterCoreCLR`:每个桥函数一个 `@_cdecl("tollcat_…")` 导出,
   UTF-8 `char*` 进出;返回字符串由 Swift 分配,配一个 `tollcat_free` 给 C# 释放。

**验收:`scripts/android-run.sh` 照常绿;Apple 侧(xcodebuild)不链接这些
target、构建无感知;`generate-shared.py --check` 绿。**

### C# 侧接法

- 一个 `MeterCoreNative` 静态类,`LibraryImport` + UTF-8 marshalling,和 Android
  的 `MeterCoreNative.kt` 同构:一个导出函数一个方法,JSON 字符串进出,
  反序列化只在这一层。
- dll 与 Swift runtime 可再发行库随 MSIX 打包。

## 复用清单

| 东西 | Windows 怎么拿 |
| --- | --- |
| 折算 / 取数 / 格式化 / 目录 | 同一份 Swift,经 `MeterBridge` |
| `shared/providers.json`(glyph、palette) | `generate-shared.py` 新增 `gen_csharp_*`,生成物提交进仓库、带 GENERATED 头 |
| `catalog.json`(教程、套餐、汇率) | symlink 进 `Windows/native` 资源,同 Android 的接法(受 `check_catalog_sync` 闸) |
| 用户可见文案(zh 源串 + en/ja) | 新增 `scripts/generate-windows-strings.py`:xcstrings → `.resw`,公式照抄 `generate-android-strings.py`;Windows 独有句子维护在 `strings-windows-only.json`,纳入 `check-copy-freshness.py` 扫描 |
| 猫(`shared/cat.json` 几何) | C# 渲染器,对照 Android 的 Kotlin 渲染器写 |
| worker(api.tollcat.app) | 不变;`shared/api-contract.json` 的 `usage.platforms` 加 `"windows"` |

## Windows 自己写的(平台底座)

| 事项 | 决定 |
| --- | --- |
| 存储 | C# 侧自持 DB(同 Android 的做法——`MeterPersistence` 不跨端)。快照序列化口径以 `ProductSnapshotCodec` 为准,建库前对照 Android 的 schema 决定 |
| 凭据 | Windows 凭据管理器(`CredWrite`/`CredRead`),绝不落明文文件。等价于 Keychain 的既有决定:不进任何云同步 |
| 后台刷新 | 一期只在应用驻留托盘时用进程内定时器;不注册系统服务、不建计划任务 |
| 托盘 | `Shell_NotifyIcon`;当月数字动态渲染进托盘位图(16/24px,亮暗两套)——菜单栏胶囊的对应物 |
| 通知 | toast,只用于余额/异常告警,口径同 iOS 通知的既有文案 |
| 开机自启动 | MSIX `StartupTask`,系统设置是唯一真相源、不落盘(同 Mac `LoginItem` 的决定) |
| 自动更新 | `.appinstaller`,清单挂 GitHub Releases(对照 Mac appcast 的做法) |

## 阶段与验收

### P0 走通性探测(约一周,随时可做,失败即撤)

整条路上唯一的高风险未知是 Swift-on-Windows 工具链,先验证它,再谈写皮。

- [ ] Windows 11 上装官方 Swift 工具链,完成上文「桥的改造」,把
      MeterCore + MeterFormat + MeterProviders + MeterBridge + MeterCoreCLR
      编成 x64 dll(arm64 顺带验证,记录结论)
- [ ] hello-world WinUI 3 应用 P/Invoke 调 `tollcat_catalog` 和 `tollcat_fetch`,
      用真实凭据拉通一家 provider,窗口里显示本月数
- [ ] 产出 `Windows/README.md`:工具链版本、踩坑、dll + runtime 体积、
      go / no-go 结论

### P1 核心链路(能用,不好看)

- [ ] 目录 → 添加服务 → 凭据写入凭据管理器 → 拉数 → 仪表盘首屏数字
- [ ] DB 落快照与历史;刷新失败的错误经桥透传展示
- [ ] **验收:新装机接入 ≥3 家真实 provider,看到与 iOS 端一致的本月数**

### P2 界面(Fluent 正经做)

- [ ] 界面清单:仪表盘(猫 + 数字 + 模块卡)、服务列表 / 详情 / 历史图表、
      添加向导、设置、关于
- [ ] `NavigationView` 分栏,信息架构对齐 Mac 宽壳 / iPad 分栏(不是像素对齐)
- [ ] 图表浮签与交互口径沿用 ChartCalloutLabel 那套统一决定
- [ ] 三语走 `.resw` 生成物;文案验收对 `BRAND.md`(标题可生硬、正文自然、
      答案先行、无黑话)
- [ ] **验收:三语全屏走查截图 + `docs/DESIGN-BAR.md` 适用条目逐条过**

### P3 平台服务

- [ ] 托盘数字 + 点开面板(对照 Mac 菜单栏面板:首屏数字、构成条、近几个月、
      刷新 / 打开主窗 / 退出;只读主 App 落的数,自己不打账单 API)
- [ ] toast 余额告警;开机自启动
- [ ] 可选(单独评估后再排):小组件面板(Adaptive Cards)

### P4 分发

- [ ] MSIX 打包 + 代码签名;`.appinstaller` 自动更新链路人工验证一次真实升级
- [ ] `release.yml` 加 `windows` job,对照 `mac` job 的纪律:preflight 版本
      一致性、构件 attest、`Forget signing material`
- [ ] winget manifest;`VERIFY.md` 加 Windows 首发人工检查单

## 闸与不变量(必须接上,不是可选)

- **只读原则**:C# 侧零网络请求(定案,见决策记录),出站域名闸自动覆盖。
- `generate-shared.py --check` 覆盖新增的 C# 生成物;生成物提交进仓库。
- `check-copy-freshness.py` 纳入 `strings-windows-only.json`;三语缺译要在
  提交闸红,不能等设备切语言才看见。
- `check-source-invariants.py` 视情况加 Windows 条目(如「C# 禁 HttpClient」
  可以做成按字面量扫描的闸)。

## 未定项(执行前找 owner 拍板)

- CommunityToolkit(WinUI)是否算进依赖白名单(倾向:允许,微软官方系)。
- 打赏:Windows 无 IAP——一期不做,还是放 tip 页链接。
- Microsoft Store 上架与否、时点。
- arm64 dll 的支持程度(P0 产出里给结论后再定)。
