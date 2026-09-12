import SwiftUI
import MeterCore
import MeterDesign
import MeterModules

/// 合计 + 构成宽卡 + 两张方卡。猫坐在页面规定好的空白处：
/// 合计块右侧（画在内容底下，UI 压猫；块高兜底），或分享胶囊两翼（胶囊居中，两侧天然空）。
///
/// 仪表盘的分享在顶栏「更多」里，这里不再传 `onShare`，猫只抽合计区那三处。
/// 舞台自己仍然会摆分享胶囊——猫猫 gallery 的落点预览要用。
///
/// 手机上合计不能单独成节：insetGrouped 会把单行节四个角都裁圆，
/// 「预计月底」贴左下角会被削。跟构成卡同一坐标系之后字不在圆角上。
///
/// List 的 section 会裁掉伸出圆角的内容，猫的落点又要能贴着卡沿，
/// 所以构成卡自己画，section 背景清掉。
struct DashboardCatStage: View {
    var monthToDate: MonthToDateModuleContent?
    var composition: CompositionModuleContent?
    var comparison: ComparisonModuleContent?
    var trend: TrendModuleContent?
    var mood: MeterCore.CatMood
    var speech: String
    var showsCat: Bool
    var onOpenComposition: (() -> Void)?
    var onOpenComparison: (() -> Void)?
    var onSelectSubscription: (() -> Void)?
    var onToggleSubscriptions: ((Bool) -> Void)?
    var onShare: (() -> Void)?
    var pinnedPerch: DashboardCatPerch?

    @State private var perch: DashboardCatPerch
    @State private var headerHeight: CGFloat = 0
    @State private var shareCapsule: CGRect = .null
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // 坐标名是纯字符串，必须能进 onGeometryChange 的 Sendable 测量闭包。
    nonisolated private static let stageSpace = "DashboardCatStage"

