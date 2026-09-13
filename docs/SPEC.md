# TollCat — iOS 账单聚合 App 设计规格

> 来源：设计规格 v2（2026-08-15）。本文件是产品的**唯一事实来源**。
> 实现与本文冲突时，以本文为准；要改设计，先改本文再改代码。

SwiftUI · iOS 26+ / macOS 26+ · 8 providers · 无后端

---

## 01 产品定义

你有八个服务的账号，每个月的钱分散在八个后台里。这个 App 把它们加在一起，总数放在你能被动看到的地方。

### 它做什么

- 把一家加进服务列表。**不必先有 API 钥匙**——只订了 ChatGPT Pro、还没用 API Platform，OpenAI 也该在列表里
- 用量要自动取数时，再录入各家 API Key，存进 iOS Keychain，不出设备
- **手把手教你在每一家怎么创建 key**——分步说明、最小权限、一键复制、直达控制台。这是用量 setup，不是进门
- 手动刷新，统一折算到**日历月**。设置里可以打开「每次进入 App 的时候自动刷新用量」；花钱才能刷新的服务仍然不进这次刷新
- 仪表页回答"会花到多少"，服务页管理加进来的厂商
- 锁屏和主屏 Widget 显示当月总额。Mac 上对应的是菜单栏常驻数字和桌面小组件

### 它明确不做

- **任何写操作。** 不关实例、不改配额。看到数字不对，点链接去官网处理。
- **推送告警。** 推送需要服务器，一有服务器这个项目的性质就变了。Widget 承担告警职责。
- **实时牌价。** 汇率是打包目录里的一张表，不是每次刷新去问银行。几天滞后对「这个月花了多少」够用。
- **用量细节。** Cloudflare 能给几十个维度，一个都不要。只关心钱。
- **AI。** 不接云端模型，也不再调设备端模型。首屏那句猫说话是写死的候选句里按事实选出来的一条，没有模型参与。

---

## 02 四种"钱"

整个设计的核心难点。八家 provider 里，"花了多少钱"是四种不同的东西，不能用同一行 UI 表达。

| 类型 | 回答的问题 | 自动取数时典型是谁 |
|---|---|---|
| **用量后付费** usage | "已经花了多少？会花到多少？" | AWS Cost Explorer · Cloudflare 账单 API · Neon · Vercel |
| **预充值余额** prepaid | "还剩多少？什么时候烧完？" | OpenAI API Platform · Anthropic Admin |
| **固定订阅** subscription | "下次什么时候扣？我还在用吗？" | ChatGPT Pro · Cloudflare Workers Paid · GitHub Copilot |
| **免费额度内** freeTier | "离开始收费还有多远？" | 大部分账号现在的真实状态 |
| **月费加超额** planAndUsage | "月费多少？超额又花了多少？" | 套餐 + 从量超额的一家服务 |

四种钱说的是**一笔数字怎么折**，不是「这家只能是其中一种」。一家厂商往往同时有固定商品和从量：Cloudflare 有 Workers Paid，也有 R2 / Workers 用量；OpenAI 有 ChatGPT Pro，也有 API Platform。详情页两栏都在，缺的那栏空着，不要按厂商砍掉其中一栏。

### 统一到日历月的折算规则

首页大数字的定义：**本月 1 号 00:00 到此刻，所有 provider 的合计支出**。账本按美元记；设置里可以选显示货币，只影响怎么写成字。

| 类型 | 折算方式 | 精度 |
|---|---|---|
| 用量后付费 | 能拿日粒度就求和本月各天；只能拿周期累计就按周期内天数线性摊到本月 | 精确 / 估算 |
| 预充值余额 | 本月消耗 = 本地记录的月初余额 − 当前余额。首月没有月初快照，退化为"接入以来的消耗" | 首月不全 |
| 固定订阅 | 扣款日落在本月内 → 计全额；否则计 0。**不按天摊**，钱确实是那天扣的。开始月之前和结束月之后计 0 | 精确 |
| 免费额度内 | 计 0，单独显示额度使用比例 | 精确 |
| 月费加超额 | 月费按订阅计入（不外推）；超额按用量计入（可外推）。同一笔美元不能进两个字段 | 精确 / 估算 |

> **诚实性规则**
>
> confidence 必须照旧计算（`.exact` / `.estimated` / `.partial`），但**不再用 `≈` 号表达**——
> 金额格式化不输出任何约等标记。估算的透明性走「可查」路径：provider 详情页按家展示精度，
> `estimatedProviders` 记着哪几家是估的。
>
> 这条不是洁癖。一个和真实账单对不上的数字，用两次就没人信了，App 也就废了；
> 但解释它的地方是追查视图，不是主角数字旁边的一个符号。
>
> 预充值若一次读到多个原币钱包（DeepSeek 的 CNY + USD 槽），详情页把各槽原币都列出，
> 空槽也留下。仪表、行首、折算只看折美元后的合计。不要把一家拆成两行。
>
> 单币种换算时，汇率写在详情页大数字下面，一行「（1 CNY = $0.1404）」：右边是用户选的显示货币，不是永远美元。不要写「按 CNY xxx 换算」，也不要放在读数 / 历史那一组。原币正好是显示货币时这行不出现——大数字已经是原值。

---

## 03 八家的 API 现实

| Provider | 数据来源 | 认证 | 取数成本 | 状态 |
|---|---|---|---|---|
| Cloudflare | Billable Usage API，按产品拆分用量与费用 | API Token | 免费 | 可用 |
| Neon | Consumption API，compute / storage / 传输 | API Key | 免费 | 可用 |
| AWS | Cost Explorer API | IAM 只读 `ce:GetCostAndUsage` | **$0.01 / 次** | 要花钱 |
| OpenAI | `/v1/organization/costs`，日粒度，可按 project 分组 | Admin Key | 免费 | 可用 |
| Anthropic | `/v1/organizations/cost_report` | Admin API Key | 免费 | **个人账号不可用** |
| Vercel | `/billing/charges`，FOCUS v1.3 JSONL，日粒度、最长一年。Hobby 没有发票，这条回 404 `costs_not_found`，记用量 $0 | API Token | 免费 | 可用 |
| GitHub | Billing usage API，用户级（Actions 分钟 + 自购 Copilot） | PAT | 免费 | 可用 |
| Fly.io | GraphQL `api.fly.io/graphql` 只有 `billable` / `billingStatus` / `creditBalance`，没有本月花费 | — | — | **读数信箱** |
| OpenRouter | `GET /api/v1/credits`，已购 / 已用 | Management key | 免费 | 可用 |
| DeepSeek | `GET /user/balance` | API Key | 免费 | **两个钱包都展示；账本用折美元合计。空槽也留下。** |
| Moonshot (China) | `GET /v1/users/me/balance`（`api.moonshot.cn`） | API Key | 免费 | **国内站人民币，按目录汇率折美元。和国际站 key 不能混用。搜索别名：月之暗面 / Kimi** |
| Moonshot (Overseas) | `GET /v1/users/me/balance`（`api.moonshot.ai`） | API Key | 免费 | **国际站美元。和国内站是两家，key 不能混用** |
| xAI | Management `GET .../prepaid/balance` | Management key + Team ID | 免费 | 可用 |
| Cursor | 无公开账单接口 | — | — | **固定订阅**；超额可手填 |
| DigitalOcean | `GET /v2/customers/my/balance` 的 `month_to_date_usage` | PAT `billing:read` | 免费 | 可用 |
| Twilio | Usage Records Daily `Category=totalprice` 做合计；同窗 `Usage/Records` 不带 Category，有钱的叶子分类进明细 | Account SID + Restricted API key（Billing → usage Read） | 免费 | 可用 |
| PlanetScale | `GET /organizations/{org}/invoices` | Service token `read_invoices` | 免费 | 可用 |
| Upstash | Developer API Redis stats `total_monthly_billing` | 邮箱 + Developer key | 免费 | 原生账号可用 |
| ElevenLabs | `GET /v1/user/subscription` 额度与超量 | API Key | 免费 | 可用 |
| Railway | GraphQL `workspace.customer.currentUsage` | Account / Workspace token + Workspace ID | 免费 | 可用 |
| Stripe | `GET /v1/balance_transactions` 的 `fee` | Restricted key `Balance: Read` | 免费 | 可用 · 只计 USD 手续费 |
| Resend | 额度响应头 `x-resend-monthly-quota` | API Key | 免费 | 可用 · 仅免费档 3,000 封 |
| PostHog | `GET /api/billing/` 的 `current_total_amount_usd` | Personal API key | 免费 | 可用 |
| Clerk | 无公开自有账单金额接口 | — | — | **需先验证** |
| Sentry | `GET /api/0/organizations/{org}/stats_v2/` 本月已接收错误事件 | Personal Token（`org:read`）+ 组织 slug | 免费 | 可用 · Developer 档 5,000 条额度占比，不报钱；付费档会一直顶在 100% |
| Mistral | Admin `GET /v1/admin/usage` | Backoffice Admin API key（`x-api-key`） | 免费 | **需先验证** · Enterprise / Preview |
| Fireworks | `GET /v1/accounts/{id}/billing/summary`，`granularity=DAILY` | API Key + Account ID | 免费 | 可用 · Google Money |
| fal.ai | `GET /v1/account/billing?expand=credits` | Admin API Key（`Authorization: Key`） | 免费 | 可用 · 预充值余额 |
| Hugging Face | `GET /api/settings/billing/usage-v2`；组织走 `/api/organizations/{name}/billing/usage-v2` | Access Token（可选组织名） | 免费 | 可用 · `totalCostMicroUSD` |
| Turso | `GET /v1/organizations/{slug}/invoices?type=upcoming` | API Token + Organization slug | 免费 | 可用 |
| Baseten | `GET /v1/billing/usage_summary` | API Key | 免费 | 可用 · 扣完 credits 的 subtotal |
| ClickHouse Cloud | `GET /v1/organizations/{id}/usageCost` | Key ID + Key Secret（Basic） | 免费 | 可用 · 1 CHC = $1 |
| Linode | `GET /v4/account` 的 `balance_uninvoiced` | PAT `account:read_only` | 免费 | 可用 · 传输超额不在里面 |
| RunPod | GraphQL `myself.clientBalance` | API Key | 免费 | 可用 · 预充值余额 |
| Deepgram | `GET /v1/projects/{id}/balances` | API Key（`Authorization: Token`） | 免费 | 可用 · 预充值余额 |
| Scaleway | `GET /billing/v2beta1/consumptions` | Secret Key + Organization ID | 免费 | 可用 · 欧元按目录汇率折美元 |
| bunny.net | `GET /billing/summary` 的 `MonthlyUsage` | Account API key（`AccessKey`） | 免费 | 可用 · Pull Zone 本月已用 credit |
| Grafana Cloud | `GET /api/orgs/{slug}/billed-usage` 的 `amountDue` | Cloud Access Policy token + Org slug | 免费 | **需先验证** · 当月可能还没出账 |
| Elastic Cloud | `GET /api/v2/billing/organizations/{id}/costs/items` 的 `total_ecu` | API Key + Organization ID | 免费 | 可用 · 1 ECU = $1 |
| Datadog | `GET /api/v2/usage/estimated_cost` 的 `total_cost` | API Key + Application Key + 站点 | 免费 | **需先验证** · Pro/Enterprise、父组织、最多延迟 72 小时 |
| Novita | `GET /openapi/v1/billing/balance/detail` 的 `availableBalance` | API Key | 免费 | 可用 · 预充值余额，单位万分之一美元 |
| Apify | `GET /v2/users/me/usage/monthly` 的 `totalUsageCreditsUsdAfterVolumeDiscount` | API Token | 免费 | 可用 · 本月折完量的美元 |
| Tavily | `GET /usage` 的 `plan_usage` / `plan_limit` | API Key | 免费 | 可用 · credits 额度占比，不报钱 |
| DeepInfra | `GET /payment/usage` 的 `total_cost` | API Key | 免费 | 可用 · 美分 |
| Vast.ai | `GET /api/v0/users/current/` 的 `credit` | API Key | 免费 | 可用 · 预充值余额 |
| Firecrawl | `GET /v2/team/credit-usage` 的 `remainingCredits` / `planCredits` | API Key | 免费 | 可用 · credits 额度占比，不报钱 |
| CockroachDB Cloud | `GET /api/v1/invoices` 的草稿 `totals` | Secret Key（Organization · Billing Coordinator） | 免费 | 可用 · 本周期草稿发票。免费期间空列表记 $0 |
| Typesense Cloud | `GET /api/v1/invoices` 的 `amount_cents` | Management API Key | 免费 | **需先验证** · 按周出账 |
| Aiven | `GET /v1/billing-group` 的 `estimated_balance_usd` | Personal token（`aivenv1`） | 免费 | 可用 · 各计费组税前预估合计 |
| SiliconFlow | `GET /v1/user/info` 的 `totalBalance`（`api.siliconflow.cn`） | API Key | 免费 | 可用 · 国内站人民币，按目录汇率折美元 |
| AI/ML API | `GET /v2/billing` 的 `current_balance` | API Key | 免费 | 可用 · 预充值余额，官方美元 |
| StepFun (China) | `GET /v1/accounts` 的 `balance`（`api.stepfun.com`） | API Key | 免费 | 可用 · 国内站人民币，按目录汇率折美元。和国际站 key 不能混用。搜索别名：阶跃星辰 |
| StepFun (Overseas) | `GET /v1/accounts` 的 `balance`（`api.stepfun.ai`） | API Key | 免费 | 可用 · 国际站美元。和国内站是两家，key 不能混用 |
| Telnyx | `GET /v2/balance` 的 `balance` | API Key | 免费 | 可用 · 预充值余额，不含授信 |
| MariaDB Cloud | `GET /billing/v1/bills` 的 `total` | API Key（`X-API-Key`） | 免费 | 可用 · 本月用量分摊合计 |
| IONOS Cloud | `GET /billing/invoices/{YYYY-MM}` 的 `total.quantity` | DCD JWT（Bearer） | 免费 | **需先验证** · 月末出账，欧元按目录汇率折 |
| UpCloud | `GET /1.3/account/billing/summary/{YYYY-MM}` 的 `total_amount` | API Token（Bearer） | 免费 | 可用 · 本月扣款合计，欧元按目录汇率折 |
| Confluent Cloud | `GET /billing/v1/costs` 的 `amount` | Cloud API Key（Basic） | 免费 | 可用 · 折后美元，最多晚 72 小时 |
| Vonage | `GET /account/get-balance` 的 `value` | API Key + Secret（Basic） | 免费 | 可用 · 预充值欧元余额 |
| Plivo | `GET /v1/Account/{id}/UsageSummary/` 的 `total_spend` | Auth ID + Token（Basic） | 免费 | 可用 · 本月用量加其它费用 |
| MessageBird | `GET /balance` 的 `amount` | Access Key | 免费 | 可用 · 预充值余额。credits 不是钱；后付费这条接口给 0 |
| IBM Cloud | `GET /v4/accounts/{id}/usage/{yyyy-mm}` 的 `billable_cost` | API Key（先换 IAM token） | 免费 | 可用 · 本月应付合计 |
| ClickSend | `GET /v3/account` 的 `balance` | Username + API Key（Basic） | 免费 | 可用 · 预充值余额，账户币种按目录汇率折 |
| Infobip | `GET /account/1/balance` 的 `balance` | API Key（`Authorization: App`） | 免费 | 可用 · 预充值余额。走公开入口 `api.infobip.com` |
| Textmagic | `GET /api/v2/user` 的 `balance` | Username + API Key（Basic） | 免费 | 可用 · 预充值余额，`currency.id` 按目录汇率折 |
| Botpress | Admin `GET /v1/admin/workspaces/{id}/billing/upcoming-invoice` 的 `lineItems[].totalInCents` | Personal Access Token + workspace id | 免费 | 可用 · 即将出账发票 |
| Neo4j Aura | `GET /v2beta1/organizations/{id}/billing/usage` 的 `list_cost` | Client ID + Secret（OAuth client_credentials） | 免费 | 可用 · 每天每组织 10 次，最多滞后 48 小时 |
| Google Cloud | 无公开本月花费接口；Cloud Billing REST 只管账号和价目 | — | — | **读数信箱** |
| Slack | 无公开工作区账单接口 | — | — | **读数信箱** |
| Notion | 无公开账单接口 | — | — | **读数信箱** |
| Figma | 无公开账单接口 | — | — | **读数信箱** |
| Supabase | 公开 Management API 没有账单金额 | — | — | **读数信箱** |
| Linear | 无公开账单接口 | — | — | **读数信箱** |
| Pulumi Cloud | 无公开账单金额接口 | — | — | **读数信箱** |
| GitLab | 公开接口只有 CI 计算分钟，没有账单金额；钱在 Customers Portal | — | — | **读数信箱** |

