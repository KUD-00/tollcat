# TollCat 浏览器扩展 — 读数投递器 设计规格

> 状态：**提案**。没进 `docs/SPEC.md`，没排期，没写一行代码。
> 落地的前置条件写在第 09 节，条件不成立就不该开工。
> 和 SPEC 打架时以 SPEC 为准；这份文件只管扩展本身。
>
> 核实：2026-09-04 · 接口现状与商店政策见第 03 / 07 节的核实表

---

## 00 结论

**可行，而且管道端几乎不用改：`POST /v1/readings` 已经是公开投递口，扩展只替换"用户自己写脚本"那一环，Worker 一行不动。但现在不该做。**

三个理由，按重要性排：

1. **没有需求数据。** 还没发布，D1 的 `inboxes` / `ingest_keys` / `readings` 三张表全是 0 行。"先看真实投递里哪几家有人用，再给谁写适配器"这条路现在走不通，只能靠猜。猜错的代价是一个适配器白写加一份长期维护债。
2. **名单比想象的小。** 开了信箱的家里，只有一部分账单页上真的有"本月至今用量"可投（见第 03 节）。gcp 有更耐久的正规路子（BigQuery 结算导出），fly / pulumi 是纯用量但量小。真正只能靠抓页面的，是 supabase / render / expo / clerk / gitlab 这一撮。
3. **Chrome 的更新通道跟这种活配不上。** 抓取规则碎了要改代码 → 重新审核 → 几天到一周，期间用户看到的不是报错而是"读数不再变"。这是所有风险里最贵的一条，缓解办法（远程规则表）本身踩在商店政策的边界上（第 07 节）。

反过来，**Mac 上这三条里有两条不成立**：Safari 扩展能跟着现有直发壳和 Sparkle 走，不过商店审核；还能通过 native messaging 直接跟 App 说话，连手贴 key 都免了。所以如果要做，Safari 先行不是"顺手也做一个"，是**唯一合理的第一步**。

---

## 01 它是什么

一个**投递器**。取代"用户自己写脚本"那一环，不取代别的任何东西。

`InboxCredentials` 的注释已经把它的身份写好了：

> 投递 key 会躺在用户的 cron、CI、browser-use 脚本里，它一定会泄露；所以它只能写。

扩展就是那个 browser-use 脚本，只是用户不用自己写。它在威胁模型里的位置和 cron 里的一行 curl 完全一样，不需要为它新开一类信任。

### 明确不做

- **不做数学。** 抽到一个十进制字符串，原样投出去。加总、折算、周期对齐全在 `MeterCore`。
- **不做格式化。** 不认识货币符号该摆哪边，也不需要认识。
- **不显示总额、不显示历史、不画图。** 它不是第五个客户端，装了它也看不到你这个月花了多少。
- **不存账单数据。** 投完就忘。扩展的本地存储里只有 key 和规则表。
- **不碰任何账单凭据。** 它借用用户已登录的浏览器会话，不需要 API key，也不许要。
- **不做写操作。** 和 App 一样（SPEC 第 01 节）：不关实例、不改配额。
- **不用用量单位反推金额。** Render 的 metrics 接口能给带宽用量，Pulumi 能给 RUM 计数，乘上价目表就是钱——**禁止**。那需要一套价目引擎，价目会变，算错了用户不知道。SPEC 第 01 节写着"只关心钱""不做用量细节"，这条对扩展同样成立。

---

## 02 为什么这条路成立

### 契约已经在那儿了

现状链路是：App 建信箱 → 签一把 `tolli_` key → 用户写脚本 `POST /v1/readings {provider, periodStart, currentSpendUSD}`。扩展只换掉最后一环。`worker/src/inbox.ts` 零改动，`InboxClient` 零改动（它本来就没有投递方法——"App 不投递，只取回"）。

读数是 `ON CONFLICT(ingest_key_id)` 覆盖写，**天然幂等**。扩展每次打开账单页就投一次，不怕重，不需要去重逻辑，也不需要记"上次投到哪了"。

### 它不需要凭据，这是最强的一点

脚本方案要用户去搞 GCP service account、掏 session cookie、或者跑 headless 浏览器。扩展直接站在已登录的会话里，**凭据数量是零**。

对比一下两种方案下用户实际要交出什么：

