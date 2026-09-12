# App Store 提交材料

这里是 App Store Connect 要填的东西的事实源：截图由脚本生成，文案改这里再贴过去。

## 素材（screenshots/）

```bash
./scripts/capture-appstore-screenshots.sh            # 全量：构建 + iPhone / iPad 横竖 / 小组件 × 3 语 × 明暗
SKIP_BUILD=1 ./scripts/capture-appstore-screenshots.sh    # 复用上次构建
SKIP_IPHONE=1 SKIP_WIDGETS=1 ./scripts/capture-appstore-screenshots.sh  # 只重截 iPad
```

| 文件前缀 | 设备 | 分辨率 | 用途 |
| --- | --- | --- | --- |
| `iphone69-*` | iPhone 17 Pro Max 模拟器 | 1320×2868 | 宣传图的素材，别直接上传 |
| `ipad11-*` | iPad Pro 11" (M5) 模拟器横屏 | 2420×1668 | 同上 |
| `ipad11p-*` | 同上，竖屏 | 1668×2420 | 同上 |
| `widget-phone-<模块>-<尺寸>-*` | 渲图，不是截图 | 每格内容尺寸 @3x | 小组件那一页的主屏 mock-up |
| `widget-pad-<模块>-<尺寸>-*` | 同上，在 iPad 上渲 | 每格内容尺寸 @3x | iPad 的那一页 |
| `iphone69-tip-*` | 同 `iphone69-*` | 1320×2868 | 内购审核截图的原图，**不能直接传**，见下一节 |

打赏那一屏不在默认那几屏里，要单独出：

```bash
LOCALES=en APPEARANCES=light IPHONE_SCREENS=tip IPAD_SCREENS="" IPAD_PORTRAIT_SCREENS="" \
  SKIP_WIDGETS=1 ./scripts/capture-appstore-screenshots.sh
```

这一趟必须带 `-stub-tips`（`screen_args` 里已经写死）：scheme 上挂的 `TollCat.storekit`
只在 Xcode 启动 App 时注入，`simctl` 装起来的那份拿不到，真去问 App Store 只会拿到空数组，
截出来是「暂时无法连接 App Store」的空态。罐装的三档在 `MeterTips/StubTipCatalog.swift`，
金额和 App Store Connect 上的基准价一样，改价两边一起改。

小组件那几格为什么是渲的：**主屏上的 widget 截不到**——`simctl` 不认识它，往模拟器
主屏上加一格只能靠人手点。所以 App 自己把每一格渲成 PNG 落到沙盒
（`-dump-widget-tiles`，见 `DeveloperWidgetTileDump`），渲的是 widget 扩展用的
**同一份视图**（`WidgetModuleTile`）、同一份仪表内容、`shared/widgets.json` 里的
同一组尺寸——所以图上的数字和同一批截图里的仪表盘对得上，尺寸和用户装到主屏上的
那一格也一样。「我的服务」和「预算线」两块的内容来自版式里的钉选和预算，演示种子
两样都没有，那一趟单独用 `-pin-accounts=` / `-monthly-budget=` 给。

## 简体中文那一套用的是另一份演示数据

**中国大陆不许在元数据里出现 OpenAI / ChatGPT**（App Review Guideline 5：深度合成
服务要 MIIT 许可，我们 2026-09-09 因为 en-US keywords 里的 `openai` 被驳过一次，
往来和申辩口径在 `review-reply-china-dst.md`）。App Store Connect 的截图是**按语言**
上传的，所以 zh-Hans 那一套图要一份不含这些名字的演示数据，en-US / ja 两套照旧。

分流靠启动参数，不靠「跑之前先手改 fixture」——那种步骤迟早把合规改动静默冲掉：

| | 默认（en / ja） | `-demo-fixtures=cn`（zh） |
| --- | --- | --- |
| 预付余额范例 | OpenAI 余额 $42.00 | DeepSeek 余额 $42.00（国内已备案） |
| 即将扣款的订阅 | ChatGPT Plus $20.00 | Vercel Pro $20.00 |
| 已退掉的订阅 | ChatGPT Team / Midjourney Standard | GitHub Team / Figma Professional |

覆盖文件是 `Packages/MeterKit/Sources/MeterProviders/Fixtures/cn-*.json`，只放和默认
**不一样**的那几个，其余照旧读不带前缀的那份；接法见 `FixtureOverlay`。截图脚本的
`locale_fixtures()` 按语言决定带不带这个参数，`LOCALES=zh` 自动就是 cn 那一套。