**不接入。** 下面这些家已经进 `ProviderCatalog`（图标、显示名、理由都在），但 `accessStatus == .declined`。iOS / Android 的添加列表和落地页 marquee **都滤掉**。目录里留着是为了不再反复核实、画廊能看到身份。理由写在 `ProviderDescriptor.declineReason`。

| Provider | 理由 |
|---|---|
| Groq | 公开文档只有控制台 Usage，没有账单金额接口 |
| Together AI | 预充值只在控制台，没有公开 credits 接口 |
| Replicate | 公开 OpenAPI 只有预测和部署，没有账单金额 |
| Perplexity | API 平台预充值只在控制台，公开接口不给余额或本月花费 |
| Cohere | 公开 API 没有账单金额 |
| Google Gemini | Gemini API / AI Studio 没有给 API key 的账单接口。金额在 Cloud Billing，那是另一家 |
| Midjourney | 没有公开 API，只能网页订阅 |
| Runway | 没有公开账单金额接口 |
| Netlify | 公开 API 只有付款方式，没有发票金额 |
| Firebase | 账单走 Google Cloud Billing，没有独立的 Firebase 账单接口 |
| Windsurf | 没有公开账单接口 |
| Pinecone | 用量和发票只在控制台，公开 API 没有账单金额 |
| Modal | 公开接口只有 Python SDK / CLI，没有 HTTP 账单金额 |
| Hetzner | Cloud API 只有价目，没有本月花费 |
| Auth0 | 没有公开账单接口 |
| Mixpanel | 没有公开账单金额接口 |
| Amplitude | 没有公开账单金额接口 |
| LaunchDarkly | 没有公开账单金额接口 |
| Algolia | 公开 API 没有账单金额 |
| Zapier | 没有公开账单接口 |
| Discord | 没有公开服务器账单接口。商标条款也不许改色改 path，字母回落 |
| Replit | 没有公开账单金额接口 |
| Webflow | 没有公开账单接口 |
| Snowflake | 没有给客户的 HTTP 账单金额接口 |
| Intercom | 没有公开账单接口 |
| Backblaze | 账单只在控制台和合作伙伴 CSV，没有账单金额接口 |
| AssemblyAI | 预充值只在控制台，没有公开余额接口 |
| Mux | Delivery Usage 只给秒数，没有账单金额 |
| Civo | Charges API 只给小时数，没有账单金额 |
| Koyeb | 没有公开账单金额接口 |
| PagerDuty | 没有公开账单接口 |
| WorkOS | 没有公开账单接口 |
| Contentful | 没有公开账单金额接口 |
| Cloudinary | 公开 API 只有用量计数，没有账单金额 |
| SendGrid | 公开 API 只有发送统计，没有账单金额 |
| Mailgun | 公开 API 只有发送统计，没有账单金额 |
| Lambda | 没有公开账单金额接口 |
| Cerebras | 预充值只在控制台，没有公开余额接口 |
| Cartesia | TTS 是 credits，Agent 才是美元，没有一份能对账的总账单 |
| Helicone | 公开 API 估的是下游 LLM 花费，不是付给 Helicone 的账单 |
| Wasabi | 账单金额只在合作伙伴 WACM，客户没有账单接口 |
| CoreWeave | 账单只在控制台，公开接口没有账单金额 |
| Honeycomb | 没有公开账单金额接口 |
| New Relic | NerdGraph / NRQL 只给 GB 和席位，金额要自己乘单价 |
| Weaviate Cloud | 没有公开账单金额接口 |
| Trigger.dev | 没有公开账单金额接口 |
| MiniMax | Token Plan 接口只给配额窗口，不是按量美元余额 |
| Hyperbolic | 没有公开余额或账单金额接口 |
| Jina | 没有公开账单金额接口 |
| DashScope | 账单走阿里云 BSS 整云账号，没有单独的通义账单接口 |
| Paperspace | 没有公开账单金额接口 |
| Salad | 没有公开账单金额接口 |
| Browserbase | 没有公开账单金额接口 |
| Convex | 没有公开账单金额接口 |
| Langfuse | 没有公开账单金额接口 |
| Gcore | 没有公开账单金额接口 |
| Contabo | 没有公开账单金额接口 |
| Northflank | 没有公开账单金额接口 |
| Inngest | 没有公开账单金额接口 |
| Tinybird | 没有公开账单金额接口 |
| LiveKit | 没有公开账单金额接口 |
| Meilisearch Cloud | 账单只在控制台，没有公开账单金额接口 |
| MotherDuck | 公开接口只有 CU 小时，没有账单金额 |
| Zhipu | 公开接口没有一份能对账的总账单，只有套餐配额 |
| Postmark | 公开 API 只有发送统计，没有账单金额 |
| Sanity | 没有公开账单金额接口 |
| Ably | 公开接口只有消息计数，没有账单金额 |
| Crunchy Bridge | 发票只在控制台，没有公开账单金额接口 |
| InfluxDB Cloud | 公开接口只有用量指标，没有账单金额 |
| Axiom | 公开接口只有 GB 摄入，没有账单金额 |
| Checkly | 公开接口只有套餐额度，没有账单金额 |
| Timescale Cloud | 没有公开账单金额接口 |
| BrowserStack | 没有公开账单金额接口 |
| Snyk | 没有公开账单金额接口 |
| CircleCI | 公开接口只有 credits / 分钟，没有账单金额 |
| Terraform Cloud | 没有公开账单金额接口 |
| Tailscale | 没有公开账单金额接口 |
| Deno Deploy | 没有公开账单金额接口 |
| Plausible | 没有公开账单金额接口 |
| Prefect | 没有公开账单金额接口 |
| Airbyte | 没有公开账单金额接口 |
| Exoscale | 用量接口只给小时和 GiB.h，没有账单金额 |
| Brevo | 公开接口只给发送 credits，不是账单金额 |
| Redpanda Cloud | 账单只在控制台和 CSV，没有公开账单金额接口 |
| Fauna | 没有公开账单金额接口 |
| Kamatera | 没有公开账单金额接口 |
| OneSignal | 没有公开账单金额接口 |
| Courier | 没有公开账单金额接口 |
| Doppler | 没有公开账单金额接口 |
| Infisical | 没有公开账单金额接口 |
| Kinsta | 没有公开账单金额接口 |
| imgix | 没有公开账单金额接口 |
| Fathom | 没有公开账单金额接口 |
| Mailchimp | 没有公开账单金额接口 |
| Klaviyo | 没有公开账单金额接口 |
| Bitbucket | 没有公开账单金额接口 |
| Buildkite | 没有公开账单金额接口 |
| Codecov | 没有公开账单金额接口 |
| SonarCloud | 没有公开账单金额接口 |
| Fivetran | 没有公开账单金额接口 |
| Sinch | 官方声明没有 Billing API，账单只在控制台 |
| SMTP2GO | 公开 API 只有发送配额，没有账单金额 |
| Mailjet | 公开 API 只有资料和发送统计，没有账单金额 |
| n8n Cloud | n8n Cloud 没有公开账单金额接口 |
| Hasura | 账单只在控制台，没有公开账单金额接口 |
| 46elks | 官方 GET /a1/me 的 balance 是未写清单位的整数，不能自行折钱 |
| KeyCDN | 公开报表是流量字节和 credit 流水，没有一份本月应付合计 |
| CDN77 | credit-balance 没写货币，不能当美元用 |
| DataStax Astra | DevOps 账单是企业 consumption 报表，普通组织没有一份可读的本月账单 |
| Dagster Cloud | 没有公开账单金额接口 |
| dbt Cloud | 没有公开账单金额接口 |
| HashiCorp Cloud | HCP 没有公开账单金额接口 |
| Appwrite Cloud | 没有公开账单金额接口 |
| Stytch | 没有公开账单金额接口 |
| Okta | 没有公开账单金额接口 |
| Chargebee | 公开接口是商户账单产品，不是 Chargebee 自己的订阅账单 |
| Lemon Squeezy | 订单只有 total，没有平台抽成字段，不能自己按费率发明 |