    init(
        composition: CompositionModuleContent?,
        mood: MeterCore.CatMood,
        speech: String,
        showsCat: Bool = true,
        monthToDate: MonthToDateModuleContent? = nil,
        comparison: ComparisonModuleContent? = nil,
        trend: TrendModuleContent? = nil,
        onOpenComposition: (() -> Void)? = nil,
        onOpenComparison: (() -> Void)? = nil,
        onSelectSubscription: (() -> Void)? = nil,
        onToggleSubscriptions: ((Bool) -> Void)? = nil,
        onShare: (() -> Void)? = nil,
        pinnedPerch: DashboardCatPerch? = nil
    ) {
        self.monthToDate = monthToDate
        self.composition = composition
        self.comparison = comparison
        self.trend = trend
        self.mood = mood
        self.speech = speech
        self.showsCat = showsCat
        self.onOpenComposition = onOpenComposition
        self.onOpenComparison = onOpenComparison
        self.onSelectSubscription = onSelectSubscription
        self.onToggleSubscriptions = onToggleSubscriptions
        self.onShare = onShare
        self.pinnedPerch = pinnedPerch
        let launched = FeatureLaunchArguments.catPerch.flatMap(DashboardCatPerch.init(rawValue:))
        let available = DashboardCatPerch.available(
            header: monthToDate != nil,
            share: onShare != nil && composition != nil
        )
        _perch = State(initialValue: pinnedPerch ?? launched ?? available.randomElement() ?? .sitHeaderRight)
    }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                accessible
            } else {
                staged
            }
        }
        .onChange(of: mood) { _, _ in
            guard pinnedPerch == nil, FeatureLaunchArguments.catPerch == nil else { return }
            perch = availablePerches.randomElement() ?? perch
        }
    }

    private var availablePerches: [DashboardCatPerch] {
        DashboardCatPerch.available(
            header: monthToDate != nil,
            share: onShare != nil && composition != nil
        )
    }

    /// 钉死的（截图 / gallery）原样用；随机抽到的过一道现场检查：
    /// 两翼塞不下猫（超大字号把胶囊撑宽）时退回合计区，合计也没有就不上猫。
    private var resolvedPerch: DashboardCatPerch? {
        guard showsCat else { return nil }
        if let pinnedPerch { return pinnedPerch }
        if FeatureLaunchArguments.catPerch != nil { return perch }
        switch perch.zone {
        case .header:
            return monthToDate == nil ? nil : perch
        case .share:
            guard onShare != nil, composition != nil, shareFlankFits else {
                return monthToDate == nil ? nil : .sitHeaderRight
            }
            return perch
        }
    }

    /// 胶囊居中，左翼放得下一只猫加边距，右翼就也放得下。
    private var shareFlankFits: Bool {
        guard !shareCapsule.isNull else { return true }
        return shareCapsule.minX - MeterSpacing.pageHorizontal
            >= MeterSpacing.catDashboard + MeterSpacing.xs
    }

    private func isCatReady(_ perch: DashboardCatPerch) -> Bool {
        switch perch.zone {
        case .header: headerHeight > 0
        case .share: !shareCapsule.isNull
        }
    }

    private var accessible: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.sm) {
            if let monthToDate {
                MonthToDateModuleView(
                    content: monthToDate,
                    onSelectSubscription: onSelectSubscription,
                    onToggleSubscriptions: onToggleSubscriptions
                )
                .padding(.horizontal, MeterSpacing.pageHorizontal)
            }
            pieCard
                .padding(.horizontal, MeterSpacing.pageHorizontal)
            if showsTiles {
                DashboardBentoTiles(
                    comparison: comparison,
                    trend: trend,
                    onOpenComparison: onOpenComparison
                )
                    .padding(.horizontal, MeterSpacing.pageHorizontal)
            }
            if onShare != nil {
                shareButton
                    .padding(.horizontal, MeterSpacing.pageHorizontal)
            }
        }
    }

    private var staged: some View {
        let catSize = MeterSpacing.catDashboard
        let sideGutter = MeterSpacing.pageHorizontal
        let bottomOutset = MeterSpacing.catPerchOutset
        let topPad = perchTopPad
        let catZone = resolvedPerch?.zone

        return VStack(alignment: .leading, spacing: 0) {
            if let monthToDate {
                MonthToDateModuleView(
                    content: monthToDate,
                    onSelectSubscription: onSelectSubscription,
                    onToggleSubscriptions: onToggleSubscriptions
                )
                // 合计区的猫画在内容**底下**（见下面的 background），字不给它让位——
                // 以前的右侧留白会随猫的随机落点出现和消失，口径切换跟着一会儿
                // 同排一会儿换行。只保留块高兜底，猫顶才不伸出舞台被 List 裁掉。
                .frame(
                    minHeight: catZone == .header ? DashboardCatPerch.headerMinHeight : nil,
                    alignment: .topLeading
                )
                .padding(.horizontal, sideGutter)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { headerHeight = $0 }
            }
            HStack(spacing: 0) {
                Color.clear.frame(width: sideGutter)
                VStack(alignment: .leading, spacing: MeterSpacing.sm) {
                    VStack(alignment: .leading, spacing: MeterSpacing.sm) {
                        pieCard
                        if showsTiles {
                            DashboardBentoTiles(
                                comparison: comparison,
                                trend: trend,
                                onOpenComparison: onOpenComparison
                            )
                        }
                    }
                    // 垫片用 padding，不要再塞进 VStack——spacing 会在垫片和卡之间再加一截。
                    // 底下那截加上块卡间距，是坐在两翼的猫探头用的净空。
                    .padding(.top, topPad)
                    .padding(.bottom, onShare == nil ? 0 : bottomOutset)
                    if onShare != nil {
                        shareButton
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Color.clear.frame(width: sideGutter)
            }
        }
        .coordinateSpace(name: Self.stageSpace)
        // 合计区的猫垫在内容底下：数字和口径切换是 UI 元件，压在猫身上；
        // 猫是装饰，不许它反过来把 UI 盖掉。两翼的猫仍在最上层——
        // 胶囊两侧本来就是规定出来的空白，没有可压的东西。
        .background { catLayer(.header, catSize: catSize, sideGutter: sideGutter, topPad: topPad) }
        .overlay { catLayer(.share, catSize: catSize, sideGutter: sideGutter, topPad: topPad) }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func catLayer(
        _ zone: DashboardCatPerch.Zone,
        catSize: CGFloat,
        sideGutter: CGFloat,
        topPad: CGFloat
    ) -> some View {
        GeometryReader { geo in
            if let resolved = resolvedPerch, resolved.zone == zone, isCatReady(resolved) {
                // 合计区的锚：舞台顶到构成卡上沿那条横带。两翼的锚：胶囊实测边框。
                let band = CGRect(
                    x: sideGutter,
                    y: 0,
                    width: max(geo.size.width - sideGutter * 2, 0),
                    height: headerHeight + topPad
                )
                perchedCat(resolved.placement(catSize: catSize, header: band, share: shareCapsule))
            }
        }
    }

    private var showsTiles: Bool {
        comparison != nil || trend != nil
    }

    /// 合计在舞台里时，块到卡那截 `sm` 就是猫脚下的沿。
    /// 没有合计（iPad 分栏）时猫只坐分享两翼。卡顶间距交给外层 List：
    /// 有「需要注意」时跟右侧 header 同一格对齐，不要再垫 xs。
    private var perchTopPad: CGFloat {
        monthToDate == nil ? 0 : headerCardGap
    }

    private var headerCardGap: CGFloat { MeterSpacing.sm }

    /// 构成卡只管构成；猫的话不再占卡里一行，读屏时挂在猫身上（见 perchedCat）。
    @ViewBuilder
    private var pieCard: some View {
        if let composition {
            let inner = pieHeader(composition)
                .padding(.horizontal, MeterSpacing.md)
                .padding(.vertical, MeterSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    Color.meterSecondaryGroupedBackground,
                    in: RoundedRectangle(cornerRadius: MeterRadius.groupedCard, style: .continuous)
                )

            if let onOpenComposition {
                Button(action: onOpenComposition) {
                    inner.meterListRowHitTarget()
                }
                .buttonStyle(.plain)
                .accessibilityHint(L("查看构成明细"))
            } else {
                inner
            }
        }
    }

    private func pieHeader(_ composition: CompositionModuleContent) -> some View {
        HStack(alignment: .top, spacing: MeterSpacing.xs) {
            CompositionModuleView(content: composition)
            Image(systemName: "chevron.right")
                .font(MeterFont.footnote.weight(.semibold))
                .foregroundStyle(Color.meterTertiaryLabel)
                .padding(.top, MeterSpacing.xxs)
                .accessibilityHidden(true)
        }
    }

    /// 页内胶囊：同一颗 borderedProminent，regular 高度。套底栏那颗 large 会像没写完的主操作条。
    /// 宽度跟内容走。热区不到 44 时把命中框垫到 `minTap`，胶囊本身不拉高。
    private var shareButton: some View {
        Button(action: { onShare?() }) {
            HStack(alignment: .center, spacing: MeterSpacing.xxs) {
                Image(systemName: "square.and.arrow.up")
                    .symbolRenderingMode(.monochrome)
                    .font(MeterFont.body.weight(.semibold))
                    .accessibilityHidden(true)
                Text(L("分享"))
                    .font(MeterFont.body.weight(.semibold))
            }
            .padding(.horizontal, MeterSpacing.sm)
        }
        .meterInlineActionStyle()
        .fixedSize()
        // 量的是收拢后的胶囊本体，不是拉满的那行——两翼的猫贴着它坐。
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .named(Self.stageSpace))
        } action: { shareCapsule = $0 }
        .frame(minHeight: MeterSpacing.minTap)
        .contentShape(Capsule())
        .frame(maxWidth: .infinity)
        .accessibilityLabel(L("分享这个月的账单卡片"))
    }

    private func perchedCat(_ placement: DashboardCatPlacement) -> some View {
        // 话从卡里删了，猫替它说：读屏读到猫时给「表情。台词」。
        CatView(mood: MeterDesign.CatMood(mood), size: MeterSpacing.catDashboard)
            .modifier(DashboardCatHop(placement: placement, perch: perch))
            .allowsHitTesting(false)
            .accessibilityLabel(speechAccessibility)
    }

    private var speechAccessibility: String {
        let moodText = String(localized: MeterDesign.CatMood(mood).accessibilityLabel)
        return "\(moodText)。\(speech)"
    }
}

