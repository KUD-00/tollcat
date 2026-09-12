# 设计基准

**目标：让人以为这是 Apple 自己出的 App。**

这不是一句鼓励的话，是验收标准。任何 UI 任务在"功能对了"之后还要过这一关。

---

## 零、`SPEC.md` 里那张设计稿只是信息架构参考

规格里的手机 mockup 是一张 **HTML 网页**。它说明的是"哪一屏放什么、回答什么问题"，
**不是 iOS 的视觉规范**。

- 它的**信息架构**有效：三个 tab、仪表回答"会花多少"、服务管理接入、向导五步等等
- 它的**视觉决定全部作废**：CSS 色板、等宽字体、卡片样式、仪表弧、间距数值

**冲突时以本文和 Apple HIG 为准，设计稿让路。** 不要再从那份 HTML 里搬任何视觉决定。

（第一版就是把那份 CSS 变量原样搬进了 iOS，结果是一个"在 SwiftUI 里渲染的网页"：
等宽字体的说明文字、土棕色的大弧、白色浮起卡片墙、圆形浮动刷新按钮。全部推倒。）

---

## 一、字体：只有系统字体

**禁止 mono 字族。** 唯一例外是真的在展示代码或 JSON（比如向导里那段 IAM policy）。

- 说明文字、caption、字段标签、金额、百分比、日期——**全部系统字体**
- 数字需要对齐不跳动时，用 **`.monospacedDigit()`**（系统字体的等宽数字变体），
  不是换成 mono 字族
- 字号只用语义字号（`.largeTitle` / `.title` / `.body` / `.subheadline` /
  `.footnote` / `.caption`），并且**只写 `MeterFont.*` 语义名**，不直接写 `Font.*`。
  只有页面主角那一个数字可以写固定 size
- macOS 上语义名映射到不同的系统样式（`MeterFont` 里唯一一处 `#if os(macOS)`）：
  macOS 内建的 footnote / caption / caption2 全是 10pt，正好是 HIG 给 Mac 的底线，
  按 iOS 比例分配的注解到 Mac 上会整体落到底线、三档塌成一档。所以 Mac 上
  正文 13 / 次要 12 / 说明 11 / 三级标注 10，对齐系统设置的读法。视图不要自己判平台改字号
- 不要手动调 `tracking` / `kerning`。系统字体在各字号下的字距已经是调过的

一句话：**看到 `.monospaced()` 就是错的，除非它旁边是代码。**

## 二、颜色：系统语义色 + 一个 tint

### tint = `.indigo`

理由不是好看，是**它不占用语义位**：这个 App 要用红/橙表示"涨得反常""余额告急"，
用绿表示"在额度内"。品牌色若是暖色就和告警撞车，若是绿色就和"安全"撞车。
indigo 是系统色，自动适配深浅模式与辅助功能设置。

在 `TollCatApp` 上设一次 `.tint(.indigo)`，往下所有交互元素自动继承。

### 其余一律系统语义色

| 用途 | 用什么 |
|---|---|
| 页面背景 | `Color.meterGroupedBackground`（iOS 的 `systemGroupedBackground`） |
| 卡片/行背景 | `Color.meterSecondaryGroupedBackground` |
| 主文字 | `Color.meterLabel` |
| 次要文字 | `Color.meterSecondaryLabel` |
| 更次要 | `Color.meterTertiaryLabel` |
| 分隔线 | `Color.meterSeparator` |
| 危险/异常 | `.red` |
| 警告 | `.orange` |
| 正常/额度内 | `.green` |

**不要再定义 ground / surface / ink / rule 这类自造 token。** 系统的语义色会跟着
深浅模式、对比度设置、辅助功能一起变，自造的十四个色值不会。

### Provider 品牌色只活在图标块里

八家的品牌色**只**用于 28pt 的 `ProviderGlyph` tile 底色。**不进图表、不进文字、
不进任何大面积**。六个饱和色相铺在一屏上是上一版最刺眼的问题之一。

构成条用**同一色相族的梯度**（indigo 由深到浅）+ 中性灰表示"其他"，
下面配一排小圆点图例说明哪段是谁。参照系统设置里的「iPhone 储存空间」。
同厂商多个账号时，图例写账号标题（「Cloudflare · 工作」），**不要**按账号铺品牌色。

