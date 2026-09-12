# Windows 版

状态：源码已按 `docs/windows/SPEC.md` 铺齐。本机是 Mac，**还没有在 Windows 11 上跑通 P0**（Swift-on-Windows 编 dll、WinUI P/Invoke 拉一家真实账单）。下面的工具链版本和体积是目标，不是实测。

## 一句话

C# + WinUI 3 画 Fluent 的皮。算账、取数、格式化、目录仍是 `Packages/MeterKit` 里那份 Swift，交叉编译成 `MeterCoreCLR.dll`，经 `LibraryImport` 调 C ABI。Kotlin 怎么复用核心，C# 就怎么复用。

## 目录

```
Windows/
  TollCat.sln
  app/                 WinUI 3 壳
  native/              SwiftPM：symlink 复用主仓源码 + MeterCoreCLR 导出皮
  tests/               不碰 WinUI 的纯 .NET 测试（账本 / path / 猫动效）
```

桥在 `Android/native/Sources/MeterBridge`（平台中立）。Windows 的 `native/Sources/MeterBridge` 是指向它的 symlink。

## 工具链（目标）

| 东西 | 版本 |
| --- | --- |
| Windows | 11 22H2+（Windows App SDK 稳定通道基线） |
| .NET | 10 LTS |
| Windows App SDK | 2.4.0（2026-08-13 稳定通道） |
| Swift | 官方 Windows 工具链，与 Android 交叉编译同一份 6.2 |
| Visual Studio | 2026，.NET 桌面 + Windows App SDK 工作负载 |
| 架构 | x64 必做；arm64 顺带编，P0 记录结论后再定是否首发 |

第三方代码依赖默认为零。WinUI / Windows App SDK 是平台，不是第三方库。CommunityToolkit 没用。SQLite 没用——账本是对照 Android schema v4 的 JSON 文件，避免再引一个 native 包。凭据走 `CredWrite` / `CredRead`。

## 在 Windows 上编

先决条件：这棵树靠 git symlink 复用主仓源码，Windows 上默认 `core.symlinks=false`，
检出来的会是"内容为路径"的普通文件，Swift 包会空、`catalog.json` 会是一行文字。
克隆前先 `git config --global core.symlinks true`（需要开发者模式或管理员），
已克隆的执行 `git config core.symlinks true && git checkout -- .`。

```powershell
# 1. 桥 dll + Swift runtime
pwsh Windows/native/build.ps1 -Arch x64 -Config release

# 2. 壳
dotnet test Windows/tests/TollCat.Tests.csproj
dotnet build Windows/app/TollCat.csproj -c Release -p:Platform=x64
```

把 `Windows/native/dist/x64/*.dll` 拷进 App 输出目录（csproj 在文件存在时会自动 Copy）。`Assets/swiftpm/` 里是 `catalog.json` 和 fixtures 的 symlink，运行时 `NativeBootstrap` 把这个目录注入 `tollcat_set_resource_root`。

## P0 还没做的（必须在 Windows 11 真机上）

- [ ] 官方 Swift 工具链编出 x64 dll；arm64 顺带编一次，记下体积和缺的 runtime
- [ ] hello-world：P/Invoke `tollcat_catalog` + `tollcat_fetch`，用真实凭据拉通一家，窗口里显示本月数
- [ ] 把实测的工具链版本、踩坑、dll + runtime 体积写回本文件，给出 go / no-go

失败即撤：Swift-on-Windows 编不过或 `FoundationNetworking` 在 Windows 上不能发 HTTPS，这条路就停。

## 分发（P4）

MSIX + `.appinstaller`（`Windows/app/Packaging/TollCat.appinstaller`），清单挂 GitHub Releases，对照 Mac appcast。winget 清单在 `Windows/winget/`。Microsoft Store 二期再议。

## 闸

C# 源码禁止 `HttpClient` / `System.Net.Http` / `Windows.Web.Http`（`check-source-invariants.py`）。出站全部走 Swift 桥，`check-outbound-hosts.sh` 扫 `Windows/`。文案走 `generate-windows-strings.py` + `strings-windows-only.json`。