| | 脚本 | 扩展 |
|---|---|---|
| 要创建的凭据 | service account / PAT / cookie | 无 |
| 凭据存在哪 | 用户的 cron / CI / `.env` | 不存在 |
| 泄露了对方能干什么 | 视权限，最坏是读全部账单甚至写操作 | 无 |
| TollCat 侧持有 | 一把 `tolli_`（只能写一行读数） | 同左 |

「Worker 从不碰账单凭据」这条 invariant 不但保住了，用户侧的凭据暴露面直接归零。

### 泄露面小且可吊销

扩展里只有一把 `tolli_` key，能力上界是"往一个信箱写一行数"。泄露的后果是别人能给你投假数字——不好，但可见（数字不对），且 `DELETE /v1/inbox/ingest-keys/:id` 一下就废。比让用户把 GCP 密钥贴进脚本安全一个数量级。

---

## 03 覆盖谁

目录里 `supportsInboxIngest: true` 的 12 家，按 `ProviderKind` 天然分成三档。**这一档划分不是我加的判断，是目录和 `InboxSnapshotMapper.canRepresent` 已经写好的。**

| 家 | kind | 页面上有本月至今用量？ | 扩展该做吗 |
|---|---|---|---|
| Fly.io | `.usage` | 有 | ✅ |
| Google Cloud | `.usage` | 有 | ⚠️ 优先走 BigQuery 导出 |
| Pulumi Cloud | `.usage` | 有（RUM 计费） | ✅ |
| Clerk | `.planAndUsage` | 有 | ✅ |
| Render | `.planAndUsage` | 有 | ✅ |
| Expo EAS | `.planAndUsage` | 有 | ✅ |
| Supabase | `.planAndUsage` | 有 | ✅ |
| GitLab | `.planAndUsage` | 有（Customers Portal / 用量配额） | ✅ |
| Linear | `.subscription` | **没有，是席位月费** | ❌ 走手动订阅 |
| Notion | `.subscription` | **没有，是席位月费** | ❌ 走手动订阅 |
| Figma | `.subscription` | **没有，是席位月费** | ❌ 走手动订阅 |
| Slack | `.subscription` | **没有，是席位月费** | ❌ 走手动订阅 |

下面那 4 家不是"优先级低"，是**信箱契约表达不了它们**：`currentSpendUSD` 的含义是日历月累计用量，席位月费是按扣款日整笔计入的订阅（SPEC 第 12.5 节：「没有公开账单接口的家，不能把『本月至今』录成固定订阅」，反过来也成立）。

> ### 顺手发现的一个不一致（不在本次改动范围内）
>
> 这 4 家在目录里 `supportsInboxIngest: true`，但 `kind == .subscription` 让
> `InboxSnapshotMapper.canRepresent` 返回 false，`InboxRefreshLane.mapped` 于是
> 走 `.failure` 分支。**结果是：现在给 Slack 签一把 key、投一条数，刷新会报失败，
> 不是"这次没读到"。** 用户能走完接入向导（`InboxHandoffModel` 不做"测试连接"），
> 但永远等不到第一次投递生效。
>
> 这跟扩展没关系，独立存在。要么把这 4 家的 `supportsInboxIngest` 关掉、向导改指
> 手动订阅，要么给订阅类想一条能表达的投递路径。**建议前者**，理由见上一段。
> 修的时候记得 `InboxLaneIsolationTests.catalogAndLaneAgreeOnWhoUsesInbox` 那张
> 硬编码名单要一起改。

### 官方接口现状（2026-09-04 重新核实）

SPEC 第 03 / 12.5 节那批"无公开账单接口"的结论是几个月前核的，这次挑关键的几家重核：

| 家 | 结论 | 依据 |
|---|---|---|
| Supabase | **仍然没有。** Management API 只有 `/v1/projects/{ref}/billing/addons`（GET/PATCH/DELETE），管的是加购项和 compute 规格，没有用量金额、没有发票、没有 spend | 拉了 `api.supabase.com/api/v1-json` 全量 path |
| Render | **仍然没有金额。** 有一大堆 metrics（带宽、CPU、内存、实例数），但没有任何带 billing / cost / invoice 的端点 | `api-docs.render.com/llms.txt` 端点清单 |
| Pulumi Cloud | **仍然没有金额。** 29 个 API 类目里只有 Resources Under Management 给资源计数，不给钱 | Pulumi Cloud REST API 文档 |
| Google Cloud | **控制台之外有正规路子**：BigQuery 结算导出能查本月至今合计。要用户开导出 + 建 dataset，表名 `project.dataset.gcp_billing_export_v1_<账单账号ID>`。Cloud Billing API 本身仍然不给花费 | Cloud Billing 文档「查询示例」 |

