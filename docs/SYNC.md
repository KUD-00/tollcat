# TollCat 指标云同步 — 设计规格

> 状态：**提案**。没进 `docs/SPEC.md`，没排期，没写一行代码。
> 落地的前置条件写在第 09 节，条件不成立就不该开工。
> 和 SPEC 打架时以 SPEC 为准；这份文件只管同步本身。
>
> 核实：2026-09-04 · 现有地基见第 02 节，跨端加密的现实见第 08 节

---

## 00 结论

**技术上八成地基已经在了；隐私叙事上这是全项目最贵的一次改动；必要性是三者里最弱的一环。现在不该做。**

三件事按重要性排：

1. **它治不了你说的那个痛。** `导入/导出` 解决的是**凭据搬家**（换机：新设备要能自己取数），指标同步解决的是**多设备同看**（第二台只显示第一台取回来的数）。同步做完，换机流程一个字没变。这是加一个功能，不是让 `导入/导出` 变好用。
2. **"只同步指标"这个说法本身要修正。** 光有金额渲染不出仪表盘——第二台设备没有 `ProviderConfigRecord` 就没有行可以挂数字。实际载荷是「迁移包 − 凭据 + 一段快照窗口」，里面必然含**厂商名单和昵称**（第 02 节）。
3. **它动的是卖点本体。** `SPEC 12.5` 那条边界写着「永远不接触账单凭据、**不接触账单数据**」，README 三语、Show HN、Product Hunt、V2EX、落地页全押在同一句 *"Nobody can see your bills. Including me."* 明文同步金额，这句话当场作废。唯一能同时保住功能和这句话的形态是**端到端加密的 blob**（第 03 节 B）。

反过来，有两条支持它的论点是硬的，不是"方便"：

- **`Cost Explorer $0.01 / 次`**（SPEC 第 03 / 12.5 节）。两台设备各刷一遍 AWS 就是双倍付钱。指标同步让第二台只读不刷——它**省钱**，也少打一遍各家的限流。
- **Android 今天连 `导入/导出` 都没有。** `strings_settings.xml` 里那句原文就是「加密迁移目前只在 iOS 上……换机需要重新接入」。对 Android 用户，同步不是"更方便的第二条路"，是**唯一的一条路**（第 08 节）。

---

## 01 它是什么

一个**镜子**。第一台设备取数并落库，把「指标」推上去；其余设备拉下来显示。仅此。

### 明确不做

- **不同步凭据。** 一个字节都不许进同步载荷，加密了也不许（第 07 节）。这条不是保守，是这个 App 的定义。
- **不在服务端取数。** SPEC 12.5：**有服务端 ≠ 可以用服务端**。同步是搬运已经取回来的数，不是让服务器去打各家 API。
- **不做账号系统。** 没有邮箱、没有密码、没有找回。和信箱一样：一串随机识别子，丢了就是丢了（丢的是镜子，不是本体）。
- **不做推送告警。** SPEC 第 01 节禁的那条不因为多了一个端点而松动。
- **不做双向"编辑同步"。** 同步的是读数和接入清单，不是"在 B 机改个昵称推回 A 机"。第一版单向：谁有凭据谁是写方（第 05 节）。
- **不做服务端合并。** 服务端看不懂密文，合并只能在客户端做。这是设计目标，不是限制。
- **不做实时。** 跟着刷新走，和目录、信箱同一条纪律：一次后台请求，失败静默。

---

## 02 现有地基与"只同步指标"的四个坑

### 已经在的（这是这个提案最省的部分）

| 要件 | 现状 |
|---|---|
| 识别子的形状 | `worker/src/inbox.ts`：128 位随机公开 id + `tollr_` 读 key + `tolli_` 投递 key，**服务端只存 SHA-256**，读写分离 |
| 限流 | `rate_limits` 通用桶，各功能互不挤占 |
| 删除路径 | `DELETE /v1/inbox` 已经是这个形状（连带删读数和 key） |
| 出站声明 | `api.tollcat.app` 已在 `OutboundHosts.all`，**不需要新域名**，`check-outbound-hosts.sh` 不动 |
| 加密原语 | `TransferCryptor`：AES-GCM-256 + PBKDF2-HMAC-SHA256 600k + 明文头整段做 AAD |
| 载荷类型 | `TransferPayload`（在 `MeterCore`，纯 Codable，已带 schemaVersion） |
| 落盘覆盖闸 | `DeviceTransferCoverageTests` + `check-source-invariants.py` 那张双份表：字段要么进包要么明示不装 |
| 跨端的核 | Android / Windows 的壳共用同一份 `MeterCore`（符号链接 + JNI / C ABI） |