### 猫是定稿灰，深色只抬亮度

TollCat 的身体不是语义色，也不能用 `Color.secondary`：系统灰在深色里要么和
grouped 卡面糊成一团，要么亮到把白眼吃掉。浅色 `#6E747B`，深色 `#858C93`，
同一只冷灰，只改亮度。眼睛、嘴、眼镜深浅都是白，压在身体上至少 3:1。
ZZZ / 感叹号 / 骷髅跟身体走，不要另给一套。

## 三、控件：能用系统的就不要自己写

**先查系统有没有，有就用。** 下面这些都不许自造：

| 要做的东西 | 用系统的 |
|---|---|
| 分组列表 | iOS：`List` + `Section` + `.listStyle(.insetGrouped)`。Mac 设置页走 `MeterGroupedList`（grouped `Form`，系统设置那套）。仪表 / 服务仍是 `List`，Mac 把 `.insetGrouped` 别名成 `.inset`。调用点不要 `#if os` |
| 空状态 | `ContentUnavailableView` |
| 主按钮 | `.buttonStyle(.borderedProminent)` |
| 次要按钮 | `.buttonStyle(.bordered)` 或 plain |
| 表单字段 | `Form` + `TextField` / `SecureField` |
| 顶部操作 | `.toolbar { ToolbarItem(...) }` |
| 关掉 sheet | `Button(role: .close)`（系统 X）。**不要**手写「取消」或自造 xmark |
| 下拉选择 | `Menu` / `Picker` |
| 开关 | `Toggle`。Mac 默认是 checkbox；根上 `meterControlChrome()` 钉成 `.switch`，和系统设置同一颗。不要自己画，也不要留成勾选框 |
| 破坏性确认 | `.confirmationDialog` |
| 状态标签 | 系统字体 + 语义色文字，不是自造 pill |

**没有浮动圆形按钮。** 刷新放 `.toolbar`，不是右上角悬一个白色圆片——那是
Material Design 的 FAB。

**没有卡片墙。** 六张等重的白色圆角卡摞在一起是网页布局。用 `List` 的分组，
行与行之间是发丝分隔线（从图标右边起始），不是每行一张浮起的卡。

自造组件只在系统确实没有对应物时才写：`ProviderGlyph`（品牌图标块）、
构成条（`SegmentBar`）、向导的分步说明列表——就这三类。

## 三点五、导航栏

- **三个主屏（仪表盘 / 服务 / 设置）用系统的 `.large` 大标题。**
  `.navigationBarTitleDisplayMode(.large)`。toolbar 按钮回到标题上方那一行，
  交给系统。

  Apple 的 `.large` 结构是：

  ```
  状态栏
  [工具栏行 44pt]  ← 按钮在这里（没有按钮时这行是空的）
  [大标题 ~52pt]   ← 用户看到的「间距」就是上面那一行
  内容
  ```

  大标题和内容之间那截留白，不是缺了间距，是工具栏按钮行。`.inlineLarge`
  把这一行省掉，标题和按钮挤在同一行，看起来就像「贴顶」。那大约 55pt 的差距，
  正是被 `.inlineLarge` 省掉的按钮行。

  **不要用 `.inline`**（小号居中标题），也**不要用 `.inlineLarge`**
  （省掉按钮行）。不要自己做内容 header，不要手写折叠——系统的大标题→小标题
  过渡直接白拿。三种的区别：

  | 模式 | 效果 |
  |---|---|
  | `.large`（用这个） | 按钮在上、大标题在下，占两行。折叠过渡系统白送 |
  | `.inline` | 小号居中标题，和按钮同行 —— **标题变小了，不要** |
  | `.inlineLarge` | 大标题和按钮同一行 —— 省掉了上面那行按钮位，顶部会显得挤 |

- 标题要**承载内容**。仪表页的标题是当前月份（"八月"），不是"仪表"——
  和下面 tab bar 的标签一字不差地重复一遍，等于白占一行
- iOS 26 的 toolbar 有**共享玻璃底**：相邻的 item 自动成组，不要自己画容器。
  分组用 `ToolbarSpacer(.fixed, placement:)`，取消共享用
  `.sharedBackgroundVisibility(.hidden)`