**对 GCP 的判断因此改了**：给它写页面抓取适配器是错的投资，"任务书"该给的是一段 BigQuery SQL。控制台是 Google 自家最爱重构的界面之一，而结算导出的表结构有正式契约。

Fly.io 沿用 SPEC 第 03 节已核实的结论（未文档化 GraphQL 没有本月花费）。Clerk / Expo 这次没重核，开工前补。

---

## 04 抓法：拦 JSON，不抓 DOM

### 为什么不抓 DOM

React + 虚拟列表 + A/B 实验，选择器每季度必碎。数字还带本地化千分位、货币符号、以及"$1.2K"这类缩写。抓 DOM 等于把一个字符串解析问题叠在一个不稳定定位问题上。

### 拦 JSON 怎么拦

MV3 里 `webRequest` 读响应体的能力已经没了，`declarativeNetRequest` 只能拦不能读。唯一的路子是 **`world: "MAIN"` + `run_at: "document_start"` 的 content script 猴补 `window.fetch` 和 `XMLHttpRequest`**，读页面自己调内部 API 的响应。

拿到的是结构化数字加货币码，比 DOM 稳一个量级，而且能录一份响应 JSON 进仓库当回归夹具——和 `MeterProviders/Fixtures` 同一套纪律。

代价照实说两条：

- **MAIN world 里页面能反过来动你的脚本。** 不放任何秘密进 MAIN world：key 留在 service worker，MAIN 世界只负责把抽到的原始 JSON 片段 `postMessage` 给隔离世界的 content script。
- **内部 API 无契约、无公告、随时变。** 这就是这件事的全部成本所在，第 09 节的排期条件是围着它设计的。

### 抽取规则是一张声明式表

每家一条规则，固定词汇，**不是表达式语言**（原因见第 07 节）：

```jsonc
{
  "provider": "supabase",
  "match": "https://api.supabase.com/platform/organizations/*/billing/*",
  "amount": { "path": ["usage", "total_amount"], "as": "decimal" },
  "currency": { "path": ["usage", "currency"], "default": "USD" },
  "period": { "path": ["usage", "period_start"], "as": "iso-date" }
}
```

字段词汇表由代码定义并穷举：`path`（数组下标 + 对象键，不含通配、不含条件）、`as`（`decimal` / `iso-date` / `epoch-seconds` 三选一）、`default`。解释器是死的，规则是数据。抽不到就静默跳过，**绝不猜**。

### 架构红线怎么守

ARCHITECTURE 那条"取数逻辑只有一份 Swift"必须守住。守法是让扩展**只做抽取和投递**：从 JSON 里取一个十进制字符串和一个货币码，原样上报。没有加总、没有单位换算、没有周期推断、没有格式化。这样"供应商适配逻辑"没有被复制进第二种语言——被复制过去的只有"这个数字在响应的哪个字段上"，而那本来就是数据。

---

## 05 契约缺口

三个，其中两个必须先补，不补的话扩展只能服务一家一币。

### a. `/v1/readings` 没有货币字段（必须补）

`currentSpendUSD` 硬编 USD。页面上的数字可能是 JPY（Slack 日本工作区）、EUR（GCP 欧洲结算账号）、CNY。REST 那条线在 `BillingCurrency.convert` 里换汇，信箱这条线没有出口。

**改法**：新增一对字段，老字段留着不动。

```
POST /v1/readings
{ "provider": "supabase",
  "periodStart": "2026-09-01",
  "amount": "1234.00",      // 新增，十进制字符串
  "currency": "JPY" }       // 新增，^[A-Z]{3}$
```

- 不要给 `currentSpendUSD` 配一个 `currency` —— 字段名里带 USD 再说它是日元是撒谎。
- `currentSpendUSD` 继续接受，含义不变（SPEC 第 12.5 节说过这一条不许改）。两个都给就取新的那对。
- Worker 只多存两列，**照旧不 parseFloat**，原样落库、原样回显。
- 换汇在 App 侧：`InboxSnapshotMapper.snapshot(from:kind:calendar:)` 多收一个 `rates: ExchangeRates`，走 `rates.toUSD`，把 `ConvertedAmount` 填进 `Snapshot.converted` —— 和 REST 那条线完全一样的形状，原币原值留着，用户对不上厂商后台时能看出差在哪。换不出来的币种照 `ExchangeRates` 既有的规矩办：宁可"这次没读到"，不按猜的汇率记一笔。
- 信箱那组常量（provider 正则、金额正则、`LABEL_MAX`、`MAX_INGEST_KEYS_PER_INBOX = 16`）现在只写在 `worker/src/inbox.ts` 里，没进 `shared/api-contract.json`。扩展是这份契约的第四个消费端，**顺手把 inbox 那一节收进 api-contract.json**，由 `scripts/generate-shared.py` 铺到 worker / Swift / 扩展三处，扩展不要手抄正则。

