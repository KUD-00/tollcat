# tollcat.app

TollCat 落地页。静态 HTML，挂到 Cloudflare Workers Static Assets，顶级域 `tollcat.app`。

`api.tollcat.app` 仍是 `worker/` 里的 API，不要把这份站点绑到那个 Worker 上。

## 本地

```bash
cd site
pnpm install
pnpm dev
```

浏览器打开终端里打印的地址（默认 `http://localhost:4321/`）。

- 中文：`/zh-hans/`
- English：`/en/`
- 日本語：`/ja/`
- `/` 是入口：有 JS 时按浏览器语言跳到上面三个前缀之一。无 JS、爬虫仍看到中文首页，canonical 指向 `/zh-hans/`。
- 隐私：`/privacy/`（App Store 用，和 `/zh-hans/privacy/` 同一页）
- 支持：`/support/`（App Store 用）
- 更新说明：`/zh-hans/changelog/`。发版时在 `src/changelog.ts` 数组最上面加一条，三语一起写。合进 main 就上线。同样有 `/en/changelog/`、`/ja/changelog/`；无前缀的 `/changelog/` 仍可用。
- 服务支持清单：`/providers/`。首页接入区块和页脚的链接，有 JS 时在首页开成 dialog；无 JS、新标签、爬虫都落到这一页。三语同样有 `/zh-hans/providers/`、`/en/providers/`、`/ja/providers/`。
- 凭据区块在「能接哪些」和 FAQ 之间。标题里的 `*` 和说明里的链接，有 JS 时开成左右滑动的说明；无 JS 落到隐私政策。
- 平台区块在凭据和 FAQ 之间。三个按钮（iPad / Mac / 安卓）有 JS 时开对应说明；无 JS 时 Mac / 安卓落到 GitHub。
- 出现在介绍里：`/sponsors/`。厂方谈在对应服务介绍里出现，不是落地页广告。三语同样有 `/zh-hans/sponsors/`、`/en/sponsors/`、`/ja/sponsors/`。
- 外观：页头可在浅色、深色、跟随系统之间切换；选择写在本机 `localStorage`。无 JS 时跟随系统配色。
- 语言：三语对等，`/zh-hans/`、`/en/`、`/ja/`。有 JS 时，无前缀路径会跳到带前缀的地址；选择写在本机 `localStorage`，页头再切会覆盖。爬虫不跳。
- Agent 目录：`/llms.txt`，全文：`/llms-full.txt`。各页另有同路径 Markdown（`/zh-hans/index.md`、`/zh-hans/privacy.md`、`/en/index.md` …）

生产构建预览：

```bash
pnpm build
pnpm preview
```

用 Wrangler 在本地模拟 Cloudflare（仍然不上传）：

```bash
pnpm preview:cf
```

## 上线

1. `src/config.ts` 里填 `appStoreUrl`、`appId`。`githubUrl` 指向仓库，私有也可以放页头链接。空则不显示 GitHub 图标。
2. `pnpm build && pnpm wrangler deploy`。custom domain 用 apex `tollcat.app` 和 `www.tollcat.app`，不要抢 `api.tollcat.app`。
3. 上线后把 App Store Connect 的 Privacy URL / Support URL 指到 `/privacy/` 和 `/support/`（联系我们仍挂这条路径）。

## 落地页截图

机壳里的画面：

- iPhone：`src/assets/screenshots/iphone-{dashboard|wizard|services}-{zh|en|ja}-{light|dark}.png`。18 张屏幕。机身是官方 iPhone 17 Pro Product Bezel（浅色 Silver / 深色 Deep Blue），`PhoneFrame` 叠在画面上，锁屏动画仍在开孔里。
- 平台页：iPad 11" 横屏、Mac 主窗口、Mac 菜单栏面板；Android 仪表在 JNI 对得上、模拟器没 ANR 时才写入。`bash scripts/capture-site-platform-screenshots.sh`（iPad 默认同 `docs/appstore/screenshots`；Mac / Android 现截。Android 先 `scripts/android-run.sh`）。脚本末尾会跑 `scripts/composite-site-device-frames.py`：导出 iPhone 17 Pro 机壳叠层，并把 iPad / Mac 嵌进官方 Product Bezel（iPad Pro 11" / MacBook Pro 14"）。机壳清单、开孔和合成都在 `scripts/apple_bezels.py`——**商店宣传图用的是同一份**，两处不许各写一遍。开孔是量出来的（屏幕那块透明，从图边泛洪一遍剩下的就是它），量到的结果缓存在 `.cache/apple-bezels/holes.json`。原版 bezel 也缓存在那儿，不进 git；落地页用的是 `iphone-17-pro-*`、`ipad-bezel-*`、`macbook-window-*`。