**阻塞项 1 · Anthropic** — Usage & Cost Admin API 对个人账号不开放，需要在 Console → Settings → Organization 建组织后签发 Admin API key。没有的话这家 v1 里只能降级成"固定订阅"手工录入。

**阻塞项 2 · Fly.io** — 已核实。未文档化 GraphQL 没有本月花费，走读数信箱。Launch 档固定费走手动订阅。别再为它写 `BillingProvider`。

**AWS 的取数成本决定了刷新策略** — Cost Explorer 每次请求 $0.01。所以 **AWS 默认不参与全局刷新**，单独按钮，按钮文案直接写"约 $0.01"。永远不做后台轮询——自动化在这里是要付钱的。

---

## 04 结构与界面

底部三个 tab。仪表回答"会花多少"，服务管理接入，设置放剩下的。用 iOS 26 原生 `TabView`——Liquid Glass 材质和滚动收起是系统给的，加一行 `.tabBarMinimizeBehavior(.onScrollDown)`，**不要手搓玻璃效果**。

### 第一次打开

四页 carousel。底部系统 page control，另写可读的「2 / 4」（VoiceOver 读「第 2 页，共 4 页」）。右上角「跳过」。前三页底栏「继续」，最后一页「添加第一个服务」——关掉开场，跳到服务 tab，弹出添加列表。

每一页一块对应界面的**活预览**（SwiftUI，灌本节设计稿数字，跟着显示货币改写），不是截图 PNG，也不是三只换脸的猫。没有对应屏的那页用 SF Symbol。猫可以出现在真有猫的界面里（小组件），不要当每一页的主角。

| 页 | 画面 | 标题 | 这一页只讲 |
|---|---|---|---|
| 1 | 仪表上半截：从量合计 **$43.20**、本月订阅单独一行 $4.00、构成圆环。预览下面「显示货币」 | 这个月花了多少 | 各家收成一个数字。拨货币，数字当场改写。不要再问外观、名字、提醒 |
| 2 | 三枚图标：只在这台设备 / 不进 iCloud / 不跟备份走。**不要截凭据表单** | 凭据不出这台设备 | Keychain 最严一档；换机用设置里的导入与导出 |
| 3 | 中号小组件活预览（猫 + 数字 + 构成条）。Mac 上是菜单栏胶囊 + 同一张中号预览 | 不必打开也能看见 | 没有按金额推送。iPhone 把数字放主屏或锁屏；Mac 放菜单栏和桌面小组件 |
| 4 | 添加列表行（AWS / Cloudflare / OpenAI / GitHub） | 加上第一家服务 | 先加进列表就行，不必现在就有 API 钥匙 |

预览数字只用本节那组设计稿，不是运行时取数。GitHub $4 是订阅，不进主角数字、不进构成圆环——开场预览和真仪表同一条规则。

不要教练浮层，不要指着按钮。提醒、外观进设置，不进这四页。

宽壳（横屏 iPad、Mac）开场左右并排：左边是按手机列宽收住的活预览，右边标题和说明。不要把手机竖叠拉成通栏。竖屏 iPad 仍是上图下文，但预览和正文限宽居中。超大字号退回竖叠。

### Tab 1 · 仪表

模块化卡片，可排序可隐藏。第一块永远是本月合计，后面按关心的顺序排。滚动时 tab bar 收起。

屏幕内容（从上到下）：

- 本月从量合计，下方 caption「预计月底 $94」；有订阅再一行
- 猫的一句看点
- bento：一张宽的构成卡（圆环 + 图例），点整张卡从右侧推进构成页；下面两张方卡——较上月同期（点整张卡从右侧推进对比页）、近几个月从量
- 「需要注意」：异常 / 余额告急 / 即将扣款 / 免费额度，没数据整块不出现

### Tab 2 · 服务

**一行一个厂商。** 没加进来的不出现。列表底「添加服务」从右侧推进。右上角是排序，不是添加——添加已经在列表底和空态里了。

排序三种：**计费模式**（默认）、**类别**和**价格**。前两种是分组，第三种是扁列表。

**「历史服务」是一个入口，不是列表底下的一节。** 它和「添加服务」同住最后那张卡，点进去才是一览
（已经结束的厂商 + 已经退掉的独立手动订阅）。主列表回答的是「我现在每个月付多少」，
停掉的东西挂在下面只是噪音；但它们必须留着——过去几个月的账里有它们。没有历史就不出这一行。

计费模式按第 02 节那些钱的种类分组，小标题用那套名字。组的顺序是：用量后付费 → 月费加超额 → 预充值余额 → 固定订阅 → 免费额度内。行首一律是本月花了多少；预充值的「还剩多少」只写在副标题，不要把钱包剩额放到行首。组内保持加入顺序。

类别按这家干什么活分组（AI 推理、托管、数据库……），和仪表页「按类别构成」同一套名字——类别标在服务目录里，界面不猜。组的顺序跟目录里的声明序走（AI 推理开头、其他收尾），**不按金额排**：刷新一次就重排组序会让人找不着刚看过的那一行。组内保持加入顺序。

这两个词分的是两件事，别混着说：计费模式说的是行首那个数在说什么，类别说的是这家是干什么的。

分组排序下，加进来的服务只落在一组时不画小标题。一组标题是废话。

按价格是一张扁列表，按行首那个数从高到低，不分组。免费额度行首是比例，按价格时会沉底。

行结构：`圆点 · 名称 · 右侧(金额 / 副标题) · ›`

同一家两份用量（工作 / 个人 Cloudflare）不把主列表拆成两行。点进去，详情里才是用量商品。

演示数字仍按设计稿一家一行（合计 47.20）。不要在主表示例里画第二份 Cloudflare。

| 名称 | 金额 | 副标题 |
|---|---|---|
| AWS | $21.40 | 手动刷新 |
| Cloudflare | $11.05 | 12 分钟前 |
| OpenAI | $7.62 | 余额 $42 |
| GitHub | $4.00 | 8 月 3 日扣款 |
| Neon | $3.13 | 12 分钟前 |
| Vercel | 免费额度（灰） | 用了 34% |

只加了 ChatGPT Pro、还没有 API 钥匙的 OpenAI：行在列表里，金额走订阅，副标题是套餐名。构成图里没有它——订阅不进饼图。

### 添加一家

添加列表只列还没加进来的。已经加过的不出现——再接一份用量从详情进。点一家从底下弹出一张**小抽屉**，不要再推一整页简介。

空搜索是「常见服务」：市占档 1 和档 2，但刨去只支持读数信箱的那几家，按品类分组（组序跟 `ProviderCategory` 声明序走）。档位是目录里标的市占位置，界面不解释档位这两个字。一打字就搜全目录——档 3、4 和只走读数信箱的，按显示名和搜索别名也能命中。空结果用系统 `ContentUnavailableView.search`。列表底「更多服务」推进下一页，那一页空搜索列剩下的全部（档 3、4，加上档 1、2 里只走读数信箱的），同样有搜索、同样按品类分组。不要在本页再挂一百行。

抽屉中间一颗比列表行更大的 `ProviderGlyph`，下面是目录里那句这家是什么（`summary`）。不要再写一遍名称——主按钮已经是「添加《服务名》」。图标和抽屉顶（指示条下面）留一截空，不要贴顶。点了写入成员关系，关掉抽屉，推进详情。

**不要问「钱从哪来」。** 计费模式和支持格是按量账单的属性，写在《服务名》连接参考抽屉顶部，不写在进门。需要哪些凭据，等连接用量时看教程。

### 详情

导航标题是厂商名。两栏都在，不管这家「典型」是按量还是订阅：

**按量计费**
- 还没有用量身份：空态，主操作「连接《服务名》账单」。点开是教程 + 填凭据（下面两步），用 sheet / 抽屉，不要再叠一层「添加服务」那种整页推进。不要脚注解释要先连接。
- **没有公开账单接口的那几家**（读数信箱）：空态主操作是「填入本月花费」，不是任务书。任务书是次要：「用脚本自动上报」。手填也算用量身份。
- 已有一份：读数、图、刷新都针对这一份。手填的那份主操作是「更新花费」；没接脚本、也没有 API 就不要刷新。抽屉里选月份，可以补过去的月份，12 个月那张图才有柱。
- 凭据入口是「管理凭据」，不要在详情里同时放「重新填写凭据」和「再接一笔按量账单」。点开从右侧推进：已接入的用量身份列在上面，点一份就重新填这一份的钥匙（教程 + 凭据，和第一次连接同一套，仍走抽屉）；划掉删除这一份，不拆厂商门口。底下一行「再接一笔按量账单」（第二个 Cloudflare 账号、第二个 OpenAI org），走同一套教程 + 凭据。测通成功后再问昵称。主列表仍是一行。

**固定订阅**
- 「加一笔固定订阅」。和按量计费不是二选一。
- 没有用量也可以先录。
- 月付问「开始时间」，选年月——从那一个月起每个日历月全额计入。年付问「首次扣款日」。
- 空列表脚注按目录自动生成：这家有预置档位就写「例如 Workers Paid 等固定订阅费用服务」（用该厂商目录里第一个档位名，前面的厂商名可省）；没有预置档位就不要脚注。
- **开始时间选不到未来的月份。** 从明年三月开始的订阅在账本上是纯 0，只会让人以为记错了。
  当月内的未来日期留着——年付的首次扣款日常常就在这个月的后几天。
- **退订是填一个「结束时间」，不是按一个「结束」按钮。** 编辑页里一个「已经退订」开关加一个年月选择器，
  结束月可以是过去的任何一个月（三个月前退的就填三个月前），也可以填在未来
  （这个月取消、服务用到 11 月底，那几个月照常计入）。结束月当月全额计入，之后计 0。

**没有「恢复」。**
订阅是**一段区间**。1–3 月用了 Pro、5 月又订回来，那是两段：列表里新加一笔，起点 5 月。
「恢复」会把中间没付钱的 4 月一起补上，那个数就是编的。所以退订之后只有两条路：
留着（它进「历史订阅」），或者删掉（那是「我根本录错了」）。同理，结束掉的厂商也没有恢复——
又要用就重新接一次用量、重新加一笔订阅。

**历史订阅 / 历史用量**（详情页内）
- 到此刻为止已经结束的订阅列在「历史订阅」，结束掉的用量身份列在「历史用量」。都灰着，都带「已结束 · 2026年8月」。
- **结束月还没到的仍然留在「固定订阅」里**，副标题写「到 2026年11月 为止」——那几个月的钱还得付。
- 两节都只在非空时出现，不写脚注解释——「已结束 · 月份」自己说得清楚。
- 列表里划出来的只有「删除」，而且**不带 `role: .destructive`**：那个 role 会让 SwiftUI 先播一次删行动画，
  而真删还卡在确认弹窗后面，行会先消失一下再弹回来。

按量和固定订阅都还没有时，不要渲染顶部金额那一节——空着会画出一个「—」。

顶部金额**不跟仪表盘的取景框**：永远是本月、这家全部账号、含订阅（服务列表那一行同一个口径，两页永远同一个数）。详情页回答的是
「这家这个月要付多少」，那是账单事实；首屏那颗「含订阅 / 仅从量」是首屏的取景，
让它改写这一页的大数字，等于同一家的钱在两页各说一个数——而这一页上「按量计费」
和「固定订阅」本来就是并列的两节。月份和排除名单同理不跟，历史那排 7/30/12 是这一页自己的。

**历史图时间轴**（详情页内）

- **7 天 / 30 天是看得见的宽度**，不是一页。底下是一条最多 12 个月的日线时间轴。打开停在最右边（今天）。
- 平移用系统 `chartScrollableAxes`：轻滑移一点，甩一下惯性滑过很多天。不要整窗跳页。
- 图上方写出**当前看得见的**起止日，跟着滑动连续变。
- 纵轴按整段日线一次定死，平移时柱高不要跟着每一天重算——那是另一种「整个都变」。
- **12 个月不滑。** 已经是回看上限。
- 平移是拖，看某一天是点一下。不要用 `chartXSelection` 的拖去抢平移。
- 「读数明细」仍按所选档位从今天往回，不跟图上滑到哪一段。
- 滑到哪一段不落盘。切 7 / 30 只改看得见的宽度，时间轴还是那一条。
- 手填补的过去月份仍然只进 12 个月那张图，不因为日线图能滑到那个月就冒出来。