### b. key 怎么到扩展手里（必须补）

一把 ingest key 只有一行读数（归属的唯一事实源是 `ingestKeyID`，不是 `providerID` —— `InboxRefreshLane` 会用 key 的归属覆盖投递 body 里的 `provider`，这是防串种的关键，**不许为扩展改成一把 key 多家**）。上限 16 把。所以扩展覆盖 N 个账号就要 N 把 key。

三条路，只有两条能走：

- **手贴（MVP，也是没有 Mac 壳时的退路）。** App 里"为扩展签一把 key"→ 显示 key 和它归哪家 → 用户粘进扩展。一家一次。1–2 家可以接受，7 家不行。
- **Native messaging（正解）。** Safari Web Extension 和 Mac 壳在同一个 bundle 里，`browser.runtime.sendNativeMessage` 直接跟 App 说话：扩展说"我在 supabase 的账单页上，给我一把 key"，App 弹一次确认、签好、递过去。**不经服务端，不经剪贴板，不用用户手贴。** Chrome 走 native messaging host manifest（Mac 壳写进 `~/Library/Application Support/Google/Chrome/NativeMessagingHosts/`）也能做到同样的事。
- **服务端配对码（不要走）。** 让扩展用一个配对码去 Worker 换 key，意味着服务端要**明文存一把待领取的 key**。现在服务端只存 SHA-256、丢了只能轮换（`InboxCredentials` 的注释就是这么设计的），为一个便利开这个口子不值得。

把 read key 给扩展也不行——read key 能读全部读数、能删整个信箱，那是安全降级。

### c. 归属和上限（不改，但要在 UI 上说清）

16 把 key 的上限在扩展场景下会被吃掉一半以上（每家每账号一把）。签第 13 把的时候界面上要能说清"这个上限是干什么的、哪几把 30 天没用过了"——`listIngestKeys` 已经回 `lastUsedAt`，界面用起来。

---

## 06 分发

### Safari 先行

- **Safari 18.4 起，Developer ID 签名 + 公证的 Safari Web Extension 可以在商店外分发**（更早的版本必须走 Mac App Store，或者打开"允许未签名扩展"）。项目本来就是 macOS 26+ 直发 + Sparkle，**这条路上没有商店审核，规则碎了跟着下一个 Sparkle 版本走，或者直接下发规则表**。开工前用当时的 Xcode 再确认一遍这条政策。
- 扩展打进 `TollCatMac` bundle，`project-mac.yml` 里加 target（不要手编 `.pbxproj`）。
- Native messaging 免掉手贴 key（第 05 节 b）。
- iOS 的 Safari 也支持 Web Extension，能打进 iOS 包。但在手机上翻云厂商账单页的人少，**不排期**。

### Chrome 次之

- `host_permissions` 只列那几个域，一个不多。**绝不要 `*://*/*`** —— 单一用途说明和权限论证都会卡住。
- 规则表远程下发，否则修一个字段路径要等审核（第 07 节）。
- 上架时间点应该在 Safari 版跑过一段真实碎裂之后（第 09 节）。

### Firefox 暂不做

另一套审核、另一套 API 差异，换来的用户面在这个产品的受众里最小。

---

## 07 商店政策的硬边界

Chrome 的 MV3 政策禁远程代码，但明确允许远程配置数据。原文划的线是：

> 允许：「Fetching a remote configuration file for A/B testing or determining enabled features, where all logic for the functionality is contained within the extension package」
>
> 禁止：`<script>` 指向包外、`eval()` 执行远程取来的字符串、以及**为运行远程来的复杂命令而搭一个解释器**

**推论直接约束第 04 节的设计**：规则表必须是固定词汇的声明式表，路径就是路径，`as` 就三个枚举值。一旦规则里出现条件、循环、算术、或者任意 JS 片段，它就从"配置"滑向"为远程命令搭的解释器"，那是政策里点名禁止的那一类。这条边界不是我们自己划的保守线，是政策原文的分界，设计时按最严的读法办。