两套的金额和曲线是逐个对齐的（合计 47.20、同比 +62%、续航 43 天都不变），所以换了
数据版式不会变形，两套图共用一次构建。`FixtureAggregationTests` 里有三条闸看着：
合计一致、OpenAI 在 cn 里必须是未接入、cn 的订阅名不许出现那几个词。

## 内购审核截图（iap-review/）

```bash
python3 scripts/render-iap-review-screenshot.py     # iphone69-tip-* → 640×920
```

**商店页的尺寸在这里一律不收。** 内购那个上传框是另一套老规格，只认 **640×920**，
传 1320×2868 会红「The dimensions of one or more screenshots are wrong」。所以这一步
从 `iphone69-tip-*` 顶上按 640:920 裁一刀再缩，顺便去掉 alpha（同样不许带透明通道）。

三个内购（糖果 / 咖啡 / 披萨）传同一张就行：一张图里三档并排，另外那句
「A tip — nothing gets unlocked.」也在画面里，审核员要确认的两件事一次看全。

## 机身（真机机壳）

```bash
python3 scripts/render-appstore-devices.py           # 截图 → 嵌进 Apple 官方 Product Bezel
```

机壳来自 developer.apple.com 的 Product Bezels，缓存在 `.cache/apple-bezels/`（不进 git），
清单和开孔在 `scripts/apple_bezels.py`——**落地页用的是同一份**。以前商店图的手机框是
CSS 画的一个圆角黑框，同一个 App 在落地页和商店页长着两台不同的机器。

开孔和截图是像素级 1:1（6.9" iPhone 1320×2868、11" iPad 2420×1668 / 1668×2420），
嵌进去一个像素都不用缩。产物是透明背景的 PNG，落在 `.tmp-task-marketing/devices/`。

## 宣传图（marketing/，上传用这个）

真机机身之上加标题。明暗两套主题全量生成（`-light` / `-dark` 后缀，各用对应外观的
截图），上传时任选一套：

```bash
node scripts/render-appstore-marketing.mjs                       # 全量 84 张
ONLY='ipad13-*' node scripts/render-appstore-marketing.mjs       # 只出 iPad 那一档
ONLY=ipad13-widgets-zh-light node scripts/render-appstore-marketing.mjs   # 只出一张
ONLY='*-widgets-*,ipad13-services-*' node ...                    # 逗号分隔，能用 *
```

## 只重出需要的那几张

产物名就是 `<档>-<屏>-<语言>-<明暗>`，三段流水线每一维都能单独收窄。
**改一处版式不要跑全量**——一轮截图二十分钟起，宣传图三分钟，为了一张图跑一整轮是纯浪费。

```bash
# 只重截 iPad 横屏的服务一览、只要中文浅色
LOCALES=zh APPEARANCES=light IPAD_SCREENS=services IPHONE_SCREENS="" \
  IPAD_PORTRAIT_SCREENS="" SKIP_WIDGETS=1 SKIP_BUILD=1 \
  bash scripts/capture-appstore-screenshots.sh

python3 scripts/render-appstore-devices.py ipad11-services   # 只嵌这一屏
ONLY='ipad13-services-zh-light' node scripts/render-appstore-marketing.mjs
```

| 想改什么 | 从哪一步起跑 |
| --- | --- |
| 只动了 `frames` 表里的坐标 / 标题 | 只跑 marketing（素材和机身都没变） |
| 换了机壳 / 换了截图 | devices → marketing |
| 改了 App 界面 | capture（带 build）→ devices → marketing |
| 只改小组件那一页的摆法 | 只跑 marketing；换摆哪几格也只要 marketing |

截图脚本的开关：`LOCALES` / `APPEARANCES` / `IPHONE_SCREENS` / `IPAD_SCREENS` /
`IPAD_PORTRAIT_SCREENS` / `WIDGET_DEVICES`（phone、pad）/ `SKIP_BUILD` / `SKIP_IPHONE` /
`SKIP_IPAD` / `SKIP_WIDGETS`。传空串就是「这一档整个跳过」。

帧结构轮换，同一档里没有两屏同构（配置在脚本 `IPHONE_FRAMES` / `CANVASES` 的 frames 表，
坐标一律写成画布比例，所以 6.5" 档和 6.9" 档共用一份）：