两样钱都有的家，大数字下面摊开一行「（按量 $7.62 + 订阅 $20.00）」，两半加起来正好是那个数字。这行本身是金额，用主文字色，不是灰的说明文字；括号跟着语言走（中日全角、英文半角），和汇率那行同一条规矩。
只有一样钱的家不出这行——那一样就是大数字本身。免费额度那一屏主角是百分比，也不出。

危险操作文案是「清空本机《服务名》相关账单数据」，不是「删除这家服务」。

**结束与删除是两件事。** 过去几个月的账单不是存下来的，是拿**当前**的接入表和订阅表逐月重算的
（`MonthSpendHistoryCalculator`）。所以「把这一行删掉」等于「过去每个月的合计都少掉这笔钱」——
真付过的钱在账本上消失。不用了的正常出路必须是结束，不是删除。

结束这家：底下所有用量身份归档（Keychain 里的凭据删掉、不再刷新），挂在这家上的订阅停在本月，
成员关系和历史 Snapshot 全部留着。这家从服务列表挪进「历史服务」那一页，从下个月起不计入总额，
过去每一个月照旧算得出来。**没有恢复**：又要用就重新接一次用量、重新加一笔订阅——
凭据本来也已经删了，那本来就是重新接一次。

清空本机这家的账单数据：成员关系、用量身份、对应 Keychain、订阅、**历史 Snapshot** 一起删。
过去几个月的合计会跟着变，不可撤销。文案要把这一条说出来。

结束一份用量不影响其它用量，也不动厂商门口（还有订阅或别的用量就还在列表里）。

### 连接用量 · 教程

抽屉顶部先是计费模式、支持情况、连接凭据。支持情况只写当前这一档（例如完全支持）和一句注释，不要 info、不要展开另外两档。连接凭据是一整块：左边一个标签，右边字段名逐行右对齐，不要拆成多行列表——发丝分割线会把它们拆成好几样东西。这说的是这条按量账单能不能自动取数、要准备什么，不是这家客服好不好。

按每一项分段看怎么拿到。小标题是「如何获取《字段名》」，不要只写字段名。Cloudflare 为例：

步骤只在用户真的要换一个画面、做一个选择时才拆。打开页面和创建是同一件事就写成一句；「创建之后立刻复制」不要单独成步。以后可以配截图再拆细，现在不要为了有步骤而写步骤。

**如何获取API Token**
1. 打开 **Cloudflare 控制台** 的 **API Tokens** 页面，点 **Create Token**。「Cloudflare 控制台」是行内链接，**前面**跟系统的 safari 符号。不要另起一个「在浏览器中打开」按钮。
2. 选 **Custom token**，只勾 **Account · Billing · Read**。Account Resources 选你的账户，其余留默认，然后复制 token。权限名写在句子里就够了，Cloudflare 这一步不要另起「权限」复制块。教程只写正确做法，不要跟「不要给 Edit」「只显示一次」这类旁白。

**如何获取Account ID**
不要自己写怎么找。写成「请查阅 **查找 Account ID**」，「查找 Account ID」是行内链接，前面跟系统 safari 符号（用 SwiftUI `Image`，不要 `NSTextAttachment`，否则图标不渲染）。打开编译死的 Cloudflare 文档。目录只标哪几个字可点，绝不带 URL。

导航标题是「《服务名》连接参考」，例如「Cloudflare连接参考」。步骤序号是圆角方形：比原来的蓝圆点大、灰底、灰边、字跟 label。不要用 `n.circle.fill`。

底部主按钮「我拿到凭据了，下一步」。位置、胶囊、底栏高度必须和添加确认抽屉那颗「添加《服务名》」、连接页那颗「测试连接」对齐。底栏不要镂空，列表行不许从按钮底下透出来。

### 连接用量 · 凭据

导航标题是「连接《服务名》」，例如「连接Cloudflare」。

字段：API Token、Account ID。明文输入，不要掩码——掩码会把 token 和 Account ID 做成两套控件，光标和热区对不上。

- 底部主按钮先是「测试连接」，和前面两步同一颗胶囊、同一个 Y。文本框还有空着的时候按钮是灰色不可点，不要点下去才说请填写。测的时候不要 `.disabled`，否则绿色铺色会被洗掉。凭据 section 的页脚写「凭据将保存到 Keychain，什么是 Keychain？」；后面那句是链接，打开说明。不要堆在按钮下面把按钮顶上去。字段名（API Token、Management Key）贴着卡片上沿，不要留一整行 44pt 的空白。
- 测的时候**不要转圈**：系统绿从左到右盖住按钮。不要另起一颗保存按钮、也不要把测试塞进列表行。
- 凭据字段名字一行、输入一行；点到名字或输入行空白处也要弹出键盘。输入右侧给「粘贴」，从剪贴板填入。**不要 placeholder。**
- 成功和失败都写在「凭据」字段下面，不要另开一节。成功只写金额和周期，不要再跟一句「这个数字应该和你后台一致」。失败：具体原因和怎么修（401 / 403 / 断网 / 空读数），并给一次错误触觉。
- 理论支持（`accessStatus == pendingVerification`、不是读数信箱）的服务，测完之后在**同一张抽屉**里多一节「反馈」。成功、失败都出现。正文预填、可改，发送走应用内反馈那条。发出去之后这一节只留「收到了，谢谢。」，表单收掉。另有一个默认关掉的开关，附带这次测试的 HTTP 摘要：密钥和账单数字打码。不另开一步，底栏仍是测试 / 保存。完全支持并测试过的、读数信箱、还没测，都不要出这一节。
- 测通之后，**同一颗**主按钮变成「保存到 Keychain」。改过凭据则退回「测试连接」。**测不通过不让保存**，也不要测通了就自动写入——用户要先核对金额。
- 铺色动效必须能在开发菜单的组件画廊里点着看。

### Liquid Glass 的使用纪律

玻璃只用在**浮在内容之上的导航层**：tab bar、navigation bar、以及未来可能的 toolbar。仪表页的卡片、列表的行、按钮——**全部不透明**。

这是 Apple 自己的建议，也是让界面不糊的唯一办法。用标准 `TabView` 和 `NavigationStack`，重新编译就自动有了，不需要写任何玻璃相关代码。

已知坑：`.tabBarMinimizeBehavior(.onScrollDown)` 在用了 `NavigationStack(path:)` 绑定路径的 tab 里可能不触发。遇到了不用怀疑自己。

### iPad

iPhone 和 iPad 共用一份二进制，**不要为平板另开 target、另写一套 Model**。分叉只发生在导航壳。

| 条件 | 壳 |
|---|---|
| regular 且窗口宽 > 高（横屏 iPad、够宽的分屏） | iPad 壳：`NavigationSplitView` 侧栏三个入口；仪表单列滚动、铺满整列（左右只留 `pageHorizontal`），方卡和洞察模块是等宽 bento、按 `dashboardTileMin` 自动换行；服务 / 设置再套一层主从；接入向导左右并排；开场左右并排 |
| 其余（竖屏、窄分屏、iPhone） | 现在的 iPhone 壳：底栏三个 tab、单列、`NavigationStack` 推进 |

不要用 `horizontalSizeClass` 单独判断——iPad 竖屏也是 `.regular`。

宽壳仪表是**一列 bento，不是两列 List**：合计 + 构成猫卡独占一行吃满整列，左右只留 `pageHorizontal`，和服务 / 设置列里的分组卡同一个边距（不要再给内容列设上限居中——列头标题钉在列边，内容缩在中间就是两截解释不了的留白）；「较上月同期」「近几个月」和「需要注意」的每个模块各自成卡，低于 `dashboardTileMin` 就换行，最多三列，只有一行时按张数等分。窗口再宽，多出来的宽度变成更多列，单张卡不拉成横条。「需要注意」的模块卡用模块名（异常 / 余额告急 / 即将扣款 / 免费额度）做小标题，行和手机同一套洞察行。

筛选在 iPad 壳里用 popover，不要再弹一张铺满的 sheet。模块 View、折算、取数都不为平板改。

**抽屉在横屏 iPad 上不是底栏。** HIG 把 detent 标成 iPhone 机制；iPad 用居中的 form / page sheet。外壳只走 `meterDrawerChrome`，pad 分支换呈现，iPhone 的 detent 不动：

| 档 | iPhone | 横屏 iPad |
|---|---|---|
| compact | 按内容收矮的 detent | form sheet，高度贴内容 |
| expandable | 按内容收矮，可拉到 large | form sheet |
| large | 开满 | form sheet |
| mediumLarge | medium / large | form sheet |
| page | 开满 | page sheet（连接参考双栏） |
| fitted | 开满 | 按内容的理想尺寸收（分享卡）。里面不许用 List / Form——理想高是 0 |

抓手只出现在手机。iPad 的筛选走 popover，不要再套 sheet 外壳。Features 不要手写 `presentationDetents` / `presentationSizing`。

### Mac

iPhone / iPad / Mac 共用 `MeterKit` 里的 Model、折算、取数。Mac 另开薄壳 target（`Mac/`），**不要用 Mac Catalyst**，也不要把 iOS 包在 Apple Silicon 上当 Mac 版。分叉只发生在场景和导航壳。

| 面 | 规则 |
|---|---|
| 主窗口 | 恒开宽壳。外层永远两栏 `NavigationSplitView`（侧栏 + 主区），切 tab 只换主区。不要在两栏 / 三栏分栏之间切换。服务 / 设置的列表和详情走主区里的主从列。窗口不带工具栏：顶上只有红绿灯那一行（32pt），一颗 `ToolbarItem` 都不声明（哪怕不可见的占位，窗口就会长出一条 52pt 工具栏）。列头（`meterMacColumnBar`）紧贴其下，和侧栏第一行同一水平；标题左沿三个 tab 一律 `md`，不随内容列限宽漂移——同一个壳，标题不该随页面走。列头不画进红绿灯那一行：titlebar 区域里的东西系统只当拖拽区，鼠标点不到。侧栏只有三个入口，不放品牌章也不放猫——和菜单栏、程序坞重复；底部可以钉一块用户在「编辑」里挑的一格宽模块（`DashboardLayout.sidebarModule`），钉了主区就不再画它，卡里的链接切回仪表盘再开 |
| 侧栏 | 仪表盘、服务、设置。和 iPad 同一套三个入口 |
| 设置 | 主窗口三栏，同一份 `SettingsView`。⌘, 切到这一栏，不要另开 `Settings` 场景。控件走系统设置：grouped `Form`、`Toggle` 是 switch 不是 checkbox，行高按可点下限，列表里的按钮是一行字不是凸起 NSButton。每一列自己的标题和返回，不要统一成一条窗口 top bar |
| 导入与导出 | 导出 / 导入是这一列里的分段控件，不要进窗口顶栏 |
| 刷新 | 工具栏按钮 + ⌘R。不要下拉刷新 |
| 菜单栏 | `MenuBarExtra`，`.window` 式面板。常驻那一小块由设置「通用 › 菜单栏样式」决定：默认只有一只猫（模板图，表情跟仪表盘），可改成猫 + 金额或只有金额；花了多少钱是私事，不默认常驻在屏幕右上角。常驻金额口径和 Widget 相同：未筛选、跟「算进固定订阅」。点开是仪表盘首屏搬过来的：数字、预计、构成条、近几个月，口径跟仪表盘取景框（限定语随数字一起出现）；底下刷新、打开主窗口、退出。菜单栏不自己打账单 API。「开机自启动」问系统（`SMAppService`），不落盘；「关掉窗口后只留在菜单栏」= 最后一个主窗口关掉退成 accessory，主窗口再露面回 regular。这两档偏好不进迁移包 |
| 桌面小组件 | 和小 / 中 / 大 iOS Widget 同一套视图。没有锁屏 accessory。Widget 仍不链接 Providers |
| 分享卡 | 存文件 / 拷贝 / 系统分享。不要申请相册权 |
| 开场 | 左右并排：左边按手机列宽收住的活预览，右边标题和说明。第 3 页标本 TODO 单独定制（菜单栏 / 桌面小组件），先留空；文案不要写主屏或锁屏 |
| 凭据 | 仍是 `WhenUnlockedThisDeviceOnly`。和 iPhone 不共享 Keychain。换机走 `.tollcat` |
| App Group | 只用给本机 Mac Widget。前缀是 Team ID，不是 iOS 的 `group.` |
| iOS 包 | `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO`。没出 Mac 壳之前，不要让 iPad 窗口冒充 Mac 版 |