上架描述里要写清远程取的是什么、为什么必须远程（供应商内部接口随时变），别让审核员自己猜。

---

## 08 信任

目标用户是开发者。"一个能读我账单页的扩展"对这群人是高门槛请求，说不清就装不上。

- **权限最小。** 只列必需的域，不要 `tabs`，不要 `<all_urls>`，不要 `webRequest`。
- **零遥测。** 不接任何统计。App 那边的 `/v1/usage` 匿名页面计数也不要往扩展里搬。
- **页面内容不外传。** 出站只有一个主机：`api.tollcat.app`。抽到的 JSON 片段不落盘、不上报，取完那个数字就丢。
- **投递前让用户看见。** 抓到的数字先显示在扩展面板里，用户点一下才投。**理由是硬的**：信箱读数在 App 里就是 `Snapshot`（`source == .inbox`），和 API 取回的长得一样，而快照永不删除（SPEC 第 12.5 节）。一条错读数会永久污染月度历史，而且用户不知道它是错的。"访问页面就自动静默投递"这个形态不许做。
- **key 存 `chrome.storage.local`，不用 `sync`。** 别让它跟着浏览器账号同步到别的机器上。
- 扩展里要有一个"忘掉这把 key"的按钮，和 App 里的吊销是两件事，两边都要有。

---

## 09 什么时候才该开工

**闸门（全部成立才开工）：**

1. App 已发布，且信箱表里有真实投递数据——不是 0 行。
2. 至少有一家 provider 的投递来自 **≥ 10 个不同信箱**，且连续两个月都在投。少于这个数，说明手填够用了。
3. 上一条里那家不在"有正规接口可走"的名单上（也就是说：如果排第一的是 GCP，正确的动作是写 BigQuery 任务书，不是写扩展）。
4. 第 03 节那个订阅类不一致已经修掉——不然扩展会踩进同一个坑。

**开工后的顺序：**

| 阶段 | 做什么 | 完成的标志 |
|---|---|---|
| 1 | 补契约：`amount` + `currency` 进 `/v1/readings`，inbox 常量进 `shared/api-contract.json`，`InboxSnapshotMapper` 收 `ExchangeRates` | 一条日元读数能在 App 里显示成正确的美元，`Snapshot.converted` 里留着原币原值 |
| 2 | Safari 扩展 + native messaging + **一家** provider 适配器，内部自用 | 不用手贴 key；投一次，App 里数字对得上厂商后台 |
| 3 | 跑 1–2 个月，只量一件事：**规则碎了几次** | 有数。碎得比预期多就在这里停掉，把结论写回这份文件 |
| 4 | 规则表外置成远程数据，第二家适配器，再考虑 Chrome 上架 | Chrome 审核延迟不再等于用户静默停更 |

**阶段 3 是真正的决策点，不是形式。** 前面三个阶段的成本都是一次性的，第 4 步之后才开始付长期维护费。

### 代码放哪

新开顶层目录 `Extension/`（和 `worker/` `ops/` 平级）。TS，零第三方运行时依赖（AGENTS 那条"不引入第三方库"对运行时同样成立；构建工具照 `worker/` `ops/` 的先例办）。`scripts/check-outbound-hosts.sh` 的扫描目录要加上它——扩展里的 `https://` 字面量也该被那道闸管着。

注意扩展的 `host_permissions` 是**浏览器**要访问的域，不是 App 的出站目标。`OutboundHosts.swift`（关于页那份透明清单）**不要**因此新增厂商域名——App 对这几家依然一个请求都不发。

---

## 10 未决事项

1. Clerk / Expo 的官方接口这次没重核。开工前补，说不定其中一家已经有了。
2. 一个账号在多个组织/项目下（GCP 多结算账号、Supabase 多 org）时，扩展怎么知道当前页面对应哪把 key？倾向于让扩展把页面 URL 里的组织标识一起带给 App，由 App 匹配到账号——但这需要 `InboxRefreshTarget` 那边有对应的标识，现在没有。
3. 用户在扩展里投了一条，App 在另一台设备上、几天后才拉到。这段延迟里 App 显示的还是旧数字，界面上要不要有"信箱里有你还没拉过的新读数"这种提示？取决于 App 拉取读数的时机（现在是跟着刷新走）。
4. 规则表远程下发的话，它挂在 `/v1/catalog` 上（目录本来就只带文字和数字，规则表也是数据），还是另开一个端点？倾向前者，但要确认它不会把目录的体积吃大。
