# CLI 版实装 SPEC

状态:**待执行**。前置依赖一条:MeterBridge 的访问级别修复(`package` 要标到成员
函数上,见 Windows 实装 review 的结论)必须先落地——CLI 直接链接 MeterBridge,
桥编不过 CLI 就不存在。
执行前先读:`AGENTS.md`、`ARCHITECTURE.md`、`BRAND.md`、`docs/windows/SPEC.md`
(桥的形状在那边定义)。「决策记录」是定案,「未定项」之外不开新的选型辩论。

## 一句话

`tollcat` 是一个终端命令:开发者在任何一台机器上敲一下,看到各家云和 AI
这个月一共花了多少。Linux 的「原生」是终端,这就是 Linux 版;同一个二进制
在 macOS 上是获客入口(brew 一行装上,看到数字,再被引去装带小组件的 App)。
它不走 C ABI——纯 Swift 可执行文件,直接链接 `MeterBridge`,是四个端里
唯一一层皮都不用写的。

## 决策记录(定案,不再议)

- **纯 Swift 可执行文件,直接依赖 `MeterBridge`。** 不经 JNI、不经 CDecl,
  `Product*` 函数就是 CLI 的内部 API。JSON 进出的开销在 CLI 场景完全无感。
- **参数解析手写,不引 swift-argument-parser。** 命令面只有一个动词加几个旗标
  (见「命令面」),手写五十行换掉一个依赖,符合「第三方依赖默认为零」的纪律。
- **凭据:macOS 走 Keychain,Linux 走 Secret Service(libsecret,系统库,
  不算第三方);headless / 服务器环境走环境变量注入**
  (`TOLLCAT_<PROVIDER>_<FIELD>`,只读进程环境,不落盘)。绝不写明文凭据文件,
  也不提供写明文的旗标——这是品牌立场,不是实现细节。
- **账本:和 Windows 版同一个 JSON ledger schema(对齐 Android schema v4)**,
  路径遵 XDG(`$XDG_DATA_HOME/tollcat/ledger.json`,macOS 是
  `~/Library/Application Support/tollcat/`)。CLI 不发明第二种存储。
- **CLI 不发任何遥测,匿名计数也不发。** 终端工具的文化如此;App 端的匿名
  页面计数逻辑不搬过来。这也意味着 CLI 的出站域名 = provider API,一条不多。
- **文案三语走 JNICopy 机制。** CLI 自有句子作为新键进 `shared/jni-copy.json`,
  译文照旧取自 xcstrings、由 `generate-shared.py` 铺进桥;语言由
  `LANG` / `LC_ALL` 解析成 localeTag 传给 `Product*`。不为 CLI 造第二条
  i18n 通道(Linux 上 Foundation 的本地化资源加载不可依赖,三语表编进
  二进制是唯一稳的路)。
- **Linux 产物用 Swift Static Linux SDK 出全静态二进制**(x86_64 + aarch64),
  不依赖发行版 glibc/swift runtime。macOS 产物签名 + 公证(沿用 Mac 直发的
  证书与流程)。
- **不自带更新器。** 包管理器负责更新:Homebrew tap(macOS/Linux)、GitHub
  Releases 直下。`tollcat --version` 打印版本与 commit,不联网查新。

## 非目标

- 不做 TUI(全屏交互界面)。一屏打印完就退出;`watch tollcat` 是用户自己的事。
- 不做交互式凭据向导的完整目录教程——`tollcat add <provider>` 逐字段提示即可,
  教程链接打印 URL 指向落地页。
- 一期不画猫(`--cat` 彩蛋见未定项)。
- 不做 Windows 的 CLI 产物(等 Windows P0 验证工具链后顺带评估,零额外设计)。

## 命令面

```
tollcat                     # 仪表盘一屏:总数、预计、按 provider 一行一个
tollcat --oneline           # 一行:「$43.20 ↗ 预计 $61」,给 waybar/polybar/tmux/starship
tollcat --json              # 机器可读,schema 即 ProductDashboard 的输出
tollcat add <provider>      # 逐字段提示录凭据,存平台安全存储
tollcat remove <provider>
tollcat refresh             # 强制拉新(默认输出用账本缓存,超过 TTL 才拉)
tollcat providers           # 支持的服务列表(ProductCatalog)
tollcat --version
```

旗标:`--no-color`(同时尊重 `NO_COLOR` 环境变量)、`--locale <tag>`(覆盖
`LANG`)。默认输出人读、彩色、一屏以内;`--json` 保证 stdout 纯 JSON、
诊断走 stderr,退出码:0 正常、1 拉数有失败、2 用法错误。

## 架构

### 目录

