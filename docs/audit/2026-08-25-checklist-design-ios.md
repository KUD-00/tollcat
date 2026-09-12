# checklist.design · iOS 对照

> 对照源：[checklist.design](https://www.checklist.design/)（Mobile + 对得上的 Flows / Design system / Web app 条目）。
> 审计：2026-08-25。P1 实装：同会话后续。本文更新：2026-09-08。
> **只查 iOS。** Android / Windows / CLI 不在范围。
> 验证方式：源码对照，没有上真机跑 VoiceOver、滚动收起 tab、启动时长。
>
> 产品行为仍以 [SPEC.md](../SPEC.md) 为准，视觉验收以 [DESIGN-BAR.md](../DESIGN-BAR.md) 为准。
> 本文是**欠账和有意不做**，不是新的产品合约。和 SPEC 打架时先改 SPEC，再改代码。

三种不要混：

| 种类 | 怎么处理 |
|---|---|
| **真缺口** | 改了用户会更好 |
| **和自家基准打架** | 先改 SPEC / DESIGN-BAR，再改代码 |
| **产品有意不做** | 清单条目标 N/A，不要当 bug 修 |

---

## 总评（审计当时）

适用条目大约 140+。粗分：已对齐 ~55%；产品有意不做 ~15%；真实缺口 ~30%。

**没有 P0**（主路径走不通的项）。

Windows / CLI 的 SPEC 里也有叫「P2」的段落，和这份清单无关。

---

## 不适用（产品没有这些表面）

这些清单**不该拿来改 App**：

| 清单 | 原因 |
|---|---|
| Login / Sign up / Profile / Referral / Invite | 无账号，凭据只在本机 Keychain |
| Camera / Map / Chat / Cart | 不做 |
| Paywall | 免费；打赏是消耗型 IAP，不解锁功能 |
| Checkout 的地址/卡号表单 | 付款走系统 StoreKit 表 |
| In-app notifications 信息流 | 没有站内通知 inbox；「读数信箱」是投递账单的 mailbox |
| Website 整类、Admin、Kanban、Feed 等 | 网站/后台，不是这套 iOS |

Restore purchases / 管理订阅：消耗型打赏，Apple 不要求 restore。标 N/A。

---

## P0

无。左缘返回没关；启动页没有人为延时；主路径（看数字、加服务、填凭据）走得通。

---

## P1

审计时的上架/主路径项。实装状态以「现状」列为准。

| # | 清单 | 问题 | 现状 |
|---|---|---|---|
| 1 | [Settings #8 Legal](https://www.checklist.design/mobile/settings) | 设置/关于没有隐私政策、条款链接。站点有 `/privacy/`、`/support/`，App 没接。 | **已做。** 关于页 `SafariLink`：隐私政策、支持。按语言走 `/`、`/en/`、`/ja/`。站点没有服务条款页，没有造空链。 |
| 2 | [Dashboard #3](https://www.checklist.design/mobile/dashboard)、[Gesture #3](https://www.checklist.design/mobile/gesture-navigation) | 仪表没有下拉刷新，只有右上角刷新。 | **已做。** 仪表手机列表和 iPad 两列走 `meterRefreshable`。 |
| 3 | [Action Sheet #3](https://www.checklist.design/mobile/action-sheet)、Deleting account、Error prevention | 划掉订阅、划掉投递 key 没有确认。 | **已做。** `confirmationDialog`，文案写清后果。 |
| 4 | [In-App Browser](https://www.checklist.design/mobile/in-app-browser) | 教程和官网账单用系统 `Link`/`openURL`，没有应用内 Safari（URL 栏、关闭、分享、加载条）。 | **只做无障碍。** 产品有意跳出到系统 Safari（拿 API Key 时更不容易被钓鱼）。`SafariLink` 的 VoiceOver hint 是「在 Safari 打开」。不要改成 WKWebView。 |
| 5 | Accessibility 热区、Dashboard | 筛选月份芯片小于 44pt。 | **已做。** `MeterSpacing.minTap`。 |
| 6 | Action Sheet / Modal 关闭 | 分享卡手写 `xmark` 和 `presentationDetents`。 | **已做。** `Button(role: .close)` + `meterDrawerChrome`。 |
| 7 | Loading vs DESIGN-BAR | 服务页 `.refreshable` 带系统转圈；DESIGN-BAR 刷新不许转圈。 | **已做。** 一律 `meterRefreshable`，藏掉系统转圈。闸：`check_refreshable` / `RefreshableGuardrailTests`。 |

相关代码：`LegalURL.swift`、`AboutView.swift`、`MeterRefreshable.swift`、`ProviderDetailView.swift`、`InboxSettingsView.swift`、`SafariLink.swift`、`DashboardFilterSheet.swift`、`ShareCardSheet.swift`。

---

## P2

编号接审计当时的分条，方便对照会话。**全部未作为产品任务关掉**，除非下面注明「有意」或「不必当缺口」。

### 启动

对照 [Splash Screen](https://www.checklist.design/mobile/splash-screen)。

1. **启动猫和下一屏构图对不上。** 启动页猫在右下（`LaunchScreen.storyboard`：trailing 20、bottom 16）。Onboarding 猫居中偏上。已引导则下一屏是 tab，猫更小、坐在构成卡上。清单要有意识的过渡，现在是硬切。
2. **启动猫可能压 Home Indicator。** 约束绑根视图底边，不是 safe area。未上真机量过。

### Tab 和手势

对照 [Tab Bar](https://www.checklist.design/mobile/tab-bar-navigation)、[Gesture navigation](https://www.checklist.design/mobile/gesture-navigation)。

3. **切 tab 没有触觉。** **已做（2026-09-08）。** `RootView` 切三个入口发 `.selection`。DESIGN-BAR 第八节改成允许这项——系统 iOS 26 tab 不保证自带触感，手指挡住图标时要 App 自己确认点中了。真机仍建议摸一下，避免和系统触感叠成两下。
4. **Tab 上没有 badge。** **有意。** 从来不打算有。告急在仪表「需要注意」。
5. **滚动收起 tab bar 可能是空操作。** 写了 `.tabBarMinimizeBehavior(.onScrollDown)`。SPEC 自注：绑了 `NavigationStack(path:)` 的 tab 可能不触发。三个手机 tab 都绑了 path。必须上机滚一下。
6. **已接入的服务行不能划。** **有意。** 误触风险。删一家走详情底的红色项。
7. **几乎没有长按菜单。** **这轮不做。** 若以后加，只加在「复制 / 跳进某一页」这种不会误删的地方，见文末「长按会加在哪」。
8. **不能拖着排序服务。** **有意 / 假需求。** 服务用菜单「类别 / 价格」。仪表模块的拖拽排序是另一件事，走「编辑仪表盘」，要留。
9. **没有手势提示。** **有意 / 以后再说。** SPEC 禁止 coach mark；也许写进利用指南。

### 第一次打开

对照 [Onboarding](https://www.checklist.design/mobile/onboarding)、[Onboarding Checklist](https://www.checklist.design/mobile/onboarding-checklist)、[Help Center](https://www.checklist.design/web-app/help-center)。

10. **进度只有三个点，没有「第几步」。** **开场其实已经有。** 导航栏中间是 `1 / 4`，圆点给 VoiceOver 读「第 N 页，共 M 页」。审计当时漏看了 toolbar。接入向导原先没有，见 13。
11. **开场不做个性化。** **整理结论，这轮不加页。** 货币已经在第 1 页。外观跟系统、提醒不在开场要权限、不要问名字。详见文末「开场该设什么」。
12. **没有新手任务清单。** **有意。** 服务没那么复杂，开场 + 接入向导够了。
13. **接入向导没有总进度；部分抽屉只能下拉关。** **已做（2026-09-08）。** 手机向导导航副标题 `1 / 2`，VoiceOver「第 N 步，共 2 步」；横屏 iPad 两栏并排，副标题 `1–2 / 2`。向导、更新说明、利用指南、提醒预授权都走 `meterSheetClose`（系统 X），不再只靠下拉。
14. **利用指南不像帮助中心。** **暂不下架范围外。** 利用指南暂时不摆进设置页。

SPEC 里利用指南的**产品决定**（冷启动一篇、禁止 coach mark）在第 12 节，不是这份欠账。

### 仪表（2026-09-08 重看）

对照 [Dashboard](https://www.checklist.design/mobile/dashboard)。审计当时的 15–18 有过时的，以现在源码为准。

手机有数据：`List` 第一节是 `DashboardCatStage`（合计 + 构成 + 较上月同期 + 近几个月 + 猫），后面按版式把模块分成节（相邻「需要注意」并成一节），**最底下** `DashboardActionRow` 分享 / 编辑仪表盘。下拉刷新走 `meterRefreshable`。筛选、刷新、编辑在导航栏；筛选在 iPad / Mac 是挂在按钮上的 popover。空态是睡觉的猫 +「还没有账单」；刚清完全部数据换成「已清除全部数据」。

宽壳：`DashboardPadLayout` 一列 bento，侧栏可钉一块一格宽模块。

15. **拇指区：主角仍在上半屏。** 分享 / 编辑已经在页尾。刷新是下拉 + toolbar。筛选仍在 toolbar。清单要主操作在下 2/3；DESIGN-BAR 把刷新钉 toolbar、禁止 FAB。**和自家基准打架，不是漏做。**
16. **快捷操作不完整。** 空态没有刷新（没数据可刷）；「再加一家」在服务 tab，仪表空态按钮跳过去。有数据时仪表不放「再加一家」。**不必当缺口。**
17. **模块不能按人藏、排序。** **过时。** SPEC 第 05 节现在就是可排序可隐藏；「编辑仪表盘」里开关、拖动，Mac 还可右键上移 / 下移。侧栏钉哪一块也在这里。不要再当欠账。
18. **失败不是每一块自己的错。** 刷新失败仍是页脚一句总说明。服务行有「数据陈旧」，仪表主角数字分不清是哪家挂了。**仍欠。**

### 设置、删除、保存

对照 [Settings](https://www.checklist.design/mobile/settings)、[Deleting account](https://www.checklist.design/flows/deleting-account)、[Saving changes](https://www.checklist.design/flows/saving-changes)。

19. **「清除全部数据」不是列表最后一项。** **已做。** 单独一节，整份设置最后；「其他」（反馈 / 关于）在它上面。
20. **清完没有成功态。** **已做。** 成功触感，切回仪表空态，标题「已清除全部数据」。
21. **外观/货币改了没有确认。** **不必。** 即时写入，和系统设置一样。
22. **不能从别处一键跳进某一项设置。** **已做。** `tollcat://settings` 及 `/inbox` `/import` `/feedback` `/about` `/tip` `/whats-new`；`/reminders` 落在列表第一屏。点通知也进设置第一屏。

### 搜索和筛选

对照 [Search](https://www.checklist.design/mobile/search)、[Filtering items](https://www.checklist.design/flows/filtering-items)。

23. **进添加服务页，键盘不保证自动弹出。** **不必。**
24. **没有最近搜索。** **不必。** 目录短。
25. **搜索开着自动更正。** **已做。** `meterColumnSearchable` 关掉自动更正和自动大写。
26. **仪表上不能一键清空筛选。** 抽屉里服务有「全选」；三轴一起恢复默认没有。
27. **筛到 0 家仍显示金额 $0。** 抽屉有警告；主界面不像「没有结果，请放宽筛选」，容易理解成这个月没花钱。**优先。**
28. **没有结果数量。** 只有预览金额。账单场景金额更有用。

### 通知授权

对照 [Push Notification Opt-in](https://www.checklist.design/mobile/push-notification-opt-in)。

时机是对的：不在 onboarding 要权限。

29. **没有预授权屏。** **已做。** 系统还没问过时，开关先弹出预授权，说明「通知里不会出现金额」，主按钮才是「打开通知」。关掉预授权不弹系统框。
30. **没有通知长什么样的预览。** **已做。** 预授权里用和真通知同一份文案画一帧预览。

### 表单和错误

对照 [Showing input error](https://www.checklist.design/flows/showing-input-error)、[Saving changes](https://www.checklist.design/flows/saving-changes)。

31. **校验在点「测试连接」之后，不是失焦；再聚焦红字不消失。**
32. **「保存」不是脏了才可点。** 筛选「用这个」做对了；设置开关即时保存。
33. **打赏失败没有触觉。** DESIGN-BAR 现在允许的触发里仍然没有打赏失败。**和自家基准打架，先改 DESIGN-BAR 再加。**
34. **反馈发送带系统转圈。** 清单要提交 loading；DESIGN-BAR 禁的是账单刷新转圈。**不必当缺口。**

### 打赏

对照 [Billing](https://www.checklist.design/mobile/billing)。消耗型，不是订阅。

35. **没有「怎么退款」。** 退款走 Apple，App 里没有说明或链接。
36. **没有能拿去报销的收据。** 只有应用内历史行。
37. **没有解释含税。** 价格由 StoreKit 出。

### 帮助

对照 [Contacting support](https://www.checklist.design/flows/contacting-support)。

反馈页本身：类型、正文、选填联系、环境信息摊开——过关。

38. **没说多久会回、走哪条渠道。** 成功只说「收到了，谢谢。」
39. **出错的地方没有「去反馈」。** 刷新失败是页脚一句。

### 无障碍和动态字体

对照 [Accessibility](https://www.checklist.design/design-system/accessibility)、DESIGN-BAR 第八节。视力正常用户感觉弱，对部分用户接近 P1。

40. **有的金额 VoiceOver 仍读 `$`。** 主角数字、服务行、Widget 走 `SpokenMoney`；筛选预览、构成详情行还读格式化金额。
41. **`lineLimit(1)` 且不缩小。** 服务名、构成详情。XXL 会截断。
42. **主角数字 `minimumScaleFactor(0.6)` 可能小于 11pt。**
43. **「增强对比度」管不到猫和品牌块。** DESIGN-BAR 允许这两个 hex 例外。
44. **没做过 RTL，没在真机跑过 VoiceOver / XXL。** 验证缺口。
45. **分享动作图标固定 26pt，装在 56×56 圆里。** 动态字体可能撑破。关闭按钮已改（P1-6），这排没改。
46. **Widget 空态可能把猫的心情和空态文案读两遍。** 有数据时子视图 `accessibilityHidden`；空态 `.combine`。

---

## 已对齐、不要当缺口

- 三个 tab，图标+文字；系统 tab bar
- 大标题；仪表标题是月份
- 启动页无按钮、无人为延时
- 左缘返回没有被关
- 空态：仪表「还没有账单」和服务「还没有接入服务」文案刻意不同；刚清完数据是「已清除全部数据」
- 开场导航栏写 `1 / 4`；接入向导写 `1 / 2`
- 切 tab 有选择触感
- `tollcat://settings/…` 能跳进设置某一项
- 添加服务搜索空结果用系统 `ContentUnavailableView.search`
- 清全部 / 删厂商 / 删信箱有确认，写清 Keychain / Snapshot
- 通知权限不在 onboarding 要
- 打赏走 StoreKit，失败/取消/待处理有说明
- 版本号在设置「关于」
- Widget 用系统 `containerBackground`，金额有 spoken（有数据时）
- iPad 横屏三栏、竖屏回 iPhone 壳（SPEC）

---

## 若要接着改，先做这些 P2

用户会骂、不是清单扣分：

1. 筛到 0 家显示 $0（P2-27）
2. VoiceOver 金额读法不统一（40）、XXL 截断（41）
3. 刷新失败不点名是哪家（18）
4. 启动猫构图硬切 / 可能压 Home Indicator（1、2）

不要当 bug 修：服务行划掉（6）、服务拖着排序（8）、coach mark（9）、新手任务清单（12）、无账号头像行、应用内浏览器改 WKWebView（P1-4）、tab badge（4）。仪表主操作必须在拇指区（15）要先改 DESIGN-BAR。

---

## 长按会加在哪（P2-7，这轮不加）

只加「复制 / 跳进某一页」，不加删除、结束服务——那些已经有确认对话框，长按菜单更容易误触。

值得加的地方：

1. **仪表合计数字** — 复制「本月至今」金额。现在只能靠分享卡。
2. **构成条 / 构成详情的一家** — 跳进这家服务详情（点按已经能进；长按可当 Peek）。
3. **服务列表已接入的一行** — 刷新这一家、复制显示名、打开官网账单。不要在这里放结束 / 删除。
4. **设置「关于」的版本号** — 复制 `X.Y.Z (build)`，给反馈用。
5. **接入向导里的控制台链接 / 权限字** — 已经有复制按钮的不要再叠一份长按。

不要加的地方：空态、开场、tab、已接入行的删除、模块编辑（已经有拖拽和开关）。

---

## 开场该设什么（P2-11）

只问第一次不用、以后很难改、会立刻改变看到的数字的东西。

| 问什么 | 结论 |
|---|---|
| 显示货币 | **要，已经在第 1 页。** 账本按美元记，显示货币一改，开场标本和之后的仪表是同一套数。 |
| 外观 | **不要。** 默认跟随系统。想换再去设置，和系统设置同一习惯。 |
| 提醒 / 通知 | **不要。** SPEC：权限不在开场要。系统框只能弹一次，这时候人还没看到账单。 |
| 名字 / 时区 / 语言 | **不要。** 无账号；时区、语言跟设备。 |
| 关掉猫猫 | **不要。** 还没见过猫在账单旁边干活。 |
| 进入 App 自动刷新 | **不要。** 默认关；人还没接上第一家。 |
| 你用哪几家 | **不要。** 目录不长，第 4 页就是「添加第一个服务」，预勾等于把接入向导做两遍。 |

所以开场个性化的缺口其实只有「货币」这一项，而且已经有了。不要再加一页问卷。