- 页级偶发动作（分享、编辑仪表盘）进导航栏的系统 `Menu`（`ellipsis`），
  用 `ToolbarSpacer` 和刷新 / 筛选拆开。不要在 grouped list 底下自造两颗胶囊。
  菜单从玻璃按钮长出来是系统给的，不要手写 `glassEffect` / `GlassEffectContainer`

## 三点八、图表用 Swift Charts

`MeterDesign` 除 SwiftUI 之外**可以 import Charts**（系统框架，不是第三方）。
不要手写 `Path` 画图表。

图型按数据性质选，不按好看选：

| 数据 | 图型 | 理由 |
|---|---|---|
| 每日花费 | **柱形图** | 离散的每日金额；缺数据那天留空。折线会把缺口连成假的斜线。没有按日拆开的账单时，柱是两次读数之间新花的钱，记在读到的那天——仍是用量柱，不要另开一种图 |
| 近几个月从量 | **柱形图** | 月粒度；缺的月份留空，不要补 $0 |
| 预充值余额 | **折线** | 连续变化的量 |

按住柱或点：用系统的 `chartXSelection` + `RuleMark`，标出那天的数。缺数据写「无数据」，不要补 $0。不要自己画一根跟手的竖线。**可平移的日线图除外**：`chartXSelection` 的拖会把惯性平移吃掉，改成点一下对准那天。

7 / 30 天是看得见的宽度。时间轴用系统 `chartScrollableAxes` + `chartXVisibleDomain`，惯性白送。12 个月不滑。纵轴按整段一次定死。
| 本月构成 | **圆环**（`SectorMark` + `innerRadius`）+ 图例 | 中心留空。总额已经在圆环上方的主角数字里，再放一次是重复。超过 5 家时，第 5 名之后合并成「其他」，中性灰，金额是合并总和；被合并的几家写进无障碍标签 |

## 三点九、破坏性操作用标准行高

"清除全部数据""删除这家接入"这类红色项**行高必须和同一列表里其他行一致**。
用 `Button(role: .destructive)` 放在 `Section` 里，不要自己加 padding 或包一层
容器——那会让它比邻居高出一截，看起来像贴错了。

## 三点九五、主操作钉在底部，背景铺进 Home Indicator

有单一主操作的页面和 sheet（保存、下一步、发送、用这个、分享文件、导入）
**位置和样式要一致**：

- 走 `meterPrimaryActionBar`：`.safeAreaInset(edge: .bottom)` 钉住
  `.borderedProminent` + `.controlSize(.large)` + `.buttonBorderShape(.capsule)` 的满宽按钮
- 测试连接那颗 `FillProgressButton` 必须是同一颗胶囊，不要另写圆角。形状由
  `PrimaryActionBarGuardrailTests` 盯着
- 底栏用 `systemGroupedBackground` 铺进 Home Indicator，并关掉底边
  `scrollEdgeEffect`。**不要让列表行从按钮底下透出来**
- 底栏高度只由那颗主按钮决定。说明、Keychain 解释不要堆在按钮下面把按钮顶上去
- 有输入框的抽屉里，主按钮不要跟着软件键盘抬。走 `meterPrimaryActionBar(ignoresKeyboard: true)`；
  键盘附件栏已经有「完成」。抬按钮会改 Form 高度，再叠一层 detent 把键盘算进高度，整页弹跳
- 连接参考推到连接页不要换 sheet 高度。系统没有「抽屉变高」的转场；Apple 是外壳不动、
  里面 `NavigationStack` 横滑。两步主按钮也才能同一个 Y
- 添加确认、连接参考、连接页、加一笔订阅、筛选、利用指南：有主按钮的抽屉走
  `meterDrawerChrome` + `meterPrimaryActionBar`，同一套高度策略和同一个 Y。
  Features 不要手写 `presentationDetents` / `presentationSizing`。闸在
  `check-source-invariants.py` 和 `DrawerChromeGuardrailTests`
- 横屏 iPad 不要再用 detent。HIG：iPad 用居中的 form / page sheet。pad 分支走
  `presentationSizing`，关掉抓手。连接参考双栏和分享卡用 `.page`，其余 form。
  筛选在 iPad 是 popover，走 `meterPhoneDrawerChrome`，不要把 sheet 外壳套进
  popover。竖屏、窄分屏、iPhone 仍走现在的手机抽屉
