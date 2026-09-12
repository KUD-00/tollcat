import SwiftUI
import MeterCore
import MeterDesign
import MeterModules

/// 宽壳（Mac、横屏 iPad）：单列滚动，铺满整列，左右只留 `pageHorizontal`——
/// 和服务 / 设置列里的分组卡同一个边距。不要再给内容列设上限居中：
/// 列头标题钉在列边，内容却缩在中间，左右就多出两截解释不了的留白。
///
/// 合计 + 构成猫卡独占一行；「较上月同期」「近几个月」和「需要注意」的每个模块
/// 各自成一张 bento 卡，按 `dashboardTileMin` 自动换行，最多三列；窗口再宽，
/// 多出来的宽度变成更多列或更宽的卡，不会把单张卡拉成横条。
/// 模块 View、折算、取数都和手机同一份，这里只换外壳。
struct DashboardPadLayout: View {
    var model: DashboardModel
    var persistenceStatus: PersistenceStatus
    var onOpenProvider: (AccountID) -> Void = { _ in }
    var onOpenComposition: () -> Void = {}
    var onOpenComparison: () -> Void = {}

    /// 换行按 bento 区实测宽算，不去猜窗口尺寸。首帧先按「刚好三列」估，
    /// `onGeometryChange` 一量到真值就覆盖。
    @State private var gridWidth: CGFloat = MeterSpacing.dashboardTileMin * 3 + MeterSpacing.sm * 2
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // GeometryReader 把滚动区钉死在分给它的尺寸里。行里的卡是定宽的，直接放进
        // 分栏会让分栏按内容的理想宽度给列，窄窗口下把侧栏挤扁、整页不再跟窗口走。
        GeometryReader { proxy in
            scrollBody
                .frame(width: proxy.size.width, height: proxy.size.height)
                .onChange(of: proxy.size.width, initial: true) { _, width in
                    gridWidth = max(width - MeterSpacing.pageHorizontal * 2, 0)
                }
        }
        .background(Color.meterGroupedBackground)
    }

    private var scrollBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MeterSpacing.sm) {
                // 构成在宽壳上是 bento 里的一张两格卡，不再独占整行吃满：
                // 卡有最大宽，右边还能并排放别的。
                DashboardCatStage(
                    composition: nil,
                    mood: model.catMood,
                    speech: model.catSpeech,
                    showsCat: !model.shell.hidesCat,
                    monthToDate: model.monthToDateContent,
                    onOpenComposition: onOpenComposition,
                    onSelectSubscription: {
                        if let id = model.monthToDateContent?.subscriptionAccountID {
                            onOpenProvider(id)
                        }
                    },
                    onToggleSubscriptions: { model.setIncludesSubscriptions($0) }
                )
                tileGrid
                if showsEnvironmentFooter {
                    environmentFooter
                        .padding(.horizontal, MeterSpacing.pageHorizontal)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, MeterSpacing.xs)
            .padding(.bottom, MeterSpacing.lg)
        }
        .meterRefreshable { await model.refresh() }
    }

    /// 一格 bento。构成卡里的两张方卡在宽壳上出列，和洞察模块同一个换行流。
    private enum WideTile: Identifiable {
        case composition(CompositionModuleContent)
        case comparison(ComparisonModuleContent)
        case trend(TrendModuleContent)
        case module(DashboardModuleID)
        /// 「特别关心」在宽壳上一家一张卡，不挤在一张卡里。
        case service(ServiceCardItem)

        var id: String {
            switch self {
            case .composition: "composition"
            case .comparison: "comparison"
            case .trend: "trend"
            case .module(let id): id.rawValue
            case .service(let item): "service-\(item.accountID.rawValue.uuidString)"
            }
        }

        /// 想占几格，0.25 步进。构成一格又四分之一（圆环加图例刚好），其余一格。
        /// 行里剩不到一格时，下一张能缩就缩进来（见 `minSpan`），缩不进才让最后一张顺延填满。
        var span: Double {
            switch self {
            case .composition: 1.25
            default: 1
            }
        }

        /// 最窄能缩到几格。图表和列表卡缩到四分之三格还能看；构成不缩。
        var minSpan: Double {
            switch self {
            case .composition: 1.25
            default: 0.75
            }
        }

        /// 服务小卡矮一档，其余同高。
        var height: CGFloat {
            switch self {
            case .service: MeterSpacing.dashboardTileCompact
            default: MeterSpacing.dashboardTileHeight
            }
        }
    }

    /// 构成两格卡领头，方卡跟着构成走（和手机同一条件）：构成藏掉时它们也不单飞。
    /// 其余模块按版式顺序各成一卡。
    private var tiles: [WideTile] {
        var tiles: [WideTile] = []
        if showsComposition, let composition = model.compositionContent {
            tiles.append(.composition(composition))
        }
        if showsComposition, let comparison = model.comparisonContent {
            tiles.append(.comparison(comparison))
        }
        if showsComposition, let trend = model.trendContent {
            tiles.append(.trend(trend))
        }
        // 钉去侧栏的那块不在主区再画一遍。
        for id in DashboardModuleRegion.bodyIDs(from: model.visibleModuleIDs) where id != model.sidebarModuleID {
            if id == .services, let content = model.servicesContent {
                tiles += content.items.map { WideTile.service($0) }
            } else {
                tiles.append(.module(id))
            }
        }
        return tiles
    }

    @ViewBuilder
    private var tileGrid: some View {
        let tiles = self.tiles
        if !tiles.isEmpty {
            // 只有一行时按张数排：两张卡各占一半，别按三列排出一格空位。
            let columns = min(columnCount, Int(tiles.reduce(0) { $0 + $1.span }.rounded(.up)))
            VStack(alignment: .leading, spacing: MeterSpacing.sm) {
                ForEach(Array(tileRows(tiles, columns: columns).enumerated()), id: \.offset) { _, row in
                    tileRow(row, columns: columns)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, MeterSpacing.pageHorizontal)
        }
    }

    /// 一行里的一张卡和它实际占的格数（顺延填满之后）。
    private struct Placed: Identifiable {
        var tile: WideTile
        var span: Double
        var id: String { tile.id }
    }

    /// 贪心按顺序装行：装不下就换行，不回头填洞——顺序是用户排的，比密度重要。
    /// 行里已经有别的卡时，最后一张顺延填满剩下的格（0.25 步进的格宽就是为了这个：
    /// 构成一格半，旁边那张自然长成一格半）。孤零零一张卡的行不顺延——三列宽里
    /// 摊开一张卡，图表和数字都被拉成横条，比右边留白难看。
    /// 矮的服务小卡不和高卡混一行（会被撑成一块空白），
    /// 整块插在它前一张卡所在行之后：前一行先用后面的高卡填满，小卡最多往后挪一行。
    private func tileRows(_ tiles: [WideTile], columns: Int) -> [[Placed]] {
        let capacity = Double(columns)
        var rows: [[Placed]] = []
        var current: [Placed] = []
        var used: Double = 0
        var pendingCompact: (afterRow: Int, tiles: [WideTile])?

        func flushRow() {
            guard !current.isEmpty else { return }
            // 剩下的格给最后一张，行排满。整行只有一张卡时留着不动：
            // 它是按一格设计的，摊成三格宽只是把内容抻长。
            if current.count > 1 {
                current[current.count - 1].span += max(capacity - used, 0)
            }
            rows.append(current)
            current = []
            used = 0
        }
        func insertPendingIfReady() {
            guard let pending = pendingCompact, rows.count - 1 >= pending.afterRow else { return }
            rows.insert(contentsOf: packCompact(pending.tiles, columns: columns), at: pending.afterRow + 1)
            pendingCompact = nil
        }

        for tile in tiles {
            if tile.height < MeterSpacing.dashboardTileHeight {
                if pendingCompact == nil {
                    pendingCompact = (afterRow: current.isEmpty ? rows.count - 1 : rows.count, tiles: [])
                }
                pendingCompact?.tiles.append(tile)
                continue
            }
            var span = min(tile.span, capacity)
            let leftover = capacity - used
            if span > leftover + 0.001 {
                if leftover >= min(tile.minSpan, capacity) - 0.001, !current.isEmpty {
                    // 剩的够它最窄那档：缩进来把这一行填满。
                    span = leftover
                } else {
                    flushRow()
                    insertPendingIfReady()
                }
            }
            current.append(Placed(tile: tile, span: span))
            used += span
        }
        flushRow()
        if let pending = pendingCompact {
            rows.insert(contentsOf: packCompact(pending.tiles, columns: columns), at: min(pending.afterRow + 1, rows.count))
        }
        return rows
    }

    /// 小卡按一格一张排，不顺延填满——一张小卡拉成三格宽比留空更怪。
    private func packCompact(_ tiles: [WideTile], columns: Int) -> [[Placed]] {
        stride(from: 0, to: tiles.count, by: columns).map {
            tiles[$0..<min($0 + columns, tiles.count)].map { Placed(tile: $0, span: 1) }
        }
    }

    /// 一格的宽：网格宽扣掉列间距平分。
    private func unitWidth(columns: Int) -> CGFloat {
        (gridWidth - MeterSpacing.sm * CGFloat(columns - 1)) / CGFloat(columns)
    }

    /// 一行同高，取行里最高那档；卡宽按格数算（s 格 = s 个格宽 + (s−1) 个间距），
    /// 宽高都定死，内容按框裁。
    private func tileRow(_ row: [Placed], columns: Int) -> some View {
        let unit = unitWidth(columns: columns)
        let height = row.map(\.tile.height).max() ?? MeterSpacing.dashboardTileHeight
        return HStack(alignment: .top, spacing: MeterSpacing.sm) {
            ForEach(row) { placed in
                let width = unit * placed.span + MeterSpacing.sm * (placed.span - 1)
                tileView(placed.tile)
                    .frame(width: width, height: height, alignment: .topLeading)
                    // 卡宽是这一行算出来的，档位就在这里给。模块自己不许量宽——
                    // 量自身宽再回填自身宽会转死主线程（仪表盘实验室第一版的死法）。
                    // 传的是模块拿到的内容宽：卡自己的左右内边距先扣掉。
                    .meterModuleStyle(
                        width: ModuleWidth.bucket(forContentWidth: width - MeterSpacing.md * 2),
                        height: .regular,
                        container: .card
                    )
            }
        }
        .frame(width: gridWidth, alignment: .leading)
    }

    @ViewBuilder
    private func tileView(_ tile: WideTile) -> some View {
        switch tile {
        case .composition(let content):
            Button(action: onOpenComposition) {
                CompositionTileView(content: content)
                    .meterListRowHitTarget()
            }
            .buttonStyle(.plain)
            .accessibilityHint(L("查看构成明细"))
        case .comparison(let content):
            Button(action: onOpenComparison) {
                ComparisonTileView(content: content, showsDisclosure: true)
                    .meterListRowHitTarget()
            }
            .buttonStyle(.plain)
            .accessibilityHint(L("查看较上月同期明细"))
        case .trend(let content):
            TrendTileView(content: content, plotHeight: MeterSpacing.bentoChartTall, showsHeadline: true)
        case .module(let id):
            DashboardModuleCard(id: id, model: model)
        case .service(let item):
            Button(action: { onOpenProvider(item.accountID) }) {
                ServiceTileView(item: item)
                    .meterListRowHitTarget()
            }
            .buttonStyle(.plain)
            .accessibilityHint(L("查看 \(item.displayName) 详情"))
        }
    }

    private var columnCount: Int {
        if dynamicTypeSize.isAccessibilitySize { return 1 }
        let spacing = MeterSpacing.sm
        let fit = Int(((gridWidth + spacing) / (MeterSpacing.dashboardTileMin + spacing)).rounded(.down))
        return min(max(fit, 1), 3)
    }

    private var attentionIDs: [DashboardModuleID] {
        DashboardModuleRegion.attentionIDs(from: model.visibleModuleIDs)
    }

    private var showsComposition: Bool {
        DashboardModuleRegion.hasComposition(in: model.visibleModuleIDs)
            && model.compositionContent != nil
    }

    private var showsEnvironmentFooter: Bool {
        !persistenceStatus.notices.isEmpty || model.refreshFailureCaption != nil
    }

    @ViewBuilder
    private var environmentFooter: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xs) {
            PersistenceNoticeList(status: persistenceStatus) {
                model.dismissDemoBanner()
            }
            if let refreshFailureCaption = model.refreshFailureCaption {
                Text(refreshFailureCaption)
                    .font(MeterFont.footnote)
                    .foregroundStyle(MeterColor.warn)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(refreshFailureCaption)
            }
        }
    }
}

#Preview("Light") {
    @Previewable @State var model = DashboardModel.preview
    NavigationStack {
        DashboardPadLayout(
            model: model,
            persistenceStatus: .preview
        )
        .navigationTitle("八月")
        .navigationBarTitleDisplayMode(.large)
    }
    .environment(\.meterShell, .pad)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    @Previewable @State var model = DashboardModel.preview
    NavigationStack {
        DashboardPadLayout(
            model: model,
            persistenceStatus: .preview
        )
        .navigationTitle("八月")
        .navigationBarTitleDisplayMode(.large)
    }
    .environment(\.meterShell, .pad)
    .preferredColorScheme(.dark)
}

#Preview("窄列换行") {
    @Previewable @State var model = DashboardModel.preview
    NavigationStack {
        DashboardPadLayout(
            model: model,
            persistenceStatus: .preview
        )
    }
    .environment(\.meterShell, .pad)
    .frame(width: 560)
}