### 坑 1：指标单独存在渲染不出仪表盘

第二台设备没有接入行，账号段、昵称、`kind`、`SpendAttribution` 全空。所以载荷至少是：

| 落盘模型 | 进同步载荷？ | 为什么 |
|---|---|---|
| `SnapshotRecord` | ✅ **进**（截窗，见坑 3） | 这就是"指标"本身。注意它在迁移包里是**明示不装**的（`SPEC 12`：刷新重拉），同步这里的口径相反，两张表不能共用一份名单 |
| `ProviderConfigRecord` | ✅ 进（去密字段，同迁移包那 11 个） | 没有它就没有行可以挂数字 |
| `ProviderMembershipRecord` | ✅ 进 | 服务页的顺序 |
| `SubscriptionRecord` | ✅ 进 | 手动订阅是总数的一部分，不同步就是两台设备总数不一样 |
| `ManualUsageRecord` | ✅ 进 | 同上，而且手填刷不回来 |
| `AppPreferencesRecord` | ⚠️ 拍口径 | 仪表版式（`dashboardLayout`）、显示货币要不要跟着走？倾向**只同步账本相关的**（货币口径、订阅口径），版式和提醒留本机 |
| `TipRecord` | ❌ 不装 | 收据留在买过的那台设备上（同迁移包） |
| Keychain 里的凭据 | ❌ **绝不** | 第 07 节 |

**结论：载荷 ≈ 迁移包 − 凭据 + 快照窗口。** 它含厂商名单和昵称。提醒一下自己：`feedback` 表的注释里，"已接入的服务名单"是要用户**显式勾选**才带的——你已经把它当敏感数据对待过一次了。

### 坑 2：信箱那条 reading 的形状喂不饱仪表盘

`POST /v1/readings` 只有 `{provider, periodStart, currentSpendUSD}`，`InboxSnapshotMapper` 因此只能落 `currentSpendUSD`（prepaid / freeTier / subscription 三种 kind 直接 `canRepresent == false`）。想让第二台设备的趋势、构成、钱包、免费额度、明细都对，就得同步完整 `Snapshot`——`dailySpendData` / `spendLinesData` / `walletsData` / `converted` 三兄弟全都要。

**所以"复用信箱那条管道"是行不通的**，别被"看起来很像"骗了。信箱传的是一个匿名金额，同步传的是一整张账单。

### 坑 3：`SnapshotRecord` 永不删除，同步必须截窗

`SnapshotWriter` 那扇门只进不出。整库同步的体积会一直长。截窗规则（建议，开工时定稿）：

- 最近 13 个月：每月**每账号最新一条**（够算"上月同期"和趋势）
- 当月：保留日粒度和明细（`dailySpend` / `spendLines`）
- 更早的：不同步。历史留在取过数的那台设备上——和"历史留在设备上"这条既有口径一致

D1 单值上限是 **2 MB 量级**，部署前照 `d1/platform/limits` 核一遍原文。截窗之后应该在几十 KB，但 `spendLines` 是唯一会失控的字段（几十家 × 几百行 sku），要在客户端设硬上限。

### 坑 4：`SnapshotSource` 没有第四档

同步来的快照既不是 `api`（B 机没取过），也不是 `inbox`。而 `reconcilesWithVendorConsole`（"这个数和你后台看到的一致"）在 B 机上是**转述而非验证**。

三条路，必须拍一条，**不许顺手塞成 `.api`**：