#Preview("Light") {
    List {
        Section {
            DashboardCatStage(
                composition: DashboardCatStagePreview.sample,
                mood: .saved,
                speech: String(localized: L("这个月比上个月同期少花了 \(12)%。")),
                monthToDate: DashboardCatStagePreview.monthToDate,
                comparison: DashboardCatStagePreview.comparison,
                trend: DashboardCatStagePreview.trend,
                onShare: {},
                pinnedPerch: .sitHeaderRight
            )
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    List {
        Section {
            DashboardCatStage(
                composition: DashboardCatStagePreview.sample,
                mood: .shocked,
                speech: String(localized: L("合计较上月同期涨了 \(62)%。")),
                comparison: DashboardCatStagePreview.comparison,
                trend: DashboardCatStagePreview.trend,
                onShare: {},
                pinnedPerch: .sitShareLeft
            )
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("XXL") {
    List {
        Section {
            DashboardCatStage(
                composition: DashboardCatStagePreview.sample,
                mood: .sleeping,
                speech: String(localized: L("还没有账单。")),
                monthToDate: DashboardCatStagePreview.monthToDate,
                comparison: DashboardCatStagePreview.comparison,
                trend: DashboardCatStagePreview.trend,
                onShare: {},
                pinnedPerch: .sitShareRight
            )
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        }
    }
    .dynamicTypeSize(.accessibility3)
}

private enum DashboardCatStagePreview {
    static let monthToDate = MonthToDateModuleContent.make(
        from: MonthToDate(
            totalUSD: Money(roundedUSD: 47.20),
            projectedMonthEndUSD: Money(roundedUSD: 87.70),
            confidence: .estimated,
            estimatedAccounts: [AccountID.fixture(for: .neon)],
            facts: [],
            variableUSD: Money(roundedUSD: 47.20),
            projectedVariableUSD: Money(roundedUSD: 87.70)
        ),
        estimatedNames: ["Neon"],
        staleCaption: nil,
        now: MeterClock.design.now,
        calendar: MeterClock.design.calendar
    )

    static let sample = CompositionModuleContent(
        segments: [
            CompositionSegment(
                accountID: AccountID.fixture(for: .aws),
                providerID: .aws,
                displayName: "AWS",
                colorKey: "aws",
                amount: Money(roundedUSD: 21.40),
                fraction: 0.4534,
                percent: 45
            ),
            CompositionSegment(
                accountID: AccountID.fixture(for: .cloudflare),
                providerID: .cloudflare,
                displayName: "Cloudflare",
                colorKey: "cloudflare",
                amount: Money(roundedUSD: 11.05),
                fraction: 0.2341,
                percent: 23
            ),
        ],
        totalText: Money(roundedUSD: 47.20).formatted(),
        spokenTotal: String(localized: L("47 美元 20 美分")),
        destination: AccountID.fixture(for: .aws)
    )

    static let comparisonCaption = String(localized: L("对比 \("7 月")同期 \("$29.10")"))
    static let comparison = ComparisonModuleContent(
        percentText: "+62%",
        caption: comparisonCaption,
        spokenLabel: String(localized: L("按量较上月同期 \(DashboardPercentFormat.spokenSigned(0.62))，\(comparisonCaption)")),
        current: 47.2,
        previous: 29.1,
        currentLabel: String(localized: L("本月")),
        previousLabel: String(localized: L("上月")),
        tone: .up
    )

    static let trend: TrendModuleContent = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let lastMonth = Date(timeIntervalSince1970: 1_787_616_000)
        let start = calendar.date(byAdding: .month, value: -5, to: lastMonth) ?? lastMonth
        let points: [PlotPoint] = [12, 18, 9, 22, 15, 21].enumerated().compactMap { index, amount in
            calendar.date(byAdding: .month, value: index, to: start).map {
                PlotPoint(date: $0, amount: Double(amount))
            }
        }
        return TrendModuleContent(
            points: points,
            xStart: start,
            xEnd: CompactMonthBarChart.domainEnd(afterLastMonthStart: lastMonth, calendar: calendar),
            highlight: lastMonth,
            spokenLabel: String(localized: L("近几个月按量"))
        )
    }()
}
