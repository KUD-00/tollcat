# X / Twitter 帖子库

一个账号，中英双语混发。这里是**发到 X 上的每一条**的事实源：发之前改这里，
发完在最后一节勾掉。中文帖同时可以投即刻，但要按即刻的文体重写一遍
（更长、更生活化），不许原样搬——同一段话在两个平台读起来必须像两次说话。

## 验收

每条帖过 `../../BRAND.md`：

- **一条帖只讲一件事。** 这是 X 上最硬的一条。旧稿把「支持 80 多家 + 密钥存哪 +
  没有服务器 + 免费开源」塞进一段，那是商店描述的写法，不是帖子的写法。
- **中文是中文写作，不是英文帖的翻译。** 三语各自成文（BRAND 四点五）。
  「Nobody can see your bills. Including me.」在英文里成立，直译成
  「谁都看不到你的账单，包括我」就是翻译腔——中文该说「不是我保证不看，
  是没有一条路通到我这儿」。
- **全角标点。** 中文帖里的逗号、冒号、分号一律全角，Latin 词之间的也不例外。
- **每条能独立看懂。** 不预设读者知道 TollCat 是什么，功能帖的第一句永远是场景。
- **禁营销词。** 赋能、极致、一站式、丝滑、重磅 / seamless、effortless、
  powerful、all-in-one、supercharge。
- **金额、凭据、隐私的句子不开玩笑**，也不夸大：说得出口的必须字面为真。

## 配图规矩

- 图 > 无图，**录屏 > 图**。三个天然的短视频：锁屏小组件跳数、下拉刷新时总数
  滚动、分享卡片出图。这三段录一次，长期复用。
- 素材在 `../appstore/marketing/`（带框整机图：dashboard / detail / services /
  wizard / widgets，iphone65 / iphone69 / ipad13，三语 × 明暗）和
  `../appstore/screenshots/`（单块小组件：`widget-phone-<模块>-<尺寸>-<语言>-<明暗>.png`）。
- 一张或四张，**别放三张**——X 的三图排版会裁得难看。
- 金额不当大字排版元素；带框整机截图可以出现金额，它一眼就是产品画面。
- 首次出现演示画面的帖子带一句「演示数据」。同一串对话里说一次就够。
- 每张图填 alt text。这是无障碍，也是白拿的一点权重。

## 占位符

发之前全局替换：`<APP_STORE_URL>`、`<MAC_DOWNLOAD_URL>`（Mac 是官网直发，
不在 App Store）、`<N>`（你自己真在付的服务家数，数一下再填，别编）。

---

## 零、账号与混发规矩

同一个账号发两种语言，最容易翻车的两点，先立规矩：

1. **同一件事的中英两版，隔开至少一天。** 背靠背发同一个内容的两种语言，
   时间线上看起来像机器人。发布日是唯一例外（见下）。
2. **中英不必一一对应。** 更好的做法是各挑各的题：英文讲工程和隐私架构，
   中文挑中文圈才有共鸣的（DeepSeek、Moonshot、硅基流动的账单接口有多离谱；
   国内信用卡付美元云的汇率账）。这样时间线上就不是同一条帖子说两遍。
3. **回复一律用对方的语言。** 英文帖下面来了中文提问，中文回；反之亦然。
4. **bio 一行双语**，让人一眼知道这个号两种语言都会发。

## 一、排期（从上架当天起算）

这次来不及预热，所以建造帖（D 类）改成软启动期补发，同时给主发布周
（Show HN / Product Hunt）当预热。和 `README.md` 的三段节奏对齐。

| 时间 | 发什么 | 说明 |
| --- | --- | --- |
| 上架 D 日 | A-1 英文 thread（发完置顶）+ A-2 中文单条 | 两条隔 6–8 小时。时区不同，读者重叠很小 |
| D+1 | E-1（只测过 9 家） | 上架第二天就自曝，比任何卖点都建立信任 |
| D+2 | C-1 锁屏小组件（录屏） | |
| D+3 | B-1 情景帖 | |
| D+4 | D-1（各家对「一个月」的定义都不一样） | 这条是最可能被转的一条，别浪费在第一天 |
| D+5 | C-3 仪表盘可编辑（中文） | |
| D+7 起 | 隔天一条，B / C / D / E 轮着来 | 手上够发一个月 |
| 主发布周 | H-2 / H-3（HN、PH 上线）+ 当天守评论区 | 帖子只发一条，别刷屏拉票 |
| 每月 1–3 号 | F 类，晒上个月的分享卡 | 长期动作，见 F 节 |

一天最多两条，超过就开始掉关注。发完当天回复区守两小时——X 上回复比发帖本身更值钱。

---

## 二、A 发布帖