- 加 `case synced`，`reconcilesWithVendorConsole == false`——诚实，但详情页那句话在两台设备上不一样，用户会觉得数字降级了
- 加 `case synced`，但保留"原来是谁取的"作为附属字段——最准确，代价是 `Snapshot` 多一个字段、JNI schema 升版、`ProductSnapshotCodec` 跟着改
- 保留原 `source`，另加一个"这条不是本机取的"标记——倾向这条，因为 `source` 回答的是"这个数怎么来的"，而"哪台设备落的库"是另一件事

---

## 03 三种形态，只有一种能走

### A. 明文行（照信箱那套扩出去）

服务端存 `(inbox_id, provider, period, amount)` 这样的行。**不要走。**

它让 `SPEC 12.5` 的边界从"不接触账单数据"变成"接触账单数据"，对外那句话只能撤回。撤回一句卖点，换来的是省掉一层加密——这个交换比在任何时候都不成立。

### B. 端到端加密 blob（推荐形态）

服务端只存 `(不透明 id, 密文, version, updated_at)`。密钥在客户端由用户手里的码派生，Worker 侧连 blob 里有哪些字段都不认识。

- SPEC 那条边界**字面上仍然成立**：它拿到的是它解不开的密文，不是账单数据。
- 对外文案从"账单不上传"升级成"服务器上那份是我们解不开的密文"——这是升级，不是撤回。
- 这条性质必须能被代码验证，不是靠承诺（第 05 节的模块位置）。

诚实地说三件它保不住的事：

1. **元数据仍然泄露。** 服务端知道这个 id 每天在同步、blob 多大、多久同步一次。
2. **码弱等于没加密。** 所以码必须**我们生成**，不许让用户自己起密码。
3. **密文长期挂在服务器上，码长要重算。** `SPEC` 给 10 位 base32（约 50 bit）的论证前提是"文件只活 24 小时"+"攻击者得先拿到文件"。同步的密文没有这个窗口。粗算一次：每猜一次要算 60 万次 HMAC ≈ 120 万次 SHA-256 压缩，当代单卡是每秒几千次猜测的量级，2^50 单卡万年、千卡年这个数量级。不是灾难，但**它的安全论证换了前提，就必须重新算一遍并写下来**，倾向往 12–16 位走。`TransferLockout` 那 5 次退避在这里帮不上忙——攻击者拿着 dump 离线爆破，不经过我们的服务器。

### C. CloudKit private database（Apple 生态内明显更划算）

凭据在 Keychain、不在 SwiftData 库里，所以**同步 SwiftData 库恰好等于"只同步指标 + 去密接入清单 + 偏好"**，正是这份文件想要的那个集合。Apple 托管，我们看不到，零服务端代码，零新端点，零"识别子"UI，还顺手抹平 Mac 壳那个双录凭据的尴尬。

代价照实说：

- 要 iCloud entitlement（改 `project-common.yml` 加 capability，按 AGENTS 的"边界"这条得先问）
- SwiftData + CloudKit 要求**所有属性可选或有默认值、不能有唯一约束**，`SnapshotRecord` 这批 `@Model` 有真实迁移成本
- `PersistenceContainerTests` 那条 `cloudKitDatabase == .none` 断言和 `AboutView` 的文案都要改
- **Android / Windows 用不了**

### 决策点只有一句

**跨端（iOS ↔ Android）同看，是不是刚需？**

- 是 → 才轮到 B。
- 只是 Apple 生态内多设备 → C 明显更便宜，而且不动那句卖点。

| | A 明文行 | B 加密 blob | C CloudKit |
|---|---|---|---|
| 服务端看得到账单 | ✅ 看得到 | ❌ 只有密文 | ❌ 我们连库都没有 |
| SPEC 12.5 边界 | **要改口径** | 字面成立，加一项 | 不涉及 |
| 对外文案 | 撤回 | 改写（升级） | 改写（"你的 iCloud"） |
| 跨端 | ✅ | ✅ | ❌ 仅 Apple |
| 服务端代码 | 中 | 中 | **零** |
| 客户端代码 | 中 | 大（三份信封，第 08 节） | 中（`@Model` 迁移） |
| 用户要搬运的秘密 | 一串 | 一串（但内含两把，第 04 节） | **零** |

---

## 04 契约（走 B 的话）

### 端点