抽屉在 Mac 上跟横屏 iPad 走同一套 form / page，不要 detent。模块 View、折算、取数都不为 Mac 改。

**Mac 的弹出面自己画头尾。** Mac 的 sheet / popover 没有导航栏：iOS 塞进导航栏的标题会带着一截空 inset 漂在顶上，关闭钮会被系统甩到另起的一条底栏，和主按钮叠成两层。所以 Mac 上标题走 `meterSheetTitle`（列头同一套字号、左沿对齐分组卡），底栏是右对齐的一行：左边「取消」（Esc）、右边主操作（Return、按文字收宽，不是满宽药丸）；没有主操作的面右下一颗「完成」。Features 里关 sheet 一律 `meterSheetClose`，标题一律 `meterSheetTitle`，iOS 上它们就是系统 X 和 inline 导航标题。`expandable` 档的 sheet 在 Mac 按内容长高（窗口装不下再滚），不要一张固定高度的窄条把档位切一半。Form 自己的系统画布藏掉，和 sheet 底色不再拼成两截。

**Mac 的列内推进不走系统栈。** split 的 detail 里 `NavigationStack` 一 push 就接管整个主区：列表列卸载、返回和搜索框跑进窗口顶栏，窗口还会长出一条工具栏把列头压下去。服务页「添加服务」和「手动订阅」推详情列的手工栈（`MacColumnStack`），左边列表留着，从右平移进来，标题和返回在列头。仪表盘的构成 / 较上月同期 / 服务详情同样推列内手工栈：模块行和详情页里的路线链接一律 `DashboardRouteLink`（iPhone / iPad 回落系统栈的 value 链接），标题和目的地由 `DashboardView` 统一解析。添加页的搜索框画在列顶（`meterColumnSearchable`），不进窗口工具栏。筛选 popover 挂在筛选钮上（箭头指着它），宽度钉死、高度封顶（`macPopoverWidth` / `macPopoverMaxHeight`）。

---

## 05 仪表模块

仪表页是一列卡片，每张回答一个问题。**可排序、可隐藏**：右上角「编辑」开关模块、拖动排序（Mac 也可右键上移 / 下移），落在偏好 `DashboardLayout.order`（开着的模块 id 按顺序；空 = 没编辑过，用默认）；没数据时自动不显示。第一块永远是本月合计，不进编辑列表；构成在英雄区里，能关但不能挪。新装只开前六块，后七块是可选项。手机上相邻的「需要注意」模块并成一节，其余模块各自一节、节头是模块名；宽壳上各自成卡，「服务一览」一家一张卡。宽壳的卡是**定高定宽的 bento**：一行同高（标准 / 矮两档），宽按 0.25 步进的格数（构成一格半，其余一格），一行没排满时最后一张顺延填满；每张卡顶上有一个「一眼要看到的数」（`DashboardCardHeadline`，和较上月同期那颗百分比同一副字），列表和图表是它的展开。加新模块不用改架构：加一个 `DashboardModuleID`、一份内容 + 构造器、一个 View，注册到 `DashboardModuleFactory`。版式随迁移包走。

| 模块 | 回答什么 | 数据来源 | 阶段 |
|---|---|---|---|
| 本月合计 | 从量（用量 + 预充值消耗 + 超额）+ 预计月底；订阅单独一行 | 折算结果 | M1 |
| 构成 | 从量花在哪家。订阅不进饼图。点卡推进构成页 | 折算结果 | M1 |
| 较上月同期 | 从量比上月同一段日子多/少多少 | 折算结果 · 纯算术 | M1 |
| 近几个月 | 最近几个整月的从量柱 | 每月重算一次折算 | M1 |
| 异常 | 哪家涨得反常 | 对比上月同期 · 纯算术 | M2 |
| 余额告急 | 预充值还能撑几天 | 余额 ÷ 近 7 日均速 | M2 |
| 即将扣款 | 未来 7 天要扣哪些订阅 | 年付首次扣款日；API 快照上的扣款日。手动月付不记扣款日，不进这一块 | M2 |
| 免费额度 | 哪家快超了 | 额度使用比例 | M2 |
| 服务一览 | 钉出的几家各花了多少、较上月、近 6 个月走势 | 构成 / 对比 + 该账号自己的快照 · 编辑里选账号 | M2，默认关 |
| 固定订阅 | 单月：折算每月多少、几笔、下一笔什么时候扣。多月：这段时间实扣多少，列窗口里扣过的每一笔 | 订阅表；单月年付按 12 摊，多月按扣款月计入 | M2，默认关 |
| 日历热力图 | 哪天花得多，一格一天，可翻到有按天读数的月份 | `dailyUSD` 跨账号按天相加 | M2，默认关 |
| 按类别构成 | AI 推理 / 托管 / 数据库…… 各占多少 | 构成段按目录里的 `ProviderCategory` 收段 | M2，默认关 |
| 本月之最 | 涨得最多、占比最大、最久没刷新的那家。节标题跟着取景框走 | 对比 / 构成 / 接入状态 | M2，默认关 |
| 预算线 | 本月合计花了预算的几成 | 编辑里设的月预算（美元） | M2，默认关 |

> **一条约束**：模块只做**展示**，模块自己的设置（钉哪几家、预算多少）都在「编辑」那一面，不在模块上。点一下进对应的追查页。构成卡从右侧推进构成页，列出各家金额，再点进这家详情。较上月同期同样从右侧推进对比页：柱和涨跌幅把缺同期的本月金额算进去；缺同期的仍列在「还不能对比」，行上不当 $0、不编百分比。能比的家若有上月同期明细（同窗口内刷到过的子服务行），细则一并对比：右侧涨跌幅，第二行写两头金额——不要在一行里挤三个数。没有同期明细的子行只写本月。不要就地展开，不要另开 sheet。较上月同期只看从量，订阅不进这两张方卡。近几个月缺的月份留空，不要补 $0。近几个月那张方卡不是追查入口。
>
> **取景框不是本月的时候，所有「本月」字样都要跟着改。** 默认视角才写「本月」：限定语是空的，不写就不知道说的是哪一段。七月、近 3 个月、今年至今、有数据以来——期间已经在标题和筛选条里。
>
> - 大数字底下、日期范围上面：算进订阅时写一行「（订阅 $X）」；关掉就不出现，也不写「已计入 / 未计入」。多月的日期前面不要「合计」。
> - 「有数据以来」不要写成「全期间」——那不是中文。必须标出从哪个月起，免得被读成「我这辈子在云上花的钱」。
> - 固定订阅卡：单月仍回答「那个月每月固定要出多少」（年付按 12 摊）；多月改口，列窗口里扣过的每一笔、合计是实扣，和首屏那行同一个数。已经退掉但窗口里扣过的也要在。下一笔只在窗口压着今天时出现。
> - 「之最」的节标题跟着期间走：「本月之最」「七月之最」「近 3 个月之最」。多月没有可对比的「涨得最多」（同期窗口加起来是错的，宁可没有）。「最久没刷新」说的是此刻，回看过去月份时不出现。

---

## 06 接入向导

这是这个 App 最有价值、也最花工夫的部分。这类工具真正的流失点不是界面不好看，是用户卡在"AWS 到底要给什么权限"然后放弃了。

每家 provider 带一份结构化的接入指南：

```swift
struct SetupGuide {
  summary: String              // 这家是什么。简介页正文
  parts: [SetupPart]           // 一段 = 要准备的一样（或一起诞生的几样）东西
  verifyHint: String           // "这个数字应该和你后台看到的一致"
  troubleshooting: [ErrorCase] // HTTP 状态码 → 人话解释 → 怎么修
}

struct SetupPart {
  fields: [Field]              // 这一段拿到什么；凭据页的顺序跟着它
  steps: [Step]                // 怎么拿到。要粘贴的原文（IAM JSON）贴在对应那一步下面
}
```

计费模式和支持情况**不进目录**：它们是 `ProviderDescriptor.kind` / `accessStatus` / 有没有 live `BillingProvider`，编译期就知道。支持情况分四档：完全支持（live 且 `available`）、理论支持（live 或 `pendingVerification`）、读数信箱、暂不支持。完全支持不写注释。理论支持写「我们没正式测过，接入说明可能写错。能接上的话，试试看。」——不要写成刷新花钱。刷新花钱是 `costsMoneyToRefresh`，只在添加列表 caption 里出现。AWS 走 Cost Explorer，是理论支持，不是读数信箱。

进门只有简介。教程和连接是详情里接用量时才走的两步，不要在添加时问「订阅还是用量」。

### 四条设计规则

1. **深链到创建页，不是首页。**「打开 Cloudflare」跳到官网首页等于没帮忙。创建页的入口嵌在步骤句子里（「Cloudflare 控制台」这种），不要再单独放一个「在浏览器中打开」。可点的是这段字，地址来自编译死的 `credentialSetupURL`（或步骤 `linkTarget` 对应的 `guideURLs`）——目录只标哪几个字可点，绝不带 URL。safari 符号贴在可点字**前面**。目录按 locale 分列时，每个语言自己的句子配自己的可点片段，和加粗的做法一样。
2. **凡是需要手抄的东西都给复制按钮，贴在那一步下面。** AWS 的 IAM policy JSON 这类要粘到控制台的原文。不要另开一节「需要复制的内容」。手抄 policy JSON 是错误率最高的一步。权限写进步骤正文，不要再单独渲染一块「最小权限」。读数信箱的环境变量名写进步骤正文即可，不要单独渲染一块复制块——真正的投递 key 在连接页才签发。
3. **测试连接要显示真实金额。** 不是显示"✓ 成功"，是显示"本周期至今 $11.05"。这一步同时验证了凭据和折算逻辑。
4. **错误必须具体。** 不是"连接失败"，是"这个 token 缺 Billing:Read 权限，回上一步重新创建"。`403` 和 `401` 是完全不同的问题，不能合并成一个提示。

### 已经确认的关键信息

- **Cloudflare** — Custom token，只需 `Account · Billing · Read`。还要 Account ID。
- **AWS** — IAM 只读用户，policy 只需 `ce:GetCostAndUsage`。这段 JSON 必须可一键复制。
- **OpenAI** — 必须是 **Admin Key**。在 organization 设置里签发。权限选 **Read only**，不要 All。
- **Anthropic** — 必须是 **Admin API Key**，且要求组织账号。个人账号在这一步会直接卡死，向导里要提前说明。
- **GitHub** — Fine-grained PAT（`github_pat_`）。Expiration 选 No expiration，Repository access 选 Public repositories，Account permissions 把 Plan 开成 Read-only。没有 Billing 这一项。用户级账单只覆盖 Actions 分钟和自购的 Copilot。
- **Neon** — 组织 Settings → API keys，Key scope 选 Org-wide。没有只读选项，这把是组织级管理员权限。
- **Vercel** — Account Tokens，SCOPE 选付账的那个团队，不要点进项目。没有只读权限。Hobby 没有发票，读数是 $0。
- **CockroachDB Cloud** — Service Accounts 签发 secret key，Edit Roles：Scope Organization，Role Billing Coordinator。免费期间发票列表为空，读数是 $0。
- **Fly.io** — GraphQL 没有本月花费。走读数信箱；Launch 档固定费走手动订阅。
- **Google Cloud / Slack / Notion / Figma / Supabase / Linear / Pulumi Cloud** — 没有公开账单金额接口。走读数信箱；固定订阅走手动订阅。Google Cloud 没有一份可自助选的固定席位 SKU，只记用量。

---

## 07 手动订阅与在线目录

### 为什么手动订阅是必需的，不是附加功能

API 用量是 `$47`，但如果有 Claude Max、ChatGPT Plus 这类订阅，那可能是 `$200+`。**一个漏掉订阅的账单不是不完整，是错的。**

仪表主角数字是**从量**（这个月云在烧多少）。算进订阅时，日期范围上面一行「（订阅 $X）」；关掉这行不出现。Widget 在「算进固定订阅」打开时仍用含订阅的合计——锁屏只有一个数字，漏掉 Max 就是错的。关掉之后 Widget 和分享的合计也不再含它。

字段：名称（可从目录里选，也可自己输）、金额 + 周期（月/年）、归属（这家厂商，可选挂到某一份用量身份）。月付多一个「开始时间」，选年月——从那一个月起每个日历月全额计入，更早的月份计 0。年付多一个「首次扣款日」，用来落到哪一个月。目录里每条预置档位已经带 `period`，抽屉先选月付/年付，再只列对应档位。

