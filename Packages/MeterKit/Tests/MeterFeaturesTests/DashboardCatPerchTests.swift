import Testing
import CoreGraphics
import Foundation
import MeterDesign
@testable import MeterFeatures
@testable import MeterModules

@Suite("DashboardCatPerch")
struct DashboardCatPerchTests {
    private let catSize: CGFloat = 96
    /// 合计区锚：舞台顶到构成卡上沿那条横带。高度取保证下限——
    /// 块高兜底 `headerMinHeight` 加块卡间距 `sm`，猫在最矮的合计块上也不能伸出舞台。
    private let header = CGRect(
        x: 20,
        y: 0,
        width: 353,
        height: DashboardCatPerch.headerMinHeight + MeterSpacing.sm
    )
    /// 两翼锚：居中的分享胶囊实测边框。页内 regular 胶囊按热区下限估。
    private let share = CGRect(x: 140, y: 420, width: 113, height: 44)

    @Test("五个落点都在，抽签不会抽到清单外")
    func fiveNamedPerches() {
        #expect(DashboardCatPerch.allCases.count == 5)
        var generator = SplitMix64(seed: 7)
        for _ in 0..<40 {
            #expect(DashboardCatPerch.allCases.contains(DashboardCatPerch.random(using: &generator)))
        }
    }

    @Test("同一个种子两次抽到同一处，不同种子能抽出不同落点")
    func seedIsDeterministic() {
        #expect(DashboardCatPerch.pick(seed: 11) == DashboardCatPerch.pick(seed: 11))
        let picks = (UInt64(0)..<40).map(DashboardCatPerch.pick(seed:))
        #expect(Set(picks).count > 1)
    }

    @Test("合计区的猫都待在右侧规定的空白里，最矮的合计块也兜得住猫顶")
    func headerPerchesStayInTheReservedBlank() {
        for perch in DashboardCatPerch.available(header: true, share: false) {
            let spot = placement(perch)
            // 横向不越出给字让开的那条空白，纵向不伸出舞台顶。
            #expect(spot.x >= header.maxX - DashboardCatPerch.headerTrailingReserve)
            #expect(spot.y >= 0)
            // 脚最多伸进构成卡上沿一小截，别压到卡里第一行字。
            #expect(spot.y + catSize - header.maxY <= MeterSpacing.sm)
        }
    }

    @Test("两翼的猫贴着胶囊底线，各在一侧，不压到胶囊")
    func sharePerchesFlankTheCapsule() {
        let left = placement(.sitShareLeft)
        #expect(left.x + catSize <= share.minX)
        #expect(left.y + catSize == share.maxY)
        #expect(left.isFlipped)

        let right = placement(.sitShareRight)
        #expect(right.x >= share.maxX)
        #expect(right.y + catSize == share.maxY)
        #expect(!right.isFlipped)
    }

