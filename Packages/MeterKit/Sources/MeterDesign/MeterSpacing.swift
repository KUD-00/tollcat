import SwiftUI

/// 间距 token。Features 里不要写魔法数字。
public enum MeterSpacing {
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 8
    public static let sm: CGFloat = 12
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 20
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32

    public static let pageHorizontal: CGFloat = 20

    /// 详情页柱/折线的绘图区。不要在 Features 里另写高度。
    public static let chartPlot: CGFloat = 168

    /// 构成圆环外径。中心留空，只服务图例对照。
    public static let donut: CGFloat = 132

    /// 仪表 bento 方卡里的小柱。比详情页绘图区矮一截，才是方卡不是第二张详情图。
    public static let bentoChart: CGFloat = 64
    /// 宽壳定高卡里的近几个月柱图：卡有 220 高，柱可以给到这个高。
    public static let bentoChartTall: CGFloat = 108

    /// 图例色点。和构成条用同一套系统色，不是品牌色。
    public static let compositionSwatch: CGFloat = 8

    /// 储存空间那种细条。
    public static let segmentBar: CGFloat = 6

    public static let segmentBarWidget: CGFloat = 5

    /// 系统 `ProgressView` 那条线的粗细。渲图时 `ProgressView` 画不出来，
    /// 得自己拿胶囊描一条同样粗的（见 `BudgetModuleView`）。
    public static let progressBar: CGFloat = 4

    /// 和 `ProviderGlyph` 默认边长对齐，Features 不要再写 28。
    public static let providerGlyph: CGFloat = 28

    /// App 图标那颗方章（`BrandMark`）。和它旁边的 `title2` 字号成对。
    public static let brandMark: CGFloat = 40

    /// Mac 工具栏里的品牌方章。比 28pt glyph 小一号，才不压过侧栏切换。
    public static let macToolbarBrand: CGFloat = 24
    /// Mac 列头玻璃圆钮的直径（返回 / 刷新 / 筛选）。
    public static let macBarButton: CGFloat = 30
    /// Mac 对话框底栏按钮的高度（`.controlSize(.large)` 的 bordered 钮就是这个高）。
    public static let macDialogButton: CGFloat = 28

    /// 分享卡上的构成环。比仪表那只大一号——卡是一张要被缩略图看的图。
    public static let shareCardDonut: CGFloat = 150

    /// 分享卡方卡里的小柱。同理比仪表 `bentoChart` 高一截。
    public static let shareCardChart: CGFloat = 72

    /// 分享卡右下角的二维码。再小相机就要凑很近才扫得动。
    public static let shareCardQR: CGFloat = 72

    /// 分享面板里预览那一栏的宽。中间档：卡本身按 432pt 排版，收到这个宽度约六成，
    /// 数字还读得出，又不至于把面板撑成一张海报。**不跟着卡的长短变**——
    /// 长卡在这个宽度下往下滚，不缩成一条细缝。
    public static let shareCardPreviewWidth: CGFloat = 256

    /// 预览那一栏的高度上限。9:16 那一档（256×455）正好整张装下；
    /// 更长的卡在这一格里上下滚。
    public static let shareCardPreview: CGFloat = 460

    /// sheet 顶上标题行 + 底下那条（Mac 的「完成」）一共占多高。
    /// 只给「自己把 sheet 尺寸算出来」的面用（`DrawerHeight.fitted`）：
    /// 里面套了 `NavigationStack` 的视图报不出理想高，系统量不出来，只能自己加上这一截。
    public static var sheetChrome: CGFloat {
        #if os(macOS)
        112
        #else
        56
        #endif
    }

    /// 宽壳（iPad / Mac）分享面板里，右边那列动作的宽度。
    /// 左边留给预览——横向空间够时不该让一张竖图和三行字排成上下两截。
    public static let shareActionColumn: CGFloat = 240

    /// 添加确认抽屉中间那颗。比列表行大一号，才撑得起那张小卡。
    public static let providerGlyphLarge: CGFloat = 64