**还有一个「结束时间」**，落库同样只取年月，可空。有起点没终点的模型撑不住真实生活：退订之后那笔钱会一直扣下去，
而唯一的出路——删除——会把它从过去每一个月的合计里一起抹掉。结束月当月仍全额计入（那个月确实付了），
下个月起计 0。这不是订阅管理功能，是让总数不说谎的最低要求。

一笔订阅因此是**一段区间**，而不是一个开关。同一个产品可以有好几段（订过、退了、又订回来），
每一段一条记录——所以 Android 那张 `subscriptions` 表的主键必须是行自己的 id，不能是名字。

从某家详情加的订阅，归属就是这家。添加服务里的「手动订阅」给还没加进来的厂商、或目录里没有的工具。已经加过的厂商，订阅从详情进，不要在主列表再堆一节「手动订阅」把 ChatGPT Pro 和 OpenAI 拆开。Cursor 没有公开账单接口，加进列表之后只记固定订阅，超额用量手填。

> **红线：不要变成订阅管理 App**
>
> 不做续订提醒、不做闲置检测、不做涨价历史、不做银行账单导入、不做 logo 图库。我们只需要一个数字进总额。

### 在线目录：哪些东西不该编译进 App

最值钱的内容不是套餐价格，是**接入说明**——各家控制台改版才是高频破坏。

| 内容 | 放哪 | 为什么 |
|---|---|---|
| API base URL / 请求构造 / 解析逻辑 | 编译进 App | 凭据要发到这些地址。远程可改 = 凭据可被引走。**安全红线** |
| 控制台 URL | 编译进 App | 远程可改的跳转地址 = 钓鱼登录页 |
| 接入说明文字 / 步骤 / 权限名 / 排错 | 在线目录 | 控制台改版最频繁，这是目录的主要价值 |
| 订阅套餐目录 | 在线目录 | 厂商调价时不用发版 |
| 公告 | 在线目录 | 能在向导里提前拦住用户 |
| 回看几个月（`historyLookbackMonths`） | 编译进 App | 它进**请求构造**（回填历史时问对方要多久的数据），和 base URL 同一列。远程可改 = 远程能让 App 去拉一段不该拉的窗口 |
| 档位理由（`tierReason`）、搜索别名（`searchKeywords`） | 编译进 App（现状） | 是文字，按上面第三行本该在线；没搬是因为 `ProviderCatalog` 是**静态表**，五个壳和生成物都直接读它，让它变成"要先解析目录才知道这家叫什么"是另一件事。要搬先决定 `ProviderIdentity` 那份生成物怎么办 |

> **安全红线**：目录只能携带文字和数字，**绝不能携带任何 URL 或端点**。

> **同一家的事实只写一遍。**「要哪几把钥匙」是唯一真的双写：适配器里
> `RequiredCredential.value(.apiToken, …)` 说取数要什么，目录教程的 `fields[].key`
> 说向导问什么。两边对不上，用户会走完整个向导再在连接测试那步撞上「缺凭据」，
> 而那句话指不出缺的是哪一把。`check_credential_fields_match_guides` 守这条。
> 其余跨文件重复（显示名 ↔ `shared/providers.json` 的 `name`、`accessStatus: .declined`
> ↔ `offered: false`、`tierReason` ↔ `ProviderIdentity`）都是**生成物**，
> 权威在 `ProviderCatalog.swift`，生成器和闸各扫一遍。

```swift
struct Catalog {
  schemaVersion: Int              // App 只认得 <= 自己支持的版本
  updatedAt: Date
  guides: [ProviderID: SetupGuide]   // 只有文字
  plans:  [SubscriptionPlan]         // 名称 + 价格 + 周期
  notices: [Notice]                  // 向导里的提前提醒
}
```

加载规则，三层兜底，失败静默：

1. **打包副本。** App 里始终带一份完整 `catalog.json`。第一次安装、缓存坏了、远程 schema 太新，都退到这里。
2. **上次拉成功的。** 写在 App Group 里。冷启动和 Widget 立刻用它——比打包新才用。
3. **网上最新。** 启动后台打一次编译死的 `https://api.tollcat.app/v1/catalog`。成功且 schema 认得，写入缓存并换上；失败不弹错。

`schemaVersion` 超出版本则整份远程丢掉，不写进缓存。目录更新永不影响已存凭据和历史数据。汇率跟着目录走，不另开牌价接口。

地址编译在 `CatalogEndpoint`，不进目录正文。Worker 上的 `catalog.json` 是打包那份的符号链接——部署 Worker 等于把同一份说明和汇率推给已装机的 App。

接入说明是数据，跟着 `catalog.json` 更新，**不进** App 的 String Catalog。

`schemaVersion` 仍为 2。中文是规范字段（`text` / `summary` / `verifyHint` / …）。`en` / `ja` 是 overlay：和规范字段同形的一小段。老 App 忽略未知键，远程目录不会因为多了两列被整份丢掉。

**打包目录必须三语列齐。** 教程、简介、排错、字段提示、套餐名、公告，en / ja 缺列就是没做完，测试卡住。运行时碰到旧缓存缺列才回落中文（源语言，不回落英文）——那是兼容，不是翻译策略。

步骤的句子、加粗、可点片段是一套：有 `text` 的 overlay 必须自带 `emphasized` / `linkPhrases`，不跟中文混拼。加一门语言只加一列 overlay，不升 schema。URL 仍然不许进目录。

---

## 08 不用模型

这一节曾经写的是「设备端 AI 总结」。真机试过之后整条路线撤了，见第 12.5 节。

TollCat 里没有任何模型调用，云端和设备端都没有。首屏那句猫说话由写死的候选句和
算好的事实决定，同一份账单每次说同一句。

---

## 09 Widget

这是这个 App 值得做成原生的核心理由。你不需要"打开 App 查账单"，你需要被动地知道数字在涨。

三种尺寸，结构不同，不是把中号拉伸。数字是未筛选的本月账单（含订阅）。猫是月份行右上角的角标，不和数字并排成一列。

- **小号**：caption 月份 / 总额 / caption 预计。没有构成条。
- **中号**：月份 / 总额 / 预计 / 底部 5pt 构成条 / caption 上次刷新相对时间。
- **大号**：中号那些，加上按厂商卷的构成行（超过 5 家合并成「其他」）。构成条和图例用同一套系统色，不是品牌色。

Mac 桌面 / 通知中心用同一组 systemSmall / Medium / Large。不要做 accessory（锁屏）家族。菜单栏不是 Widget 家族，是主 App 的 `MenuBarExtra`，只读主 App 上次写下的数。

> **第一天就要定的技术约束**
>
> **Widget 不能自己调 API。** 后台刷新时机由系统决定，不可靠；而且 AWS 每次请求要钱，让系统随机触发不可接受。
>
> Widget 只能读主 App 上次刷新写下的数据。这意味着 **SwiftData 容器必须放在 App Group 里**，主 App 和 Widget Extension 共享同一个 store。**这个决定后期再改会很痛。**
>
> **不做 Live Activity。** 它是给有明确起止的事件用的，月度账单不是。

---

## 10 数据模型与刷新

```swift
// 静态配置，随 App 走
struct Provider {
  id, displayName, kind, accentColor
  billingURL           // 详情页跳转的官网账单页
  setupGuide           // 见 06
  costsMoneyToRefresh  // AWS = true，决定是否进全局刷新
  minimumRefreshInterval // 秒。对方按天限流、或数据按天才更新的家 > 0
}

// 每次刷新写一条，永不删除 —— 趋势图的唯一数据来源
struct Snapshot {
  providerID, fetchedAt
  periodStart, periodEnd       // 该 provider 自己的计费周期
  currentSpendUSD:     Double?    // 本周期至今（用量后付费）
  balanceUSD:          Double?    // 剩余余额（预充值）；多钱包时是折美元合计
  committedMonthlyUSD: Double?    // 月费金额（固定订阅）
  chargeDayOfMonth:    Int?       // 扣款日（固定订阅）
  freeQuotaUsedRatio:  Double?    // 0…1（免费额度内）
  dailyUSD: [Date: Double]?    // 有日粒度的家才填
  wallets: [ConvertedAmount]?  // 预充值多币种钱包。账本仍只认 balanceUSD
}

// 折算结果，每次刷新后重算，不入库
struct MonthToDate {
  totalUSD, projectedMonthEndUSD
  confidence: .exact | .estimated | .partial
  estimatedProviders: [ProviderID]   // 用来解释哪几家是估的
  facts: [Fact]                      // 结构化事实，猫说话和解释文案都读它
}
```

### 凭据存储

- API Key 存 Keychain，`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`——不进 iCloud Keychain，不跟备份走
- SwiftData 只存 Keychain 引用标识，不存密钥本身
- 删除 provider 时同步删 Keychain 条目

### 刷新策略

- 全局刷新：并发拉取所有 `costsMoneyToRefresh == false` 的 provider
- AWS 单独按钮，文案写明"约 $0.01"
- `minimumRefreshInterval > 0` 的家（对方按天限流、或数据按天才更新）：自动刷新和手动下拉都跳过间隔内已成功的账号。接入测试和「拉取更多历史」仍打。撞到对方上限走 429，文案写清要等多久
- 单家失败不影响其他家。失败的行显示上次成功的数据 + "数据陈旧"标记，**不显示 0**，更不让总数悄悄变小
- 永远不做后台轮询、不做定时刷新

### 首次接入时的历史回填

接入一家时拉一次能拿到的历史（AWS 12 个月，Vercel 最长一年，OpenAI 按日），写成历史 Snapshot。不回填的话第一次打开看到的是空图。

---

## 11 里程碑

按"能验证最大风险"排序，不是按"哪个简单"排序。

| | 内容 |
|---|---|
| **M0** | **脚本先行 · 不开 Xcode。** 写脚本把八家 API 各调通一次，金额和各家后台逐一对账。同时验证 Anthropic 的组织问题和 Fly.io 的 GraphQL。配 key 的每一步都截图记下来——这就是 06 里 SetupGuide 的内容。 |
| **M1** | **两家 + 手动订阅 · 仪表 + 服务 + Widget。** 接 Cloudflare（用量后付费）和 OpenAI（预充值余额），加上手动订阅——三种"钱"凑齐，总数才是真的。三个 tab 的骨架、本月合计和构成两个模块、完整的接入向导、中号 Widget。目录从 `Bundle.main` 读，不联网。**装到自己手机上，用一周。** |
| **M2** | **补齐 provider 与模块。** Neon → Vercel → GitHub → AWS（最后，要花钱且逻辑最特殊）→ Fly / Anthropic。同时补异常、余额告急、即将扣款、免费额度四个模块——全是算术，不碰 AI。目录切成远程加载。 |
| **M3** | **详情页 · 打磨。** Provider 详情页和趋势图、空状态、错误态、App 图标。 |

> **M1 的意义**：M1 结束时手机上就有能用的东西了。如果那一周没主动打开过它、Widget 也没让你看一眼——说明产品假设不成立，及时停，别做到 M3。

---

## 12 开源的边界

- README 第一行：**个人自用工具，PR 欢迎，不承诺支持，不承诺加新 provider**
- 不开 issue 模板，不写 roadmap，不承诺响应时间
- 集成腐烂是这个品类的常态。自用时坏了自己修

---

## 12.5 实现期补充的决策

这一节是实现过程中规格没覆盖、由验收方拍下来的口径。它们和上面正文同等有效。

### 预计月底怎么算

订阅部分**不外推**（钱已按扣款日全额计入），只对用量与预充值消耗做
`本月至今 ÷ 已过天数 × 当月天数`。已过天数取 `now` 的日历日；分母是当月实际天数，
不写死 30。设计稿上的 `$94` 是示意数字，不要求凑。

### 扣款日超出当月天数 → 钳到当月最后一天

订阅扣款日写的是 31，2 月没有 31 号。**计入全额，按 2 月 28/29 日算，不是计 0。**

理由在第 07 节：厂商确实会在月末那天扣款，计 0 等于让 2 月的总数悄悄漏掉一笔真实支出，
而"一个漏掉订阅的本月总计不是不完整，是错的"。宁可日期差一天，不可金额少一笔。

### Snapshot 带 kind