```
POST   /v1/sync            建同步位，返回 id + 读 key + 写 key       （无鉴权，卡 content-type）
GET    /v1/sync            取回密文 + version                        [读 key]
PUT    /v1/sync            覆盖密文，要求 If-Match: <version>        [写 key]
DELETE /v1/sync            删除这个同步位                            [读 key]
```

照信箱的既有纪律：两把 key 只在建的时候返回一次，服务端只存 SHA-256，读 key 读不了写、写 key 读不了读。`PUT` 缺 `If-Match` 或版本不匹配 → `409`，客户端拉下来合并再重试（第 05 节）。

```sql
CREATE TABLE sync_slots (
  id TEXT PRIMARY KEY,
  read_key_hash TEXT NOT NULL UNIQUE,
  write_key_hash TEXT NOT NULL UNIQUE,
  -- 密文。服务端不解析、不校验内部结构、不知道里面有几家。
  blob BLOB,
  -- 单调自增，乐观锁用。不是时间戳：两台设备时钟不同步会打架。
  version INTEGER NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL,
  created_at TEXT NOT NULL
);
```

### 一个必须先想清楚的密码学陷阱

**"一个特殊识别子"这个说法会天然踩进去**：如果鉴权用的 Bearer token 和派生加密密钥的口令是同一个字符串，那么服务端在**每一次请求的 header 里**都见过密钥材料——端到端加密当场作废，密文和明文没有区别。

所以必须是**两把独立的秘密**：

- **访问 key**（`tolls_` / `tollw_`）：走 `Authorization: Bearer`，服务端见得到，只存哈希，用来路由和鉴权
- **加密码**：**永远不出客户端**，只用来派生 AES 密钥，不进 header、不进日志、不进剪贴板

用户当然不该搬运两样东西。折中是把它们打成一串，客户端切开：

```
tollsync1.<slot-id>.<access-key>.<passcode>
          └─ 上路由 ─┘ └─ Bearer ─┘ └─ 只留本地 ─┘
```

搬运一次、心智一个东西，密码学上是两把。搬运方式优先二维码（也正是第 09 节阶段 0 要给迁移码补的那个能力），手敲是退路。

### 信封

复用 `TransferFileHeader` 那套形状：版本、salt、迭代数、nonce、明文头整段做 AAD。两点不同：

- **没有 `notAfter`。** 同步位是长期的，过期字段在这里没有意义（迁移文件那个 24 小时只缩小误发窗口，本来也不是密码学保护）。
- **载荷 schema 独立编号。** 不要复用 `TransferPayload.currentSchemaVersion`——两张表的"装什么"口径不同（坑 1 那张表里 `SnapshotRecord` 的进/不装正好相反），共用一个版本号迟早出事。

信封格式（字段顺序、AAD 组成、迭代数、码的字母表和长度）进 `shared/api-contract.json`，由 `scripts/generate-shared.py` 铺到各端，**不许三个平台各手抄一份常量**。

---

## 05 客户端

### 模块位置（这是"服务端看不到账单"能被验证的地方）

新叶子 `MeterSync`，和 `MeterTips` / `MeterInbox` / `MeterFeedback` / `MeterUsage` 并列。

**它不许依赖 `MeterCore`。** 和 `MeterFeedback` 一样——拿不到 `Money`、拿不到 `Snapshot`，它的 API 只收发 `Data`。这样"这条线上流的只可能是密文"就不是一句承诺，而是 `ArchitectureGuardrailTests` 和 `check-source-invariants.py` 能锁死的事实。加密和解密都不在它里面。

各层职责：

| 放哪 | 干什么 |
|---|---|
| `MeterCore` | `SyncPayload` 类型 + **纯函数合并**（无 `Date()`，时间从参数进）。Android / Windows 走 JNI / C ABI 直接用这一份 |
| `MeterPersistence` | `collect` / `apply`（SwiftData 侧）+ 信封加解密（CryptoKit） |
| `MeterSync`（新） | 只管 HTTP 到 `/v1/sync`，只见 `Data` 和 version |
| `MeterFeatures` | 设置 → 云同步那一页，以及跟着刷新走的那条泳道（照 `InboxRefreshLane` 的形状） |