### A-1 发布 thread（英文，发完置顶）

**1/**
> I pay for <N> cloud and AI services. Until this year I couldn't tell you what
> they cost me — not without logging into <N> dashboards and adding it up myself.
>
> So I built TollCat. It asks each vendor's billing API what I've spent this
> month and shows me one number. Free, open source. 🧵

配图：`iphone69-dashboard-en-light.png`（或录屏）。alt: "TollCat dashboard showing this month's total across several cloud services. Demo data."

**2/**
> Most days I don't open it.
>
> The number sits on the Lock Screen and the Home Screen. On the Mac it's in the
> menu bar, so it's on screen while I work.

配图：`widget-phone-monthToDate-small-en-dark.png` + Mac 菜单栏截图（落地页那张），两图。

**3/**
> The rule I wouldn't bend: your API keys never leave the device.
>
> They live in the Keychain — not iCloud, not backups — and the device talks
> straight to each vendor's API. There's no server of mine in between, so there's
> nothing on my end to breach.

**4/**
> It reads 80+ cloud and AI services: Cloudflare, OpenAI, Anthropic, Vercel,
> AWS, and a long tail of the things you sign up for at 2am.
>
> Every one comes with a step-by-step guide to making a *read-only* key. Worst
> case for a leaked key is "someone sees my bill".

配图：`iphone69-services-en-light.png` + `iphone69-wizard-en-light.png`。

**5/**
> Some services have no billing API at all.
>
> For those there's a reading inbox: forward the invoice email and the number
> shows up anyway.

**6/**
> Being honest about the long tail: of those 80+, nine are ones I've tested
> against a real paying account. The rest are adapters written against each
> vendor's docs.
>
> If yours doesn't match what your console says, tell me and I'll fix it.

**7/**
> iPhone and iPad on the App Store, Mac as a direct download. iOS 26 / macOS 26.
> MIT licensed, source on GitHub — including how to check the build on your
> phone came from it.
>
> App Store: <APP_STORE_URL>
> Mac: <MAC_DOWNLOAD_URL>
> Source: https://github.com/KUD-00/tollcat

### A-2 发布帖（中文单条，D 日晚发）

> 想知道这个月云上一共花了多少，我以前得挨个登控制台，八九个后台看下来，
> 还得自己把数加起来。
>
> 现在打开 TollCat 就是一个总数。锁屏上也有，多数时候我连 App 都不用开。
>
> 今天上架了，免费。

配图：`iphone69-dashboard-zh-light.png`。链接和密钥的事放第一条回复，正文不塞：

> 补两句：API 密钥只写进你这台手机的钥匙串，取账单是手机直连各家官方接口，
> 中间没有我的服务器。免费，MIT 开源，源码在 GitHub。
> App Store：<APP_STORE_URL>

---

## 三、B 情景帖（痛点共鸣，拉新主力）

一条一个观察，先讲处境，产品最多在最后一行露一次脸。

**B-1（英文）**
> The scariest line on my cloud bill isn't the big one.
>
> It's the small recurring one from a service I forgot I was still running.
> It never gets big enough to notice, and it never stops.

**B-2（中文）**
> 云账单最吓人的不是最大那一笔。
>
> 是某个半夜脑子一热开的服务，一直在按小时收着钱。它从来没贵到让我注意，
> 也从来没停过。

**B-3（英文）**
> No single one of my cloud bills is alarming. That's the problem.
>
> Twelve reasonable numbers arriving on twelve different days never add
> themselves up for you.

**B-4（中文）**
> 我每一家云的账单单看都还好，问题就出在这儿。
>
> 十几个合理的数字，分十几天到账，没有任何一个时刻它们会自己加起来给你看。

**B-5（英文）**
> Found out my free tier had quietly run out three weeks earlier.
>
> Nobody emails you about that. The bill just starts being a different number.

**B-6（中文）**
> 上个月才发现某家的免费额度早就用完了。
>
> 这种事没人会发邮件通知你，账单只是从某天起变成了另一个数。

---

## 四、C 功能帖（一功能一帖，长期弹药，可隔月复用）

**C-1 锁屏小组件（英文，录屏）**
> The whole point of this app is that you don't open it.
>
> This month's total sits on the Lock Screen. I look at it the way I look at
> the weather — not because I'm worried, just because it's there.

配：锁屏录屏。

**C-2 Mac 菜单栏（英文）**
> On the Mac it lives in the menu bar. Native SwiftUI, not a web page in a
> wrapper — it starts instantly and sits there costing nothing.
>
> Credentials go in this Mac's Keychain. It doesn't share them with the iPhone.

配：菜单栏面板截图。

**C-3 仪表盘可编辑（中文）**
> 仪表盘上摆什么，你自己定。
>
> 一共 12 块模块：本月合计、构成、订阅、热力图、预算、异常、余额告急……哪块有用留哪块，
> 顺序也能拖。其中 7 块能直接放到主屏上当小组件。

配：`iphone69-dashboard-zh-light.png` + `iphone69-widgets-zh-light.png`。

**C-4 热力图（英文）**
> A month of spending as one small square of squares.
>
> You don't read the numbers. You just see which days were dark, and remember
> what you were doing that day.

配：`widget-phone-heatmap-small-en-dark.png`。

**C-5 分享卡（中文）**
> 想把账单发给人看的时候，App 里能直接出一张卡片——照着你自己仪表盘上那几块模块渲。
>
> 想露什么模块就摆什么模块，不想露的挪走。

配：一张真实分享卡（自己那份，金额可留）。

**C-6 读数信箱（英文）**
> Not every vendor has a billing API. Some just email you a PDF once a month.
>
> Forward that email to your reading inbox and the number lands in the app with
> everything else. Eleven services work this way today.

**C-7 接入向导（中文）**
> 接一家服务大概一分钟：照着向导点，要开哪个权限、勾哪个范围、叫什么名字，
> 每一步都写着。
>
> 拿到的是一把只读密钥——它能看账单，动不了你的任何东西。

配：`iphone69-wizard-zh-light.png`。

**C-8 订阅与按量分开（英文）**
> Two kinds of money leave your account: the subscription that renews whether
> you use it or not, and the usage you actually racked up.
>
> They behave differently, so the app keeps them apart instead of showing you
> one blended number.

配：`iphone69-detail-en-light.png`。

**C-9 换手机（中文）**
> 钥匙故意不进 iCloud，所以换手机不能靠系统同步——这是设计，不是漏做。
>
> 旧手机导出一份加密文件，新手机输入屏幕上那个 10 位码。码离开导入页就失效，
> 文件过 24 小时也作废。

---

## 五、D 建造帖（开发者向，也是 HN 的预热）

这类帖子涨的是会认真读你链接的人。发的时候讲的是**问题**，不是产品。

**D-1 各家对「一个月」的定义（英文，最可能被转的一条）**
> Reading 80+ billing APIs taught me that "this month" is not a shared concept.
>
> Some bill on calendar months. Some on a rolling window anchored to the day you
> signed up. Some will only tell you about yesterday. One returns a total that
> silently includes tax; another doesn't.
>
> Adding those into one number is most of what this app is.

**D-2 小组件不可能偷发请求（英文）**
> "How do I know the widget isn't phoning home?"
>
> It can't. The widget target doesn't link the networking module at all — not
> guarded by a flag, just not in the dependency graph. Same reason the billing
> code and the tip-jar code can't reach each other: neither links the other.
>
> Privacy you can check by reading a build file beats privacy in a promise.

**D-3 开源可验证的诚实版本（英文）**
> "Open source" doesn't mean the binary on your phone came from that source.
>
> Apple re-signs and encrypts every App Store build, so byte-for-byte
> reproduction is impossible. What you *can* do: CI builds from a public tag with
> signed provenance, and the Mach-O UUID ties that build to the app you installed.
>
> The repo writes down where that guarantee stops. VERIFY.md.

**D-4 越刷越慢的那个 bug（中文）**
> 有段时间 App 越用越慢，我一开始以为是图表画得太重。
>
> 不是。是每次刷新都把整个历史重算一遍——成本正比于你刷新过多少次，
> 所以新用户飞快，我自己的机器上要转半天。
>
> 改法是把算好的结果落成账本，只在新数据进来时往上追加。

**D-5 三语不是翻译（中文）**
> 中英日三份文案是各写各的，不是互相翻译。
>
> 因为翻译过去的句子在另一种语言里往往站不住：英文的 "Missing a service you
> use?" 直译成中文是病句，得重新长一句「想用的服务似乎不支持？」——
> 那才是人在心里嘀咕的话。
>
> 仓库里有一份文档专门管这个，改文案要过它。

**D-6 一块模块一个小组件（英文）**
> Design call I went back and forth on: one widget kind per module, instead of
> one configurable widget you pick a module inside.
>
> Cost: swapping modules means deleting the widget and adding another. Benefit:
> searching "heatmap" in the widget gallery finds it. Discoverability won.

---

## 六、E 诚实帖（化解「凭什么把 key 给你」）

**E-1 只有 9 家实测（英文，D+1 就发）**
> Honest number: the supported list says 80+, but only nine of those have been
> tested against a real paying account. The rest are adapters written against
> each vendor's documentation.
>
> If a number doesn't match your console, that's a bug and I want to hear it.

**E-2 为什么 iOS 26 起（中文）**
> 有人问为什么最低要 iOS 26。答案不体面但是真的：我一个人做，
> 支持旧系统的成本我现在付不起。
>
> 这条门槛以后会往下降，不会往上抬。

**E-3 不是 FinOps（英文）**
> This isn't a FinOps tool and doesn't want to be.
>
> It doesn't allocate spend across a team, doesn't shut anything down, doesn't
> change your quotas. It reads, adds up, and shows you. Read-only, all the way
> through.

**E-4 没有商业模式（中文）**
> 常被问收费吗：不收。没有会员，没有专业版，也没有一个等着开闸的付费墙。
>
> 设置里有个打赏入口，糖果、咖啡、披萨三档，不打赏功能一样不少。
> 我自己每天用它看自己的账单，这是它存在的全部理由。

**E-5 Android / Windows（英文）**
> Asked a lot: Android and Windows are both in the repo, neither is done.
>
> Android is in active development, credentials in the on-device Keystore the
> same way. The Windows shell has never actually run on Windows 11 — one real
> bill on screen there is the next step.
>
> Nothing to install today. Not going to pretend otherwise.

---

## 七、F 习惯帖（长期，每月 1–3 号一条）

App 里的分享卡就是为这个准备的。目标是让「晒账单卡片」变成一个别人也想做的动作，
所以晒的必须是**自己的真实观察**，不是产品广告。卡片自带品牌，不用再喊名字，
别人问起来再答。

- "My <月份> in cloud bills. The one that surprised me: <服务>. I'd have guessed
  it was half that."
- "<月份>的云账单。最意外的是 <服务>，本来以为早就停了。"
- "First month <服务 A> cost me more than <服务 B>. Didn't see that coming."

规矩：一条一个观察，不堆话题标签，金额是真的就发真的，不想公开就把那块模块从卡片上挪走。

## 八、G 互动帖（便宜且有效）

- **要哪家**：「下一个接哪家？」四选一投票，选项从没支持的名单里挑
  （`site/src/supportTiers.ts` 的 `unsupported`）。投票结果本身就是路线图。
- **答疑转推**：有人问「支持 X 吗」，别只回复——把回答单独发一条，
  它对所有有同样疑问的人都有用。
- **接住吐槽**：有人晒被云账单吓到的截图，认真回一句自己的经历，
  不推销。这类回复带来的关注比自己发帖高。
- **修好就说**：用户报的数字对不上，修完回去告诉他，并单发一条
  「<服务> 的金额算错了，已经修好」。这是最好的信任广告。

## 九、H 里程碑帖（有真事才发）

- **H-1 上架**：即 A-1 / A-2。
- **H-2 Show HN**：当天一条，正文写「今天把它发上 HN 了，在评论区」，链接指 HN 帖。
  不喊投票，HN 反感且有检测。
- **H-3 Product Hunt**：同上，链接指 PH 页。和 HN 错开 2–3 天。
- **H-4 数字里程碑**：支持第 100 家、第一个外部 PR 合并、某家从「照文档写的」
  升到「真账号测过」。**不发下载量**——数字不好看时没法发，好看时也没意思。

---

## 十、发完勾掉

| 编号 | 语言 | 计划日 | 状态 |
| --- | --- | --- | --- |
| A-1 发布 thread | 英 | D | 未发 |
| A-2 发布帖 | 中 | D 晚 | 未发 |
| E-1 只测过 9 家 | 英 | D+1 | 未发 |
| C-1 锁屏小组件 | 英 | D+2 | 未发 |
| B-1 忘掉的那笔 | 英 | D+3 | 未发 |
| D-1「一个月」的定义 | 英 | D+4 | 未发 |
| C-3 仪表盘可编辑 | 中 | D+5 | 未发 |
| 其余 B / C / D / E | — | D+7 起隔天 | 未发 |
| H-2 Show HN | 英 | 主发布周 | 未发 |
| H-3 Product Hunt | 英 | 主发布周 +2~3 | 未发 |
| F 首条习惯帖 | 中/英 | 次月 1–3 号 | 未发 |

## 备忘

- **链接放哪**：X 压不压外链没有官方口径，别跟着传言瞎调整。稳妥做法是
  A 类和 H 类正文带链接（它们本来就是要转化的），日常 B / C / D / E 类把链接
  放第一条回复——那些帖子的目的是被看见，不是被点走。
- **别删帖重发**。一条数据不好就是不好，删了重发只会让老关注者看两遍。
- **不买粉、不进互赞群、不追蹭热点**。这个产品的读者是会去点开 GitHub 的人，
  那种流量对他们是负分。
- 中文帖投即刻要重写：即刻可以更长、更松、更像在讲今天发生的事。