`Snapshot` 增加 `kind: ProviderKind` 字段，第 10 节的字段表以此为准。两个理由：

1. **防双计。** 一条 snapshot 同时填了 `balanceUSD` 和 `currentSpendUSD` 会被算两次。
   有了 kind，折算时按 kind 只认该认的那个字段。
2. **历史保真。** Snapshot 永不删除。某家 provider 以后从"免费额度内"变成"用量后付费"
   （Vercel 很可能），历史快照必须保留它当时的 kind，否则重算历史会错。

### 快照压缩策略：13 个月以前，每账号每月只留最后一条

「永不删除」是**读取契约**（趋势图能重算历史），不是**存储契约**。两条放在一起
是无界增长：每家每次刷新落一条，能回看的只有 12 个月（`DashboardPeriod.maxMonthsBack = 11`
再加当月），于是 13 个月以前的行**任何一屏都读不到**，却一直占着那张表。
一个刷得勤的用户两年后是几万行，而那时候再想加压缩，就要对一张写满真实历史的
表写迁移，还要说服自己「删掉的那些确实没人要」。

**1.0 必做**，实现在 `MeterPersistence/SnapshotCompactor.swift`。

（这条曾经写着「实现可以晚」。那句话建立在「写侧已经和刷新次数脱钩」的假设上，
而那个假设当时不成立——写侧每天要整份重折一次、每次刷新取该账号全史。两件事叠起来
就是无界增长，所以两边一起做完了。）

- **保留窗口 = 能回看的月份 + 1 个月**。窗口内一条都不删——月内的多次刷新
  是日表压平和「最新一条带明细的是哪条」的依据。
- **窗口以外，每（账号，月）只留 `fetchedAt` 最大的那一条。**留最后一条而不是
  第一条：账期累计型的家（`currentSpendUSD` 是本月至今）最后一条才是那个月的终值。
- **这里的「月」= `fetchedAt` 所在的月，不是账期所在的月。** 两者对绝大多数读数是同一个
  （刷八月的数，取数时刻也在八月）；只有**补录**会岔开——九月给八月手填一笔，它的
  `fetchedAt` 在九月、`periodStart` 在八月，按这条规则归进九月那一组。
  取 `fetchedAt` 是因为窗口本身就按 `fetchedAt` 切（那一列上有索引），两处用同一把尺；
  也因为「下界之前最近的那一条」（`SnapshotLog.latestBefore`，预充值的月初锚点）
  是按 `fetchedAt` 挑的，按取数月分组能保证它一定还在。
  **代价写在这里，不要以为是漏的**：同一个取数月里若既有补录又有当月读数，补录那条
  会因为 `fetchedAt` 较早而被删掉。这只发生在 13 个月以外——那些月份任何一屏都读不到，
  手填本身也另存一份在 `ManualUsageRecord` 里。真要改成按账期月分组，先回来改这一段。
- **压缩不改语义。**压缩之后重折账本，那些月份的数字必须和压缩前逐项相同——
  `LedgerSelfCheck` 就是验这件事的工具，压缩实现落地时要拿它对一遍。
- **手填和信箱来的读数一视同仁**（`source` 不进判据）：它们和 API 读数在
  存储上是同一份合同，见第 12.5 节「三种输入」那条。
- **压缩是本机行为，不进迁移包**（迁移包本来就不带历史快照）。
- **先折后删。** 压缩排在同步之后（`LedgerSync.compactIfDue`），一天最多一次；
  删除和作废戳在**同一个事务**里——戳留着的话下一次开门会拿一份「按更多读数折出来的」
  账本当数。

窗口大小的唯一出处是 `DashboardPeriod`（`SnapshotCompactor.windowMonths`），
别在压缩实现里再写一个数字。

### `≈` 号已从产品整体移除，confidence 只算不标

演进过程：先是首屏去掉 `≈` 改用"含估算"小字，后来首屏连小字也去掉，最终决定
**`≈` 这个符号从整个产品移除**——Widget、分享卡、VoiceOver 里也不再有约等标记，
模型层带 confidence 的金额格式化入口（`Money.formatted(confidence:)` 等）已删除。

理由：用户打开任何一屏都是想知道"花了多少"。"其中几家是估的"属于**追查时**才需要
的信息，摆在金额旁边是噪音——而这个 App 的整个设计前提是一眼看完。

**但 confidence 本身不许消失**：

- `MonthToDate.confidence` 照旧计算，`estimatedAccounts` 照旧记录
- provider 详情页按家展示精度（追查时在那儿看）

也就是说，规则从"必须在 UI 可见"降级为"必须可查"。**这是一次有意的降级，不是遗忘。**
如果哪天发现总数和真实账单对不上、而用户没有线索去查，就该把可见标记加回来。

### 本地定时提醒可以做，推送告警仍然不做

第 01 节写着"不做推送告警"，理由是推送需要服务器。**本地通知不需要服务器**
（`UNUserNotificationCenter` + 本地 trigger，连 entitlement 都不用），
所以它不违反那条前提。

可以做：**用户自己开的定时提醒**——"每周提醒我去看一眼这个月花了多少"。
纯本地调度，App 不运行也能响。

仍然不做：**任何基于金额的告警**（"AWS 超过 $50 通知我"）。那需要在 App 不运行时
知道当前金额，也就需要后台取数或服务器推送。后台取数在 AWS 上每次要钱
（第 03 节），服务器推送会让项目变性质。**Widget 继续承担"被动看到数字"这个职责。**

### 通知里不放金额

通知触发时 App 没在运行，能拿到的只有上次刷新的旧数字。在通知里显示过期金额，
正是整个规格在防的那种"数字不可信"。

所以提醒文案只说"去看看"，可以带**事实性**的补充（"上次刷新 3 天前"），
不带任何金额或百分比。设置里那句说明写「设定猫猫何时通知你来 App 里面刷新一下用量」。

### api.tollcat.app 是唯一的服务端组件，它的边界必须钉死

第 01 节写着"无后端"。打赏留言、反馈、读数信箱、在线目录、匿名使用计数
都要有一个接收端，所以现在有了一个 Cloudflare Worker。**这是一个明确的例外，
不是前提的松动。** 一个 Worker 承担全部 endpoint，不要再部署一个。

边界（不可协商）：

- 它**永远不接触账单凭据、不接触账单数据、不代理任何 provider API**
- 现在允许的内容就这些：打赏留言、应用内反馈、公开接入目录（文字 / 套餐 /
  汇率，不含 URL）、读数信箱、**匿名页面计数**
- 匿名页面计数只收：平台（ios / android）、UTC 日是否第一次打开、允许名单里的
  页面名、各页进入次数。不收账号、广告标识、设备指纹、时区、locale、机型、
  账单、凭据、厂商名字。服务端只加总计数，不留事件流水，不留 IP
- App 侧调用它的代码放在**独立的叶子模块**（`MeterTips` / `MeterInbox` /
  `MeterFeedback` / `MeterUsage`）里，`MeterProviders` 永远不链接它们——
  和 Widget 不链接 `MeterProviders` 是同一个手法：用依赖图把"不该发生的事"
  变成编译不过

为什么要写这么死：一旦项目里存在一个"我们自己的服务端"，最省事的下一步永远是
"把取数也放上去"。那样凭据就出设备了，整个 App 的隐私前提当场作废。
**有服务端 ≠ 可以用服务端。**

### 创建 key 的深链是 descriptor 的字段

第 06 节第一条规则要求"深链到创建页，不是首页"，第 07 节的安全红线又禁止任何 URL
来自远程目录。两条一夹，结论只有一个：**`ProviderDescriptor` 必须同时有两个 URL**。

- `billingURL` —— 官网账单页，详情页"去官网处理"跳这里
- `credentialSetupURL` —— **直达创建 token 的那一页**，向导步骤里的行内链接跳这里

两个都编译进 `MeterProviders`，都不进 catalog。catalog 里只有说明文字。
不接入（`accessStatus == .declined`）的家产品列表会滤掉，可以没有这两个 URL。

（这是实现时才暴露的漏项：只给了 `billingURL`，导致向导只能跳账单页，
第 06 节第一条规则无法实现。）

### "有没有读到金额"只能有一份定义

`Snapshot` 判断"这条读数算不算数"的规则（`hasBillableMetrics`）是 `MeterCore` 的
公开 API，展示层直接用，**不许在别处复制一份同规则的实现**。

理由：这条规则决定了一次失败的取数会不会被当成 $0 计入总数。同一个判断存在两份，
迟早会分叉，而分叉的后果是界面显示的和总数算的不是同一回事。

### 年付订阅必须记到"哪一个月"，不能只记扣款日

年付不能只记「几号」。只有日、没有月，就会被**每个月**全额计一次——一笔年付 $200 的订阅
一年会被算成 $2400。这正是整个 App 想避免的那种"总数不可信"。

所以两种周期都存 **`anchorDate: Date`**。年付是首次或上次扣款日（取月+日）；月付只取年月，不问几号。同一条记录，折算用传入的 calendar 拆分量。

- 月付 → 开始月及之后每个日历月全额计入；开始月之前计 0。不问扣款日；「即将扣款」也不列手动月付
- 年付 → 取它的**月 + 日**，只有周年月计入全额，其余十一个月计 0。还没到首次扣款那个月的，计 0

红线（不做续订提醒、不做涨价历史）不变。UI 上月付问「开始时间」，选年月；年付问「首次扣款日」，选完整日期。

### 手填花费（无公开接口的家）

没有公开账单接口的家，不能把「本月至今」录成固定订阅——订阅按扣款日整笔计入，用量是日历月累计。手填、读数信箱、官方接口刷新是**同一份快照合同的三种输入**：每次都写一条 `Snapshot`，永不删除。每个月合计取该月最新一条，和 Cloudflare 刷新后数字会变是同一件事。

图跟 `kind`，不跟输入面。Fly 和 Cloudflare 都是用量，7 / 30 天都是花费柱，缺天留空。Cloudflare 的柱来自按日拆开的账单；本月之内的手填，柱改成「上次读数到这次新花的钱」，记在读到的那天。不是另一种图。12 个月仍是每月一根柱，取该月最后一次。事后补填的过去月份只进这张月图，不要在 7 / 30 天柱上冒出来——那不是「读到那天」的观测。

其余：

- `currentSpendUSD`：本月是填写当时的至今累计；过去的月份是那一个月的合计。不是当天、不是预估月底
- 选年月，不要选日。周期是所选月 1 号到月末。能填的范围和 12 个月图对齐（含本月共 12 个）
- 同月再填是新观测，不另开用量身份；跨月上月那些观测不算进本月。过去的月份可以事后补，12 个月图才有柱
- 只给没有官方接口的家（`supportsInboxIngest`）。有 API 的不许开这条，避免把人从好路推到坏路
- 不声称和官网后台对账。confidence 按估算处理
- 脚本后到、读数更新，合计改看最新那条；历史手填快照仍留着

手填是用户断言，不是缓存。每个月**最新**那一条进跨设备迁移。用量身份可以没有 API、也还没接信箱；这种身份不参与刷新。

空态不要两颗对等主按钮。填数是主操作，任务书是次要。

### 手动订阅与 API 订阅撞车时，以手动录入为准

同一个 provider 既有 `.subscription` 类型的 snapshot，又有归属到它的手动订阅时，
**只计手动录入那一笔**，snapshot 上的 `committedMonthlyUSD` 不计入，并在
`facts` 里留一条标记说明它被取代了。

理由：用户手动填的金额是他明确断言过的，错了他自己能改；而一条被静默忽略的手动
录入在界面上看起来就是个 bug。服务页要明示"这家的订阅金额以你手动录入的为准"。

（`.subscription` snapshot 没带扣款日时仍计当月全额——它本来就是一笔月费，
只是不知道哪天扣。这是有意为之。）

### Fact 是结构化数据，不是中文句子

`Fact` 只带 providerID、kind、金额、对比值这类**结构化字段**，不带拼好的中文。

理由：领域层生成用户可见文案本身就越界了。同一条 `Fact` 要同时喂给首屏猫说话、
构成页和分享卡，各自的措辞不一样；把中文拼死在 `MeterCore` 里，三处就只能共用一种说法。
渲染句子是展示层的事。

### 仪表模块的编辑在仪表页，不在设置页

排序、隐藏走仪表页右上角「更多」菜单里的「编辑仪表盘」（一个 sheet），分享同一处。
不进设置页，也不在页尾再放胶囊：这是在摆自己的仪表盘，不是在配置 App。
曾经因为只有六块而把这组 UI 收掉；现在模块有十三块、七块默认关，
没有编辑就没法加。

