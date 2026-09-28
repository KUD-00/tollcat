# tollcat CLI

Linux 的原生形态是终端。`tollcat` 是一个纯 Swift 可执行文件，直接链接 `MeterBridge`：算账、取数、目录和三语文案都还是仓库里那份 Swift，这里只做参数解析、渲染、凭据和账本。

macOS 上同一份二进制也是获客入口——`brew install tollcat` 之后先看到数字，再被引去装带小组件的 App。

状态：源码已按 `docs/cli/SPEC.md` 铺齐。本机 `swift test --package-path CLI` 应绿。对真实 provider 出数、Linux 静态二进制、Homebrew tap 的 sha256，要在发版流水线里填。

## 命令

```
tollcat                 本月合计
tollcat --oneline       一行，给状态栏
tollcat --json          机器可读（schema 即 ProductDashboard）
tollcat add <服务>      逐字段写入凭据
tollcat remove <服务>
tollcat refresh         强制拉新
tollcat providers       支持的服务
tollcat --version
```

旗标：`--no-color`（也认 `NO_COLOR`）、`--locale <tag>`、`--max-age <分钟>`（默认 30，`0` 表示总是拉新）。

退出码：`0` 正常，`1` 拉数有失败，`2` 用法错误。`--json` 时诊断走 stderr，stdout 纯 JSON。

## 本机跑

```bash
swift test --package-path CLI
swift run --package-path CLI tollcat providers
swift run --package-path CLI tollcat add openai
```

## 凭据

- macOS：钥匙串，服务名 `app.tollcat.cli`，不进 iCloud。
- Linux：Secret Service（运行时 `dlopen libsecret-1.so.0`，二进制仍可全静态）。没有 D-Bus 的机器请用环境变量。
- 任何平台只读环境变量：`TOLLCAT_<PROVIDER>_<FIELD>`，例如 `TOLLCAT_OPENAI_APIKEY`、`TOLLCAT_AWS_ACCESSKEYID`。不落盘，也没有写明文的旗标。

账本：`$XDG_DATA_HOME/tollcat/ledger.json`（macOS 是 `~/Library/Application Support/tollcat/ledger.json`），schema 与 Windows 版同一份（对齐 Android schema v4）。测试夹具在 `shared/fixtures/ledger-v4.json`。

覆盖数据目录：`TOLLCAT_DATA_HOME`。显示币种：`TOLLCAT_CURRENCY`（默认 USD）。

CLI 不发遥测，出站只有各家账单 API。

## 状态栏

waybar：

```json
{
  "custom/tollcat": {
    "exec": "tollcat --oneline --no-color",
    "interval": 600,
    "tooltip": false
  }
}
```

polybar：

```ini
[module/tollcat]
type = custom/script
exec = tollcat --oneline --no-color
interval = 600
```

tmux 状态栏（`.tmux.conf`）：

```
set -g status-right "#(tollcat --oneline --no-color) | %H:%M"
```

## Linux 静态二进制

官方 [Swift Static Linux SDK](https://www.swift.org/documentation/articles/static-linux-getting-started.html)。脚本：`CLI/packaging/build-linux.sh`。验收：一台没有 Swift 的盒子，scp 过去，`tollcat add` + `tollcat` 出数。
