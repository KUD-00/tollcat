# toll-api Worker

这个项目**唯一**的服务端。一个 Worker 承担全部 endpoint，不要按功能再拆部署。

它不接触任何 provider 凭据，也不代理任何 provider API。

## 路由

权威路由表在 `src/index.ts` 顶部的注释里，不在这里另抄一份。
投递 key 的「轮换」是签一把新的、改完脚本再吊销旧的——签发**不**吊销任何旧 key。

`POST /v1/feedback` 给 `https://tollcat.app` 和 `https://www.tollcat.app` 开了 CORS，落地页的联系表单和 App 打同一条。tip / inbox / readings 不要加。App 没有 Origin，不受影响。

## 读数信箱是干什么的

官方压根没有账单接口的那几家（Render / Expo / Clerk），用户在**自己的机器上**取数
——脚本、cron、browser-use，随便——然后把数字投递到这里，App 打开时取回。

所以这个 Worker 里：

- **没有任何 provider 的 token。** 用户的 Render key 在他自己机器上，我们见不到。
- **两把 key 只存 SHA-256。** 库被 dump 也拿不到投递权限。
- **投递 key 只能写，读 key 只能读。** 投递 key 会躺在 CI 和脚本里，它一定会泄露，
  所以它读不出任何东西，也删不掉任何东西。
- **每个（信箱, 服务）只留最新一条。** 重复投递是幂等覆盖，这里不是金额历史库——
  历史留在设备上。

最坏情况被拖库，泄露的是一堆和人对不上的匿名金额，不是能替谁花钱的东西。

## 投递长什么样

```bash
curl -X POST https://api.tollcat.app/v1/readings \
  -H "Authorization: Bearer $TOLL_INGEST_KEY" \
  -H "content-type: application/json" \
  -d '{"provider":"render","periodStart":"2026-08-01","currentSpendUSD":"12.34"}'
```

`currentSpendUSD` 是**本月至今累计**，不是「今天花了多少」。这个含义不许改；
以后要加日粒度就在 `/v1` 之上另开字段和另开路径。

金额是十进制字符串不是 JSON number——分位不许过 Double。

## 建 D1 并部署

需要本机已登录的 Cloudflare 账号。不要把 API token 写进仓库。

```bash
cd worker
npm install
npm run typecheck
npx wrangler login
```

D1 已经建好了（`database_id` 在 `wrangler.toml` 里）。第一次部署到新库才需要：

```bash
npx wrangler d1 create tollcat
```

```bash
npx wrangler d1 migrations apply tollcat --remote
npx wrangler deploy
```

`wrangler.toml` 里已经把 `api.tollcat.app` 配成 custom domain，前提是这个 zone
在同一个 Cloudflare 账号下——Cloudflare 会自己建 DNS 记录和证书，不用手工加 CNAME。
顶级域 `tollcat.app` 留给落地页和 App Store 支持链接，别挂到这个 Worker 上。

App 里的源已经指向 `https://api.tollcat.app`。**这些 origin 必须完全一致**：

- `Packages/MeterKit/Sources/MeterTips/TipWorkerEndpoint.swift` 的 `origin`
- `Packages/MeterKit/Sources/MeterInbox/InboxEndpoint.swift` 的 `origin`
- `Packages/MeterKit/Sources/MeterPersistence/CatalogEndpoint.swift` 的 `origin`
- `Packages/MeterKit/Sources/MeterFeedback/FeedbackEndpoint.swift` 的 `origin`
- `Packages/MeterKit/Sources/MeterUsage/UsageEndpoint.swift` 的 `origin`

`GET /v1/catalog` 读的是 `worker/src/catalog.json`，它是 App 打包目录的符号链接。
改 `Packages/MeterKit/Sources/MeterPersistence/Catalog/catalog.json` 再部署 Worker，
已装机的 App 下次启动就会拉到新说明和新汇率。

还要同步 `MeterProviders/OutboundHosts.swift` 里那条 host，否则关于页对不上、
CI 的 `check-outbound-hosts.sh` 会红。三处相等由 `InboxEndpointTests` 和
`TipModuleIsolationTests` 锁死。

不要从 catalog 或远程配置读取这个 URL。

## 匿名页面计数

`POST /v1/usage` 只加总，不留事件。表是 `usage_visits`（每天每平台打开次数）和
`usage_screens`（每天每平台每页进入次数）。没有用户 ID。

看数（本机已 `wrangler login`）：

```bash
bash scripts/ops
bash scripts/ops --once
```

`ops/` 是 Ink + bun 的本机 TUI，走 wrangler 读远端 D1 和部署记录，不打 `api.tollcat.app` 的 HTTP。匿名页面计数的一次性 SQL 仍在 `scripts/usage-stats.sh`。

新环境第一次要把迁移打到远端，再部署：

```bash
npx wrangler d1 migrations apply tollcat --remote
npx wrangler deploy
```

## 类型从 wrangler.toml 生成

`npm run typecheck` 会先跑 `wrangler types`，把 `Env`（含 DB binding）和运行时类型
生成到 `worker-configuration.d.ts`（已 gitignore）。binding 名写错在编译期就会红，
不要再手写 `Env` interface。

本任务不代替你执行 `wrangler deploy`。