- Mac 恒开宽壳，不要按窗口长宽掉回 iPhone 底栏。设置是第三个侧栏项，和 iPad
  同一套三栏；⌘, 切到这一栏，不要另开 `Settings` 场景。设置页是系统设置那种
  grouped Form + switch，不要 AppKit 默认的 checkbox 密表。宽壳外层永远是
  **两栏** `NavigationSplitView`（侧栏 + 主区）。两栏和三栏是两种类型，来回切
  会把侧栏和顶栏整棵拆掉。服务 / 设置的主从列走 `PadSecondaryPair`，不要再套
  一层分栏。窗口顶栏必须空着；标题、返回、刷新、分段都在对应列里。
  刷新是列内按钮和 ⌘R，不要 `.refreshable`。分享卡存文件，
  不要申请相册。菜单栏金额的口径和 Widget 相同。Home Indicator 底栏铺法不要
  搬到 Mac 窗口底
- List 不要再为 Home Indicator 留一截底边距，否则会把按钮抬高
- **不要有的放底部、有的塞进 `Section` 当一行、有的只放导航栏确认按钮**

导航栏关掉 sheet 用系统 X：`Button(role: .close)`。不要手写「取消」文字，也不要再包一层 MeterDesign 按钮——系统 role 就是那颗 X。筛选的「用这个」也是单一主操作，走底栏，不要再和关闭挤在导航栏成对。`confirmationDialog` 里的取消仍是 `Button(L("取消"), role: .cancel)`，那是对话框按钮，不是导航栏。

不要改用 `safeAreaBar` 去叠一层滚动边缘模糊——那会把「按钮铺在分组背景上」
变成另一套玻璃底栏。玻璃仍然只许系统导航层给，见 SPEC 第 04 节。

## 四、布局

- **一个左边距网格。** 一屏之内所有元素左对齐到同一条线。上一版仪表居中、
  caption 一个边距、构成条另一个、卡片又一个，差 20–40pt
- 用 `List` 的默认 inset，不要自己调 padding 去凑
- 数字右对齐，标签左对齐
- 点击目标不小于 44×44pt

## 五、仪表页的主角是数字，不是图形

**删掉那个半圆仪表弧。** 它是 web dashboard 的套路，而且大面积色块最容易显脏。

页面结构：

1. **金额本身是主角** —— 大号系统字体、`.monospacedDigit()`、`Color.meterLabel`。
   这个数字是从量（用量 + 预充值消耗 + 超额），不是含订阅的账单总额。
   金额旁不加任何限定符号（`≈` 已从产品移除，估算解释走详情页）
2. 下面一行 `.secondaryLabel` 的次要信息（预计月底、统计区间）
3. 再一行本月订阅（有才出现）。不进主角数字，也不进构成图
4. **bento，不是等重卡片墙。** 一张宽的构成卡（圆环 + 图例，点整张卡从右侧推进构成页）+ 下面两张方卡（较上月同期、近几个月）。只反映从量。较上月同期点整张卡从右侧推进对比页，列出能比的和还不能比的；还不能比的本月金额进柱和涨跌幅。近几个月不是追查入口。
5. 其余「需要注意」是 `List` 的分组行：图标 + 名称 + 右侧数值 + chevron

参照 Apple 自己怎么显示一个"总数 + 构成 + 明细"：设置里的 iPhone 储存空间、
电池、屏幕使用时间。主角仍是数字；构成用圆环，趋势用小柱，不要半圆仪表弧。

## 六、动效：没有 loading，只有变化

刷新时**不许出现任何 loading 样式**：不要 spinner、不要骨架屏、不要
"加载中…"、不要把旧数据清空再填、不要给内容加遮罩。

1. 旧数据**完整、不透明地留在屏幕上**
2. 新数据到了 → 数字滚动到新值，图表动画过渡到新形状
3. 单家失败 → 那一行保留上次成功的数据 + "数据陈旧"标记，其他家照常更新

数字滚动用 `.contentTransition(.numericText(value:))` + `.animation(.snappy, value:)`。
动画时长不超过 0.5s，用系统曲线，不要自定义弹簧参数。

刷新期间的反馈：toolbar 和详情里的刷新按钮，箭头转直到完成；内容仍留着；
完成时一次轻触觉。下拉刷新仍然不要系统转圈。减弱动态效果时箭头停住，按钮保持 disabled。