| 屏 | iPhone | iPad |
| --- | --- | --- |
| dashboard | 居中经典，纸底 | 横竖两台叠着，纸底 |
| detail | 放大微倾 -3°，品牌 indigo | 横屏微倾 -2°，indigo |
| services | 图标墙 + 单机，纸底 | 同一堵墙横过来铺满 + 横屏机身，纸底 |
| wizard | 放大微倾 +3°，indigo（与 detail 镜像） | 字在左、竖屏机身在右，indigo |
| widgets | 主屏 mock-up（四格），纸底 | 主屏 mock-up（七格），字在左、机身在右，纸底 |

图标墙由 `dump-marquee-svgs.cjs` 现场从站点源码求值，和落地页同一堵。

**只有一台竖着的机身时字排到旁边**（`sidebyside`）：4:3 的画布上把标题压在头顶，
左右会空出一大片；一横一竖才填得满。横着的机身仍然是标题在上。

iPad 的服务一览走**分栏壳**（`UsesPadChrome` 只在 regular 且宽 > 高时开），
右半边不选一家就是空态——所以横屏那趟截图带 `-open-provider-detail=aws`。
竖屏是列表壳，点开是全屏推进，不用选。

主屏 mock-up 那两页：壁纸、状态栏和那层毛玻璃底材是图这一层搭的，一格格里的内容是
App 渲出来的真视图（见上）。手机上摆四格，挑的是**四种长得不一样的**——一个大数字、
一张格子图、一只圆环、一列服务；摆四格同一种说明不了「不止一种」。iPad 竖屏一次
摆得下**七格**，正好是全部七块，标题说「7 种」图上就摆得出七种。

**手机和 iPad 的一格不一样大**（iPad 的 4×4 是正方的 342×342，不像手机上那样高出
一倍），所以素材是两套：`widget-phone-*` 和 `widget-pad-*`，各自在对应的模拟器上渲，
尺寸取自 `shared/widgets.json` 的 `frames.phone` / `frames.pad`。

宣传图命名 `iphone65-*`（1284×2778，必填档）/ `iphone69-*`（1320×2868，选传档）/
`ipad13-*`（2752×2064，ASC 的 iPad 档位叫「13-inch display」——那是画布尺寸，
画布里摆的是 11" 机身）。上传顺序按叙事排：
dashboard（一眼看出花了多少）→ detail（钱花在哪了）→ services（80 多家都能接）→
wizard（每家都有接入说明）→ widgets（主屏上就看得见）。iPad 五张同序。

标题在脚本 `COPY` 表，每行行尾都不带任何标点；改标题过 BRAND.md 标题层的规矩；
每张图都带「演示数据」小注（BRAND 红线）。小组件那一页标题里的种数写成 `{n}`，
从 `shared/widgets.json` 数出来——写死一个数字，加一块模块之后那行字就成了假话。
原始无框截图留在 `screenshots/` 备用。

`scripts/check-app-store-invariants.py` 守着这批产物：尺寸、成套（每屏 3 语 × 明暗
一张不少）、不带透明通道、每档不超过 10 屏。

## 上传

注意：ASC 版本页 iPhone 的必填档是 6.5"（1242×2688 / 1284×2778），直接拖 1320×2868
会被拒。上传 `marketing/` 的 `iphone65-*`；Media Manager 里的 6.9" 档可以再传
`iphone69-*`（选传，Pro Max 原生分辨率），其余尺寸档全部留空让它 fallback。

每档最多 10 张，前 3 张会出现在安装页。上传入口：版本页 → View All Sizes in Media Manager。

## 文案（metadata/）

| 文件 | 贴到 | 上限 |
| --- | --- | --- |
| `description.txt` | Description | 4000 |
| `keywords.txt` | Keywords | 100 |
| `promotional_text.txt` | Promotional Text（改动不需要重新审核） | 170 |
| `review-notes.md` | App Review Information → Notes | 4000 |

语言目录对应 ASC 的本地化：`en-US` / `zh-Hans`（简体中文）/ `ja`（日本語）。
副标题（App Information → Subtitle）用品牌主句，见 BRAND.md 第零节。
文案改动走 BRAND.md 验收；review-notes.md 里的占位符提交前必须替换。