### 合并规则

快照天生 append-only，按 `(accountID, providerID, periodStart, fetchedAt)` 去重即可，不需要 CRDT。整包 last-write-wins **不许**——`SnapshotRecord` 是全项目最不能丢的表。

冲突流程：`PUT` 拿 `409` → `GET` 最新密文 → 解密 → 本地合并 → 带新 version 重试，最多两次，再失败就静默放弃（下次刷新还会试）。

接入清单和订阅这类**可编辑**数据不能靠 append-only 混过去：第一版按"写方为准"（下一条），删除在 B 机上表现为"这一行不再出现"。要真双向就得给每行加 `updatedAt` 并逐字段 LWW——**第一版不做**，写进第 10 节。

### 谁是写方

第一版：**有凭据的那台是写方，其余只读。** 理由是硬的——

- `Cost Explorer $0.01 / 次`：两台都刷就是双倍付钱，SPEC 第 03 / 12.5 节为这一条专门给 AWS 开了单独按钮、写了"约 $0.01"、并禁了后台轮询。
- 各家的限流也是一样的道理。

只读端的表现要说清：仪表页照常显示，刷新按钮不再打各家 API 而是"拉一次同步"，详情页那句"和厂商后台一致"按坑 4 拍的口径走。**不许让只读端看起来像坏了。**

### 闸和清单（开工时逐条过）

- `SyncPayloadCoverageTests`：照 `DeviceTransferCoverageTests` 的形状，落盘字段要么进同步载荷、要么明示不装，**两份名单**（`check-source-invariants.py` 那张表跟着加）。这条不能省——`quantity` 那种带默认值的参数漏写，编译器不会提醒，静默丢数据。
- `shared/api-contract.json`：信封常量、`USAGE_SCREENS` 加 `settings_sync`（不加的话新页面的匿名计数会被服务端拒）。
- `shared/ui-test-ids.json`：Maestro 两端冒烟要用的 id。
- `App/Resources/PrivacyInfo.xcprivacy`：第 06 节。
- 三门语言的文案（`L("…")` + 同模块 xcstrings 的 en/ja + `generate-android-strings.py`）。

---

## 06 隐私与文案

### SPEC 12.5 那条边界要加第 6 项

现在允许的内容是五项：打赏留言、应用内反馈、公开接入目录、读数信箱、匿名页面计数。加第六项时**必须连措辞一起改**，因为「不接触账单数据」这句话现在是靠"服务端存的是密文"成立的，这个前提要写在同一段里，不能让后来的人只读到一句宽松的"允许同步"。

建议的措辞骨架：

> - **同步密文**：服务端只存一段它没有密钥的密文和一个不透明 id。加解密在客户端，`MeterSync` 不依赖 `MeterCore`（它拿不到 `Money`），这条性质由隔离测试锁死。**服务端有能力解密的那一刻，这一项就作废。**

### 对外文案要改的地方

`README.md` / `README.zh.md` / `README.ja.md` 第一段、`site/` 落地页第一条、`site/src/pages/llms.txt.ts`、`docs/launch/*`（Show HN / PH / V2EX / Zenn / X）、`AboutView` 那段、`UsageGuide` 和 `OnboardingPage` 的 Keychain 那几句。

**改法是加一句，不是删一句**：凭据那句话（不出设备、不进 iCloud、不进备份）完全不变，那才是核心承诺；账单那句从"不上传"变成"默认不上传；你自己打开云同步的话，服务器上那份是我们解不开的密文"。按 `BRAND.md` 的验收：正文要自然、答案先行、不许出现"军用级加密"这类黑话。

### 隐私清单

要加 `NSPrivacyCollectedDataTypeOtherFinancialInfo`（`Linked: false`、`Tracking: false`、purpose `AppFunctionality`）——即便是密文，"我们替你存着"这件事本身就该披露，这里按最严的读法办。

**顺手发现的一个已有缺口（不在本次范围内）**：读数信箱今天已经在上传金额，而 `App/Resources/PrivacyInfo.xcprivacy` 里没有任何 financial 类目。做不做同步，这一格都该重新审一遍。

### 删除