    /// 可点区域下限。视觉元素可以更小，热区不能。
    public static let minTap: CGFloat = 44

    /// 凭据字段名。不要做成整行 44pt，名字会离卡片上沿太远。
    public static let fieldLabel: CGFloat = 22

    /// `.controlSize(.large)` 主操作的高度。铺色按钮按这个画，才和系统大按钮齐。
    public static let primaryActionMinHeight: CGFloat = 50
    /// 底栏总高：大按钮 + 上下 sm。sheet detent 要把这一截算进去。
    public static var primaryActionBarHeight: CGFloat {
        primaryActionMinHeight + sm * 2
    }
    /// 教程步骤序号。比 SF Symbol 小圆点大一号，才读得出字。
    public static let stepIndex: CGFloat = 32
    /// 序号到正文。跟卡片内边距同一档（md），才和左侧 section 内边距齐；用 xs 会一头宽一头窄。
    public static let stepIndexGap: CGFloat = md

    /// 横屏二级列。和 iPhone 逻辑宽对齐，别被分栏压成细条。
    public static let phoneColumn: CGFloat = 393

    /// 宽壳 bento 卡的换行阈值：一列摊不到这个宽就少排一张。
    public static let dashboardTileMin: CGFloat = 250
    /// 宽壳 bento 卡的固定高：一行同高，内容按这个高裁。列表类的卡只列 3 行就是为了装进它。
    /// 不让卡按内容自己长——同一行里长的会把短的撑成一大块空白。
    public static let dashboardTileHeight: CGFloat = 240
    /// 特别关心那种只有一个数的小卡。
    public static let dashboardTileCompact: CGFloat = 124
    /// 卡里的构成环，比首屏那只小一号才和图例并排装进一张卡。
    public static let donutTile: CGFloat = 104

    /// Mac sheet 里 List 的最小尺寸（List 理想高为 0，不给会缩成一条）。
    public static let macSheetListWidth: CGFloat = 480
    public static let macSheetListHeight: CGFloat = 560

    /// 侧栏底部那张卡的最大高。侧栏首先要装得下三个入口。
    public static let sidebarCard: CGFloat = 260

    /// 编辑面里预算输入框的最大宽。
    public static let budgetField: CGFloat = 160

    /// 特别关心里迷你走势的尺寸。
    public static let sparkline: CGFloat = 64
    public static let sparklineHeight: CGFloat = 22
    /// 热力图月份标题的最小宽，翻月时箭头不跟着字长跳。
    public static let heatMonthTitle: CGFloat = 96
    /// 图例里百分比那一列的宽，数字右对齐成一列。
    public static let percentColumn: CGFloat = 44

    /// 热力格一格的边长。GitHub 贡献图那档大小，一列七格加间距约 110pt 高。
    public static let heatCell: CGFloat = 14
    public static let heatGap: CGFloat = 3

    /// 预算线那排小方块之间的缝。和热力格同一副手感——格子本身不写死边长，
    /// 一行几格由宽度档定、每格分剩下的宽，缝始终这么宽。
    public static let budgetBlockGap: CGFloat = 3

    /// Mac 上从列头弹出的 popover（筛选）。宽度钉死；高度封顶，不封顶 Form 会按
    /// 内容理想高把 popover 拉成一条顶出屏幕的长条。
    public static let macPopoverWidth: CGFloat = 420
    public static let macPopoverMaxHeight: CGFloat = 620
    /// Mac 菜单栏点开的面板。比筛选 popover 窄：只放数字、构成条和近几个月。
    public static let macMenuBarPanelWidth: CGFloat = 320
    /// 菜单栏面板里的饼图。132 在 320 宽的面板里太抢，图例只剩一条缝。
    public static let donutMenuBar: CGFloat = 96