```
CLI/
  Package.swift             # executable target `tollcat`
  Sources/
    MeterCore      -> ../../Packages/MeterKit/Sources/MeterCore      (symlink)
    MeterFormat    -> ../../Packages/MeterKit/Sources/MeterFormat    (symlink)
    MeterProviders -> ../../Packages/MeterKit/Sources/MeterProviders (symlink)
    MeterBridge    -> ../../Android/native/Sources/MeterBridge       (symlink)
    tollcat/                # CLI 独有:参数解析、渲染、凭据、账本、TTL
```

和 `Windows/native` 同一哲学:symlink 复用,不复制一行核心。`MeterBridge`
的家在 `Android/native/Sources/MeterBridge`(历史原因),CLI 与 Windows
一样指过去;若日后把它迁到中立路径,三处 symlink 一起改。

### CLI 独有层(全部要写的东西)

| 模块 | 内容 |
| --- | --- |
| 参数解析 | 手写:一个动词 + 旗标表,未知输入打 usage 退出码 2 |
| 渲染 | 终端表格与 oneline;宽度探测(`COLUMNS`),不依赖 curses;颜色只用 16 色 ANSI,`NO_COLOR`/管道时自动关 |
| 凭据 | 协议 + 三实现:Keychain(macOS)、Secret Service(Linux)、环境变量(只读 fallback,任何平台可用) |
| 账本 | 读写 XDG 路径的 ledger.json,schema 与 Windows `JsonLedgerStore` 完全一致(同一份测试夹具) |
| TTL | 默认输出用账本内不超过 N 分钟的快照;过期或 `refresh` 才打 provider API(N 的默认值一期定 30,可 `--max-age` 覆盖) |

## 阶段与验收

### P0 骨架(macOS,量级:天)

- [ ] `CLI/` 包建立,链接 MeterBridge,`tollcat providers` 打印目录三语可切
- [ ] `tollcat add` + Keychain 存取 + `tollcat` 拉一家真实 provider 显示本月数
- [ ] **验收:brew 未发布前,`swift run tollcat` 在本机对 ≥2 家真实 provider
      出数,与 iOS 端一致**

### P1 Linux(量级:天到周,风险最低的移植)

- [ ] Static Linux SDK 出 x86_64 + aarch64 静态二进制,Ubuntu 与 Alpine 容器里跑通
- [ ] Secret Service 凭据实现;无 D-Bus 环境下环境变量注入路径验收
- [ ] **验收:一台没有 Swift 的 Linux 盒子,scp 二进制过去,`tollcat add` +
      `tollcat` 出数**

### P2 打磨

- [ ] `--oneline` / `--json` / 颜色与管道行为 / 退出码按「命令面」逐条验收
- [ ] 三语:`LANG=ja_JP.UTF-8 tollcat` 走查;CLI 新键进 jni-copy.json,
      `check-copy-freshness` 覆盖
- [ ] 账本 schema 与 Windows 侧共享测试夹具,两边各自的测试都吃同一份 JSON
- [ ] 文档:README 里 waybar / polybar / tmux 状态栏接法各给一段抄得走的配置

### P3 分发

- [ ] `release.yml` 加 `cli` job:mac 二进制签名公证、Linux 静态二进制、
      产物 attest,挂同一个 tag 的 GitHub Release
- [ ] Homebrew tap(`brew install tollcat`);`VERIFY.md` 加 CLI 首发检查单
- [ ] 落地页加终端一节(站点文案三语,过 copy-freshness)

## 闸与不变量

- **出站域名**:CLI 不新增任何出站(不发遥测,worker 都不碰),
  `check-outbound-hosts.sh` 自动覆盖;`ProductWorker` 不链进 CLI target。
- **凭据不落盘不出端**:环境变量路径只读不写;`--json` 输出里永远没有凭据
  字段(ProductDashboard 的输出本来就没有,加一条测试钉死)。
- CLI 新增用户可见句子必须走 jni-copy 键,`check-i18n-coverage` /
  `check-copy-freshness` 照常拦。
- `check-source-invariants.py` 加一条:`CLI/Sources/tollcat` 禁 import
  `FoundationNetworking`(网络只许存在于 MeterProviders 传输层)。

## 未定项(执行前找 owner 拍板)

- TTL 默认 30 分钟是否合适;`watch`/状态栏高频调用下是否要文件锁。
- `tollcat --cat`:cat.json 几何降采样成 ASCII/半角块的彩蛋,做不做、何时做。
- Linux 发行渠道要不要加 AUR / nixpkgs(社区包,维护成本在别人手里)。
- Windows 的 CLI 产物(等 Windows P0 结论)。