    @Test("可坐清单跟着锚走：没合计只剩两翼，没分享只剩合计区")
    func availabilityFollowsAnchors() {
        let headerOnly = DashboardCatPerch.available(header: true, share: false)
        #expect(headerOnly.count == 3)
        #expect(headerOnly.allSatisfy { $0.zone == .header })

        #expect(DashboardCatPerch.available(header: false, share: true) == [.sitShareLeft, .sitShareRight])
        #expect(DashboardCatPerch.available(header: false, share: false).isEmpty)
        #expect(
            DashboardCatPerch.available(header: true, share: true).count
                == DashboardCatPerch.allCases.count
        )
    }

    @Test("合计和构成卡同一行，不靠垫底 inset 躲圆角")
    func monthToDateSharesTheCompositionRow() throws {
        let dashboard = try source("DashboardView.swift")
        #expect(dashboard.contains("monthToDate: model.monthToDateContent"))
        #expect(!dashboard.contains("private var heroSection"))
        #expect(!dashboard.contains("listSectionSpacing(0)"))

        let stage = try source("DashboardCatStage.swift")
        #expect(stage.contains("var monthToDate: MonthToDateModuleContent?"))
        #expect(stage.contains("headerCardGap"))
        #expect(stage.contains("private var headerCardGap: CGFloat { MeterSpacing.sm }"))
        #expect(stage.contains("padding(.top, topPad)"))
        #expect(!stage.contains("Color.clear.frame(height: topPad)"))
        #expect(stage.contains("DashboardCatHop"))
        // 猫的话不再占构成卡一行；台词只在读屏时挂在猫身上。
        #expect(!stage.contains("speechLine"))
        #expect(stage.contains("accessibilityLabel(speechAccessibility)"))
        #expect(stage.contains("DashboardBentoTiles"))
        #expect(!stage.contains("isCompositionExpanded"))
    }

    @Test("两张方卡并排拉满构成卡宽度，高度跟较高那张齐")
    func bentoTilesFillTheCompositionRow() throws {
        let tiles = try source("DashboardBentoTiles.swift")
        #expect(tiles.contains("HStack(alignment: .top"))
        #expect(tiles.contains("minWidth: 0, maxWidth: .infinity, maxHeight: .infinity"))
        #expect(tiles.contains("fixedSize(horizontal: false, vertical: true)"))
        #expect(tiles.contains("frame(maxWidth: .infinity)"))
        #expect(!tiles.contains("aspectRatio("))
        #expect(!tiles.contains(".aspectRatio"))

        let stage = try source("DashboardCatStage.swift")
        #expect(stage.contains(".frame(maxWidth: .infinity, alignment: .leading)"))
    }

    @Test("分享和编辑在导航栏更多菜单，不在页尾")
    func shareAndEditLiveInTheToolbarMenu() throws {
        let dashboard = try source("DashboardView.swift")
        #expect(dashboard.contains("systemImage: \"ellipsis\""))
        #expect(dashboard.contains("L(\"更多\")"))
        #expect(dashboard.contains("square.and.arrow.up"))
        #expect(dashboard.contains("L(\"分享\")"))
        #expect(dashboard.contains("L(\"编辑仪表盘\")"))
        #expect(dashboard.contains("ToolbarSpacer(.fixed"))
        #expect(!dashboard.contains("DashboardActionRow"))
        #expect(!dashboard.contains("onShare:"))
        #expect(!dashboard.contains("onEditDashboard:"))
        #expect(!dashboard.contains("L(\"编辑\")"))

        let pad = try source("DashboardPadLayout.swift")
        #expect(!pad.contains("DashboardActionRow"))
        #expect(!pad.contains("onShare"))
        #expect(!pad.contains("onEditDashboard"))
    }

    @Test("舞台分享胶囊只给 gallery 的落点预览")
    func shareCapsuleOnStageIsGalleryOnly() throws {
        let dashboard = try source("DashboardView.swift")
        #expect(!dashboard.contains("onShare:"))

        let stage = try source("DashboardCatStage.swift")
        #expect(stage.contains("square.and.arrow.up"))
        #expect(stage.contains("shareButton"))
        #expect(stage.contains("L(\"分享\")"))
        #expect(stage.contains("meterInlineActionStyle()"))
        #expect(!stage.contains("meterPrimaryActionStyle()"))
        #expect(stage.contains(".fixedSize()"))
        #expect(stage.contains("minTap"))
        #expect(!stage.contains("buttonStyle(.bordered)"))
        #expect(stage.contains("HStack(alignment: .center"))
    }

    @Test("主角金额顶边不被 List 裁掉")
    func monthToDateAmountLeavesRoomAtTheTop() throws {
        let view = try source("MonthToDateModuleView.swift")
        #expect(view.contains(".meterAmountStyle()"))
        #expect(view.contains("fixedSize(horizontal: false, vertical: true)"))
        #expect(view.contains("padding(.top, MeterSpacing.xs)"))
    }

    @Test("构成卡点进去，不就地展开")
    func pieCardPushesDetail() throws {
        let stage = try source("DashboardCatStage.swift")
        #expect(stage.contains("onOpenComposition"))
        #expect(stage.contains("查看构成明细"))
        let module = try source("CompositionModuleView.swift")
        #expect(!module.contains("isExpanded"))
    }

    @Test("较上月同期点进去，不就地展开")
    func comparisonTilePushesDetail() throws {
        let stage = try source("DashboardCatStage.swift")
        #expect(stage.contains("onOpenComparison"))
        let tiles = try source("DashboardBentoTiles.swift")
        #expect(tiles.contains("查看较上月同期明细"))
        #expect(tiles.contains("onOpenComparison"))
        #expect(!tiles.contains("isExpanded"))
    }

    @Test("宽壳仪表是一列 bento：铺满列宽、按 tileMin 换行，不再是两列 List")
    func padLayoutIsFullWidthBentoColumn() throws {
        let pad = try source("DashboardPadLayout.swift")
        #expect(pad.contains("ScrollView"))
        // 不再给内容列设上限居中：列头钉在列边，内容缩在中间就是两截莫名的留白。
        #expect(!pad.contains("dashboardWideColumn"))
        #expect(pad.contains(".frame(maxWidth: .infinity, alignment: .leading)"))
        #expect(pad.contains("MeterSpacing.dashboardTileMin"))
        // 只有一行时按格数排，两格的构成卡也算进去。
        #expect(pad.contains("tiles.reduce(0) { $0 + $1.span }"))
        // 卡是定高的（一行同高、内容按框裁），不再靠 fixedSize 量内容撑行。
        #expect(pad.contains("MeterSpacing.dashboardTileHeight"))
        #expect(!pad.contains("maxHeight: .infinity, alignment: .topLeading"))
        // 构成在宽壳上是一格又四分之一的卡（0.25 步进的格宽），不独占整行。
        #expect(pad.contains("case .composition: 1.25"))
        #expect(pad.contains("var span: Double"))
        #expect(pad.contains("composition: nil,"))
        // 旧的两列 List 骨架不许回潮：卡会被无上限的列宽拉伸。
        #expect(!pad.contains("compositionColumn"))
        #expect(!pad.contains("attentionColumn"))
        #expect(!pad.contains("List {"))

        let dashboard = try source("DashboardView.swift")
        #expect(dashboard.contains("usesPadChrome"))
        #expect(dashboard.contains("DashboardPadLayout("))
        #expect(!dashboard.contains(".opacity(0)"))

        let stage = try source("DashboardCatStage.swift")
        #expect(stage.contains("monthToDate == nil ? 0"))
        #expect(!stage.contains("monthToDate == nil ? MeterSpacing.xs"))
    }

    private func placement(_ perch: DashboardCatPerch) -> DashboardCatPlacement {
        perch.placement(catSize: catSize, header: header, share: share)
    }

    /// 模块视图搬去了 MeterModules（widget 才链得到），其余仪表盘源码还在原处。
    private func source(_ fileName: String) throws -> String {
        let sources = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "Sources")
        let modules = sources.appending(path: "MeterModules").appending(path: fileName)
        let dashboard = sources
            .appending(path: "MeterFeatures/Dashboard")
            .appending(path: fileName)
        let url = FileManager.default.fileExists(atPath: modules.path) ? modules : dashboard
        return try String(contentsOf: url, encoding: .utf8)
    }
}