    /// 宽壳一级侧栏。没钉模块时 200–280、默认 240。
    /// 钉了底部那张卡就把列拉到上限：卡扣完两层边距（`sm` + `md`）× 2
    /// 才刚过 `ModuleWidth.regular`（200）。只改 `ideal` 不够——分栏亮过之后
    /// ideal 不再协商，用户拖过的宽会粘住；把 min 也抬到上限，列必须张开，
    /// 也拖不回 compact。
    public static let sidebarColumnMin: CGFloat = 200
    public static let sidebarColumn: CGFloat = 240
    public static let sidebarColumnMax: CGFloat = 280

    public static func sidebarColumnWidth(
        hasPinnedModule: Bool
    ) -> (min: CGFloat, ideal: CGFloat, max: CGFloat) {
        if hasPinnedModule {
            return (sidebarColumnMax, sidebarColumnMax, sidebarColumnMax)
        }
        return (sidebarColumnMin, sidebarColumn, sidebarColumnMax)
    }

    /// Mac 主窗口。侧栏按 `sidebarColumn` + 主从列各一截，再窄会掉成细条。
    public static let macWindowMinWidth: CGFloat = 960
    public static let macWindowMinHeight: CGFloat = 640
    public static let macWindowIdealWidth: CGFloat = 1100
    public static let macWindowIdealHeight: CGFloat = 740

    /// 一级侧栏左下。比仪表那只小一号，才塞得进 `sidebarColumn` 的栏。
    public static let catSidebar: CGFloat = 72

    /// 仪表圆环下方那只猫猫。64 在卡里像一颗钉，要能当这张卡的角色。
    public static let catDashboard: CGFloat = 96

    /// 猫坐在构成卡沿上时伸出卡外的那一截。按猫身高的比例，不另写死点数。
    /// 和落点里最大的探出（上沿 `sm`、右下约 0.25）对齐，再留一点给旋转。
    public static var catPerchOutset: CGFloat { catDashboard * 0.24 }

    /// 小号 Widget 月份行角标。和 28pt glyph 同级，不和数字抢行高。
    public static let catWidgetSmall: CGFloat = 28

    /// 中号 Widget 月份行角标。不要再做成左侧一列——那会把金额挤没。
    public static let catWidget: CGFloat = 36

    /// 大号 Widget 月份行角标。
    public static let catWidgetLarge: CGFloat = 48

    /// 打赏页。
    public static let catTip: CGFloat = 88

    /// 打赏成功之后。猫吃到东西，比选档时大一截；不要大到开屏那档。
    public static let catTipCelebrating: CGFloat = 128

    /// 打赏档位上的糖果 / 咖啡 / 披萨。三列并排还留得下名字和价格。
    public static let tipTreat: CGFloat = 76

    /// 设置页那一行入口上的糖。比 28pt 的 provider tile 大一号：那是一块满底色的方章，
    /// 这是一张留白很多的画，同样点数看着要小半圈。
    public static let tipTreatRow: CGFloat = 36

    /// 开屏 / 首次引导。画廊里仍按这个尺寸看猫；开场页不再用猫当整页插图。
    public static let catOnboarding: CGFloat = 168

    /// 开屏小组件预览。接近系统中号 Widget 的高度，不要再长成一张海报。
    public static let onboardingWidget: CGFloat = 160

    /// 开场里仪表 / 凭据 / 添加列表那块标本的宽。跟手机逻辑列对齐，
    /// 不要跟窗口一起拉成一张宽卡。
    public static let onboardingPreviewWidth: CGFloat = phoneColumn

    /// 中号小组件标本的宽。系统中号大约这个数，拉宽就不再像小组件。
    public static let onboardingWidgetWidth: CGFloat = 338

    /// 利用指南抽屉。比开屏小一号，medium detent 里还要留下标题和两三句话。
    public static let catUsageGuide: CGFloat = 96

    /// 横屏不要把一句话拉成一行宽标语。
    public static let readableMeasure: CGFloat = 480

    /// 开场底栏。宽壳上 480 通栏太扁长；比一半多一截，高度略抬。
    public static let onboardingActionWidth: CGFloat = 300
    public static let onboardingActionHeight: CGFloat = 56

    /// 开发画廊。
    public static let catGallery: CGFloat = 180
}