`DELETE /v1/sync` 要在设置里有入口，文案照 `InboxSettingsView` 那个确认框的纪律：点名"服务器上那份删掉、已经存到本机的历史留着"，不做静默破坏。

---

## 07 明确不做的几件事（滑坡防线）

这一节存在的理由和 `SPEC 12.5` 那句「有服务端 ≠ 可以用服务端」一样：一旦项目里有了一条"同步通道"，最省事的下一步永远是往里多塞一样东西。

- **凭据不许进同步载荷，加密了也不许。** 一旦进了，"密钥只在这台设备的 Keychain 里"就是假话，而这句话是整个 App 的地基。想搬凭据只有一条路：用户主动、一次性、加密文件（`SPEC 12.5`）。
- **不许让服务端取数。** 同步位里有厂商名单，下一步"顺手让服务器帮你刷"就只差一把 key——那把 key 永远不给。
- **不许因为有了同步就做推送告警。** SPEC 第 01 节禁它的理由是"推送需要服务器"，而这个理由早就被 Worker 破了；真正的理由是产品定义——Widget 承担告警职责。别拿新端点当借口。
- **不许在服务端解密做任何统计。** 服务端没有密钥，这条是设计层面成立的；写下来是为了防止有人"临时加个字段方便看数"。要看数就看 `/v1/usage` 那份匿名计数。
- **不许把同步位当"账号"往外长。** 没有邮箱、没有密码、没有找回、没有登录态。它是一串识别子。

---

## 08 Android 与 Windows

### 这是必要性最强的一段

Android 壳今天**没有导入/导出**。`DeviceTransferDestination.kt` 只有一段解释文字，原文是：

> 加密迁移目前只在 iOS 上。……Android 上的凭据只在这台设备的 Keystore 里，还不能导入或导出 `.tollcat` 文件。换机需要重新接入。

连带的后果是：`StoredInboxMailbox` 只在迁移包里旅行，所以 **Android 上想用读数信箱，必须先从 iOS 导出一次**——这条路在 Android 上根本走不通。信箱的 read key 对用户**完全不可见**（`InboxSettingsView` 只显示信箱 id），也没有任何"粘贴 read key 加入已有信箱"的入口。

所以对 Android，同步不是"更方便的第二条路"。这也顺带说明：阶段 0 那个"read key 加入信箱"的小口子（第 09 节）本身就值得补，和同步做不做无关。

### 但跨端加密要三份实现

`TransferCryptor` 在 `MeterPersistence` 里，`import CryptoKit`。而 `Android/native` 只符号链接 `MeterCore` / `MeterProviders` / `MeterFormat`——**`MeterPersistence` 不在里面，CryptoKit 在 Android 上也不存在**。Apple 的 swift-crypto 是第三方包，AGENTS 那条"一个都不要"（唯一既定例外是 Sparkle）挡着。

所以信封的加解密只能落在各平台的皮上，照 `AndroidKeystoreCredentialStore.kt` 已经立下的先例办（Keystore 在 Kotlin 侧，不在 Swift 侧）：

| 端 | 信封用什么 | 可用性 |
|---|---|---|
| iOS / Mac | CryptoKit（`TransferCryptor` 已有） | 现成 |
| Android | `javax.crypto`（AES/GCM + PBKDF2WithHmacSHA256） | 平台自带，不引第三方 |
| Windows | `System.Security.Cryptography`（`AesGcm` + `Rfc2898DeriveBytes`） | 平台自带 |

跨端的代价是**三份信封实现 + 一组共享测试向量**：`shared/` 里放一份"这个码 + 这个 salt + 这段明文 → 这段密文"的夹具，三端各跑一遍。合并逻辑不用重复——它在 `MeterCore` 里，Android / Windows 走 JNI / C ABI 用同一份（照 `ProductSnapshotCodec` 的路子加一个 `ProductSync` 桥）。

注意 `SqliteLedgerStore` 的 `VERSION = 4` 是 Android 自己的账本，`collect` / `apply` 在那一侧要另写一份——这是 Android 壳既有的分工，不是这个提案带来的新债。

---

## 09 什么时候才该开工

