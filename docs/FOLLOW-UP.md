# 跨端跟进

盖戳记的是「这个 Apple 目录自上次点头之后改过，某跟随端的人看过 diff」。不发明能力，不维护跨语言依赖表。Apple 先合。没点头不等于 iOS 不能发，只表示那一端还不能声称跟进完成。

设计背景：[docs/audit/2026-09-09-cross-platform-follow-up.md](audit/2026-09-09-cross-platform-follow-up.md)。

## 三条命令

```bash
python3 scripts/check-follow-up.py due --platform android
python3 scripts/check-follow-up.py show dashboard --platform android
python3 scripts/check-follow-up.py stamp dashboard android --decision reviewed --note "…"
```

| 决策 | 意思 |
|---|---|
| `reviewed` | 看过；该改的改了，或不需要改 |
| `n/a` | 这端没有这一摊 |
| `deferred` | 这端以后做；仍算未点头 |

`--note` 必填。`n/a` 不跟哈希，目录再改也不过期。

地图在 [`scripts/follow-up.json`](../scripts/follow-up.json)。预提交只跑 `check`（路径 404、未知 id），**过期不红**。

## 盯哪些目录

| id | Apple 目录 |
|---|---|
| `dashboard` | `MeterFeatures/Dashboard/` |
| `modules` | `MeterModules/` |
| `services` | `MeterFeatures/Services/` |
| `setup` | `MeterFeatures/Setup/` |
| `settings` | `MeterFeatures/Settings/` |
| `developer` | `MeterFeatures/Developer/` |
| `share` | `MeterFeatures/Share/` |
| `shell` | `MeterFeatures/` 根上的 `.swift` |
| `bridge` | `Android/native/Sources/MeterBridge/*.swift` |

新文件丢进其中一个目录，自动进该目录的哈希。新目录：表和 `watches` 各加一行。

排除：`MeterCore` / `MeterProviders` / `MeterFormat`（共核）、`GENERATED` 头、文件名 `*Pad*` / `*Mac*` / `*MenuBar*` / `*Widget*`。跟随端路径写在每条 watch 的 `hints` 里，给人看，闸不核。

哈希抹注释、丢掉空行，保留字符串。CLI 在 `CLI/` 落地前全部预置 `n/a`。

## 发版

`bash scripts/release-status.sh` 在班车启发式之外多打一行「未点头」。那一行不改变原来的 `due`（落后两班车 / 核心改过）。跟进完成和能不能发是两句话。