语言跟页面走，亮暗跟页头主题走（和厂标 marquee 同一套 `<picture data-theme-src>`）。

数字锁死 SPEC 第 04 节那组（AWS $21.40 / 合计从量 $43.20）。历史月在 `Packages/MeterKit/Sources/MeterProviders/Fixtures/*.json` 的 `olderMonths`，改完跑 `FixtureAggregationTests`，当月向量不能动。

下次换图，按这个顺序。机械步骤也可以直接跑 `bash scripts/capture-site-screenshots.sh`（包已经编过则 `SKIP_BUILD=1`）。

1. **种子**  
   只改 fixture JSON。当月合计必须仍是 $47.20。  
   `xcodebuild -project TollCat.xcodeproj -scheme TollCat -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:MeterKitTests/FixtureAggregationTests test`

2. **Debug 包装进 iPhone 17 Pro**  
   分辨率要 1206×2622，和现在这些 PNG 一致。  
   `xcodebuild -project TollCat.xcodeproj -scheme TollCat -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /tmp/dd-site-screenshots build`

3. **状态栏**  
   启动 App 会清掉覆盖，必须在画面出来之后、截图之前再钉：  
   `xcrun simctl status_bar booted override --time "9:41" --batteryState charging --batteryLevel 100 --cellularMode active --cellularBars 4 --wifiMode active --wifiBars 3 --dataNetwork wifi --operatorName ""`

4. **每个 (locale, appearance)** 先卸再装，空库。外观同时设模拟器系统外观和 `-appearance=`，否则状态栏和图标会对不上。

5. **三屏启动参数**（都加 `-clock-preset=design -stub-catalog -stub-inbox -stub-usage-analytics -stub-feedback -AppleLanguages … -AppleLocale …`）  
   - 仪表：`-seed-demo -skip-onboarding -hide-cat`（落地页截图关掉猫）  
   - 服务：同一份已灌的库，`-seed-demo -skip-onboarding -start-on-services`（不要卸）  
   - 向导：必须再卸再装。空库弹出 Cloudflare 连接参考抽屉。`-skip-demo-seed -skip-onboarding -start-on-services -open-setup=cloudflare`

6. **语言**  
   中文 `-AppleLanguages "(zh-Hans)" -AppleLocale zh_CN`  
   英文 `-AppleLanguages "(en)" -AppleLocale en_US`  
   日文 `-AppleLanguages "(ja)" -AppleLocale ja_JP`

7. **截图**  
   `xcrun simctl io booted screenshot site/src/assets/screenshots/iphone-<screen>-<locale>-<appearance>.png`  
   只要屏幕，不要模拟器窗口边框。机身是官方 iPhone 17 Pro bezel，由 `PhoneFrame` 叠上。

8. **接线**  
   文件名对上 `site/src/screenshots.ts` 的 import。`Home.astro` 按 locale 取图。不必改组件，除非增屏。

9. **看一眼**  
   `cd site && pnpm dev`。`/`、`/en/`、`/ja/` 各开一次，页头浅色 / 深色 / 跟随系统都切一下。机内文字语言要跟页面走，亮暗要跟外壳走。

## 为什么是 Astro

落地页要的是可被抓取的 HTML 和能打满分的 Core Web Vitals。Astro 默认几乎零 JS：FAQ 用原生 `<details>`，语言切换是 popover 链接。首页有一段很小的 IntersectionObserver，用来在滚动时只换 sticky 机壳里的屏幕，机身不动。凭据那一屏是 CSS 动画：各家图标收进一把锁。