### 阶段 0（现在就该做，和同步无关，都不动 SPEC 边界）

这两件事各一天量级，做完再看同步还剩多少必要性：

1. **迁移码出二维码。** 导出页在显示 `K7M2Q-9XR4T` 的同时给一张 QR，导入页扫一下，省掉手敲 10 位。这是"`导入/导出` 不好用"的**直接**解药。码仍然不进剪贴板、不入库、离开页面就没（`SPEC 12.5`）。
2. **信箱页加「用 read key 加入已有信箱」。** 补掉第 08 节那个洞。顺带零成本验证一个假设：**用户愿不愿意粘贴一串识别子**——整个同步提案都建立在这个假设上，现在它一次都没被验证过。

### 闸门（全部成立才开工同步）

1. **App 已发布。** 现在仓库还私有，`inboxes` / `ingest_keys` / `readings` 三张表全是 0 行（`docs/EXTENSION.md` 2026-09-04 核实），零用户信号。`SPEC 12` 自己写着「个人自用工具，不写 roadmap」。
2. **"两台设备"是真被提出来的诉求**，不是我们替用户想的。阶段 0 第 2 条的采用率是最便宜的先行指标。
3. **第 03 节那个决策点已经拍了**：跨端刚需 → B；只有 Apple 生态 → C。**没拍就不许开工**——A / B / C 的客户端代码量和文案改动完全不同，猜错等于全白写。
4. **坑 4（`SnapshotSource` 口径）和第 02 节那张载荷表已经定稿**，写进 `SPEC 12.5`。载荷口径是这件事的地基，不能边写边定。

### 开工后的顺序

| 阶段 | 做什么 | 完成的标志 |
|---|---|---|
| 1 | 契约：`/v1/sync` 四个端点 + `sync_slots` + 信封进 `shared/api-contract.json` + 三端测试向量 | 三个平台能互相解开对方的密文 |
| 2 | `MeterSync` 叶子 + `MeterCore` 的合并纯函数 + 覆盖闸 | 隔离测试锁死"这条线只流密文"；载荷字段闸绿 |
| 3 | iOS 单向：写方推、只读端拉，**自己两台设备用两周** | B 机的仪表页和 A 机逐格对得上，含趋势、构成、钱包、明细 |
| 4 | Android 只读端 | Android 第一次有了跨设备路径 |
| 5 | 再考虑双向可编辑数据（第 05 节那段） | —— |

**阶段 3 是真正的决策点，不是形式。** 前三个阶段是一次性成本；阶段 3 之后开始付的是长期账：一个多设备一致性问题的调试成本，和一句改过的隐私文案要一直守住。

---

## 10 未决事项

1. **`AppPreferencesRecord` 哪些字段跟着同步？** 倾向只同步账本口径（显示货币、订阅口径），版式（`dashboardLayout`）、提醒、外观留本机——同一个人在 iPhone 和 Mac 上想要的版式本来就不一样。要定稿。
2. **可编辑数据的双向同步**（接入昵称、订阅、排序、删除）。第一版"写方为准"够不够用，得看阶段 3 的实际手感。逐字段 LWW 要给每行加 `updatedAt`，那是一次落盘迁移。
3. **两台设备都有凭据的场景**（用户先走了一次 `导入/导出`，两台都能刷）。"谁是写方"要不要变成用户可选、还是按"最近成功刷新时间"自动推举？后者会在两台之间来回抖。
4. **码长要重算**（第 03 节 B 第 3 点），并把算术过程写进 SPEC，别只留一个结论数字。
5. **Widget 在只读端的表现。** Widget 不链 `MeterProviders`、也不该链 `MeterSync`，它读 App Group 的落盘值——所以只读端的 Widget 只在 App 拉过同步之后才更新。这个滞后要不要在 Widget 上体现？
6. **`ops/` 那个本机 TUI 要不要加同步位的运维视图？** 它只该看得到"有多少个同步位、多大、多久没动"，**看不到内容**（它本来也没有密钥）。
7. **同步位的生命周期。** 一个再也没有设备来同步的位子要不要过期回收？倾向要（它占的是我们的存储），但"多久"和"回收前怎么通知"没想清楚。