编辑面改了就生效，没有草稿。三节：显示中（可拖动排序，Mac 也可右键上移 / 下移）、
更多模块（开关）、以及开着的模块自己的设置——「服务一览」钉哪几家账号、「预算线」多少钱。
持久化是 `AppPreferencesRecord.dashboardLayoutJSON`（整份 `DashboardLayout`），进迁移包。

### 撤掉端侧模型

首屏那句猫说话一度交给端侧小模型来挑：候选句我们写死，模型只回一个编号。真机试下来，
这条路线的收益撑不住它的代价，已经整条撤掉。

试过的失败面记在这儿，免得再走一遍：端侧小模型做三语短创作的水平是语法不通、凭空编
情节、金额丢掉货币符号，甚至说出「猫赚了钱」「花得最多的是 AWS」这种事实错误。语法
胡说和事实胡说都没法用校验器可靠拦下来——长度合格、数字合格、没有引号的句子，任何
字符串校验都会放行。改成「只挑不写」之后句子安全了，但模型能贡献的只剩「这个月哪件
事最值得说」这一个判断，而它换来的是：一条要写进隐私政策的设备端模型条款、设置里一个
只在部分机器上出现的开关、以及一条永远只有一部分用户走得到的代码路径。

现在的做法：`CatSpeechFallback` 按算好的事实排出候选句，取第一条。同一份账单每次说
同一句，三语各自成文，没有开关，也没有降级路径。

### 对外名字是 TollCat

显示名、开屏、猫、打赏文案、Xcode 工程和 target、bundle id、App Group、Keychain service、迁移文件 UTI、内购产品 ID，都走 TollCat。

Swift 包模块仍叫 `MeterKit` / `MeterCore` / `MeterDesign` 等。那是分层合约，不是货架上的名字；改模块名会碰到每一份 import，没有产品收益。

### 设置 tab 留下

排序和模块显隐从设置里拿掉之后，这一页还有外观、显示货币、进入 App 时自动刷新、提醒、读数信箱、导入与导出、打赏、关于。利用指南暂时不摆进设置页。
三 tab 的信息架构不变。不要为了「看起来空」把设置塞进仪表。

设置「数据」那一组的顺序：读数信箱、导入与导出。转移到新设备和从旧设备导入不要再并排两项——合成「导入与导出」，一页两个分段（导出 / 导入）。打开 `.tollcat` 文件时落在导入那一档。**清除全部数据是整份设置的最后一项**，单独一节，下面不要再跟反馈、关于。清完切回仪表空态，标题换成「已清除全部数据」。

`tollcat://settings` 打开设置列表第一屏（提醒、外观都在这一屏）。`/inbox`、`/import`（或 `/transfer`）、`/feedback`、`/about`、`/tip`、`/whats-new` 推进对应页。`/reminders` 也落在第一屏——提醒没有独立页。scheme 和仪表深链共用 `tollcat`，host 分开。

### 利用指南

设置「通用」里有一项「利用指南」。不是接入向导，也不替代首次引导。每篇只讲一个用的时候会看错的点：标题 + 两三句话。

第一版五篇，按这个顺序：

1. 这个数字不含月费
2. AWS 刷新要花钱
3. 换手机，钥匙不会跟着走
4. 没有接口的可以投进信箱
5. 锁屏上也能看到这个月

看过的 id 记在偏好里，跟着跨设备迁移走。旧包没有这个字段，当成一篇都没看过。新篇用新 id，没看过的人冷启动会再弹。

冷启动且已经走过首次引导时，若还有没看过的，从底下弹出一篇（系统 sheet，medium / large detent）。一次一篇，按目录顺序。划掉或点「知道了」都算看过。同一次启动里刚做完首次引导，不弹——下次冷启动再弹。从后台回来不弹。打开 `.tollcat` 迁移文件时不弹。

设置里可以随时回看全部；打开一篇也算看过。列表不标未读。

不要做成 coach mark，不要指着某个按钮。

### 账本按美元，显示货币是另一件事

第 01 节曾经写「汇率换算。全部按 USD」。那条挡住了真实用户：Moonshot (China) 国内站余额是人民币，DeepSeek 国内户也是，Azure / Fastly 按账户所在地结算。

改法拆两层，不要混：

1. **进账本。** 厂商用非美元结算时，按打包目录里的汇率折成美元再合计。换不出来就这次没读到，不要猜。折过的读数按定义是估算。详情页把当时用的汇率写在大数字下面（「（1 CNY = $0.1404）」，右边跟显示货币走）；多钱包仍列出各槽原币。
2. **写出字。** 设置里有一个「显示货币」。默认美元。选人民币、日元这些时，把账本里的美元再折回去写到屏幕上。Widget 和分享卡跟这个选项。账本本身还是美元。

汇率表只许带数字，所以能进 `catalog.json`，跟着第 07 节那三层兜底更新。不要为了更准去联网问牌价。

设置里只对某一行生效的注解，写进那一行（标题下面的次要文字）。不要挂在
`Section` footer——footer 在卡片外面，多行一组时读起来像整组的说明。

「每次进入 App 的时候自动刷新用量」默认关。打开后，冷启动和从后台回到前台
各走一次全局刷新，规则和点仪表刷新按钮相同：花钱才能刷新的服务不进。

服务页一家都没接时，空态只留「还没有接入服务」和「添加服务」。不要再跟
「已经支持 N 家」「添加一家大约两分钟」那两段。

设置「其他」那一组不要再挂「自愿，没有会员，也没有解锁」。

### 没加进来的服务不占服务页主列表

八家全列出来会有一串空行。默认只看已经加进来的。添加走右上角和列表底的「+ 添加服务」，从右侧推进，不要再弹一张抽屉。用量 setup 才用 sheet。
免费额度行只要有用量读数就仍单独成行——那是「离开始收费还有多远」，不是空行。

### 厂商门口和用量身份

`ProviderID` 只表示厂商（目录、品牌、适配器、向导、出站域名）。服务列表一行一个厂商，主键是「加进来了」这份 **成员关系**。

用量身份是 **账号** `AccountID`（UUID）：一把钥匙、一段 Snapshot 历史、一次刷新失败。同一家可以有多份用量，折算、筛选、Keychain 仍按账号——两个 OpenAI org 的预充值月初余额绝不能串。账号不是服务列表的一行。

- 加一家 = 写成员关系。此时可以没有账号。
- 连接用量 = 新建账号、测通、写入 Keychain。第一份补在这家下面；再加一份也从详情进。
- 该厂商只有一份用量且未起昵称时，详情里用量那一行就是厂商名。第二份起昵称必填；已有空昵称预填「账号 1」，两个框出现在测通成功 / 保存前。
- `moonshot` 与 `moonshotAI` 是两个厂商（两套 API），不是两份用量。
- 仪表构成按用量账号切片；Widget 5pt 条按厂商卷。筛选存排除的账号。挂在厂商上、没有用量账号的订阅，筛账号时排不掉。
- 升级会重建本地库。旧接入需要重新加一次。迁移包 schema 1；文件 24 小时过期，所以严格版本相等即可，不做向前兼容——包的寿命比任何一次发布都短，为它维护一套迁移是纯负债。

详见 `docs/design-multi-account.md`。

### 跨设备迁移：用户主动、一次性、加密

凭据是 `WhenUnlockedThisDeviceOnly`，故意不进 iCloud Keychain。换手机不能靠系统同步，
只能靠用户主动发起的一次转移。

通道是系统分享（AirDrop、文件、邮件都行）。**安全性不能依赖通道**，只能依赖文件
本身是加密的。没有明文 JSON / CSV 导出，开发菜单里也没有。

**一次性码是 10 位 Crockford base32**，屏幕上显示成两组五位（`K7M2Q-9XR4T`）。
不要改成 6 位数字。6 位数字只有约 20 bit 熵；文件一旦落到别人手上，攻击者不用管
App、不用管过期时间，离线穷举 10^6 种可能。就算 PBKDF2 拉到 60 万轮，GPU 上也是
几小时的事，而文件里是能直接花钱的 API key。10 位 base32 约 50 bit，离线穷举
不可行，读出来敲一次的体验没有变难。

码只用来派生密钥，不入库、不写日志、不进剪贴板。离开「导入与导出」这一页就没了。导出和导入两档之间切换不要重新生成。

**过期不是密码学保护。** 文件 24 小时后不能再导入，只缩小「误发出去」的暴露窗口。
拿到文件的人离线爆破根本不看过期字段。不许把过期写成「所以是安全的」。

密码学：AES-GCM、256 位密钥；KDF 必须是 PBKDF2-HMAC-SHA256、迭代 ≥ 600000、
16 字节随机 salt。明文头（版本、salt、迭代数、nonce、`notAfter`）整段作为 AAD。
CryptoKit 的 HKDF 不行——它没有工作因子，是给高熵输入用的。

文件扩展名 `.tollcat`，自定义 UTType，头里不许出现凭据，也不许出现 provider 名字。

**装**：接入了哪几家、每家的非密配置、手动订阅、**每月手填用量（每月最新一条）**、偏好设置、Keychain 里的凭据。

**不装**：历史读数和缓存快照。重新刷一次就有了，落地密文越小、装的东西越少越好。手填刷不回来，所以每个月**最新**那一条进「装」，不要跟缓存快照混。

导入：选文件 → 敲码 → 解密 → 校验 `notAfter` → 凭据写回
`WhenUnlockedThisDeviceOnly`、其余写 SwiftData → 触发一次刷新。码输错 5 次开始
退避锁定，这只挡设备上的乱试，挡不住离线爆破。

### 首屏口径切换：大数字旁的「含订阅 / 仅从量」

第 02 节原本的口径是「大数字永远只是从量，订阅单独一行」。现在改成：
**整页只有一个口径，由大数字旁边那颗双段切换决定**，它就是筛选抽屉里
「算进固定订阅」的另一个入口——同一份 `DashboardFilter.includesSubscriptions`，
一起落盘，Widget 也跟这份落盘值（Widget 只跟订阅口径，不跟排除名单和月份）。

- **仅从量**（默认）：等于以前的行为。订阅那行不出现。
- **含订阅**：大数字 = 从量 + 订阅（`totalUSD`），预计月底、
  构成、对比、趋势、分享卡、Widget 全部同口径，日期上面写「（订阅 $X）」。

**订阅口径不算「筛选」**：它不点亮工具栏的筛选图标、不进限定语
（`DashboardFilter.isActive` 只看时间和排除名单）——口径切换自己说明。
「即将扣款」模块也不再跟着它隐藏：口径管的是合计怎么算，那张卡说的是几天后要扣钱。
代码上 `DashboardFilter.unfiltered` 仍是「什么都不筛」（含订阅），
产品默认落在 `AppPreferences` 的初始值里，两者是两件事。

三条边界：

- 构成与对比分家列表共用同一套归属（`SpendAttribution`）：挂账号的订阅
  并进该账号的段；挂厂商的手动订阅，若该厂商**恰有一个**已接账号就并进它
  （行能点进详情），否则单独一段、名字就写厂商（多账号时账号段自带昵称
  后缀，不会撞名）；完全不归属的合成一段「手动订阅」（和 Widget 的
  `manual` 桶同一条线）。切片加起来必须等于大数字。
- 对比详情的每一行写全两头：「本月 $X · 七月同期 $Y」+ 涨跌幅；窗口说明
  尾部标口径（「… · 含订阅 / 仅从量」），两种口径的页面不该看起来一样。
  无主订阅段没有账号可推进，摆普通行。
- 「上月同期」里的订阅改成和本月同一把尺：**账单口径**，扣款日落在那个月内
  就计全额。以前按「扣款日 ≤ 上月的今天」记 0，分子账单、分母现金，
  25 号扣款的订阅会让每月 1–24 号的涨幅凭空虚高。

---

## 13 未决事项

- **Anthropic 账号类型** —— 去 Console 看有没有 Organization 设置，决定这家进不进 v1。向导已经按「先有组织」写好，测不通就手工录入。
- **checklist.design iOS 对照** —— P0 / P1 / P2、不适用和有意不做，记在 [docs/audit/2026-08-25-checklist-design-ios.md](audit/2026-08-25-checklist-design-ios.md)。不在本文件逐条展开。产品行为仍以本文为准。
