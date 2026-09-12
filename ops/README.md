# TollCat ops

本机看 `api.tollcat.app` 上要处理的事。Ink + bun 的 TUI。

不打 HTTP 到 `api.tollcat.app`。凭据是本机 `wrangler login`，数据走 `wrangler d1 execute --remote` 和 `wrangler deployments list`。Worker 本身没有管理接口，这一层就是给操作者用的。

## 看什么

| 页 | 来源 | 待办含义 |
|---|---|---|
| 待办 | 下面几项的并集 | 还没标已读的反馈 / 打赏，加上未打上的迁移 |
| 反馈 | `feedback` | App 和落地页表单 |
| 打赏 | `tips` | 含留言和没有留言的 |
| 信箱 | `inboxes` / `readings` | 只看数量和最近读数，不碰钥匙 |
| 用量 | `usage_visits` / `usage_screens` | 匿名打开次数。表不在会指到迁移 |
| 健康 | 本地 `worker/migrations` vs 远端 `d1_migrations`，加上两次部署时间 | 代码和库对不上时黄字 |

已读存在 `~/.tollcat/ops-ack.json`，不写远端 D1。健康项不能标已读，修好才会消失。

## 跑

需要 bun 和已经 `wrangler login` 的本机。第一次：

```bash
curl -fsSL https://bun.sh/install | bash
cd worker && npm install
cd ../ops && bun install
```

之后：

```bash
bash scripts/ops
bash scripts/ops --json
bash scripts/ops --once
bash scripts/ops --section feedback
```

仓库根也可以 `bun ops/src/cli.tsx`。

## 键盘

`1-6` / Tab 切页，`j k` 移动，`space` 标已读，`y` 复制联系方式或 id，`r` 刷新，`?` 帮助，`q` 退出。

## 测

```bash
cd ops && bun test
```

单测不碰 Cloudflare。假 wrangler 的夹具在 `tests/snapshot.test.ts`。