测试连接同样不许转圈。主按钮用系统绿从左到右盖住 tint（`FillProgressButton`），不要叠一层半透明白、也不要把按钮 `.disabled` 洗成灰。减弱动态效果时整颗变绿、不做横向铺色。请求还在走的时候铺色可以超过 0.5s，开始和收尾仍用 `.snappy`。

## 六点五、动效必须能在画廊里被演示

本文要求的每一个动效（数字滚动、图表过渡、圆环从空转到满、猫的眨眼和换脸、测试连接铺色、刷新按钮旋转），**开发菜单的组件画廊里都要有一个
可交互的演示**：点一下就换一组数据，当场看它是滚过去的还是硬切的。凭据输入行、粘贴、测连接铺色、刷新箭头都要能在画廊里点。圆环进场在「金额」那一组，点「再转一次」。切到设置再回到仪表也会再转；刷新只过渡各段，不重新转。

理由：静态状态可以靠截图检查，动效不行。没有演示入口的话，唯一的验证方式是
去触发一次真实刷新——那既慢又碰不到边界值（$0、负数、超大数）。
**没法演示的规则等于没有规则。**

## 六点六、猫的生命感在脸上，不在身上

TollCat 的猫是账单旁白，不是桌面宠物，也不是会变形的 blob。

- **常态身体锁住。** 不要压扁回弹，不要原地漂。尾巴可以轻轻摆。
- **看起来活着，靠视线和眨眼。** 眨眼是眼皮上下压，快闭慢开，偶尔连眨；不是换成一张闭眼图。视线用互质周期慢慢漂，对不上循环。
- **换表情先眨眼再变脸。** 星眼、叉眼、骷髅拓扑不同，不要做 path morph。眼缝最窄的那一帧切图层。
- **换落点跳一下，不要瞬移，也不要在卡面上滑过去。** 左右翻转不要走 `scaleEffect` 动画——过 0 会把猫挤没。
- **吓到、睡觉、翻肚皮已经够用。** 不要再加和账单无关的状态。Widget 和减弱动态效果仍然是静帧。

时长仍然不超过 0.5s，用系统曲线，不要自定义弹簧。

## 七、Widget 的材质听系统的

第三节"能用系统的就用"在 Widget 上同样成立，而且更严格：容器背景用
`.containerBackground(for: .widget)` 交给系统，不要铺实色。
内容层照常走本文的字体与颜色规则。

三种尺寸各是一套结构，不是把中号拉伸：小号只留月份、总额和预计；中号把构成条
和刷新时间落到同一条左边距；大号才出按厂商卷的构成行。猫是月份行的角标，
不是和数字并排的一列。

## 八、通用判据

- **Dynamic Type** 拉到 XXL 不破版、不截断、不重叠
- **深色模式**用系统语义色自动适配，不要写两套色值。两个例外：`ProviderGlyph`
  的品牌 tile，以及猫的身体灰（浅 `#6E747B` / 深 `#858C93`）。
- **空态**用 `ContentUnavailableView`，有标题、说明、和一个动作
- **触觉反馈**用系统 `sensoryFeedback`，不自造。允许的触发：
  - 切底部 tab / 侧栏三个入口（`.selection`）。手指挡住图标时，轻触确认点中了。系统 iOS 26 tab 不保证自带触感，App 自己发。
  - 切筛选月份、切是否计入订阅（`.selection`）
  - 保存成功、刷新完成、复制成功、清除全部数据成功（轻 impact / `.success`）
  - 测试连接失败（`.error`）
  不要在开关、点普通按钮、打字时再加。
- **VoiceOver**：金额读成"约 47 美元 20 美分"，`ProviderGlyph` 有品牌名 label，
  装饰元素 `.accessibilityHidden(true)`

## 九、验收时会被问的问题

UI 任务做完，报告里要能回答：

1. 全仓库还有几处 `.monospaced()`？分别在哪、为什么留？
2. 还有几个自造组件是系统已有对应物的？
3. 一屏之内所有元素的左边距是同一条线吗？
4. 刷新时旧数据有没有被清空或遮住？数字是滚动的还是硬切？
5. Dynamic Type XXL 和深色模式各看过了吗？
6. 空态长什么样？
7. 哪一处你觉得还不够"像原生"？

最后一问必答，不许答"没有"。
