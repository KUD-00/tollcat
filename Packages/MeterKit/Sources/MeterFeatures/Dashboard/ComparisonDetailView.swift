import SwiftUI
import MeterCore
import MeterDesign
import MeterModules

/// 较上月同期的追查页。主角柱和涨跌幅含还不能比的本月金额；
/// 缺同期的另开一节，行上不当 $0、不编百分比。
struct ComparisonDetailView: View {
    let content: ComparisonModuleContent

    var body: some View {
        MeterGroupedList {
            // 主角段落用默认的白底行——透明底会让百分比和柱图看起来悬在页面上。
            Section {
                hero
                    .listRowSeparator(.hidden)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(content.spokenLabel)
            }

            if !content.comparableItems.isEmpty {
                Section {
                    ForEach(content.comparableItems) { item in
                        row(item)
                        sublineRows(item)
                    }
                }
            }

            if !content.incomparableItems.isEmpty {
                Section {
                    ForEach(content.incomparableItems) { item in
                        row(item)
                        sublineRows(item)
                    }
                } header: {
                    Text(L("还不能对比"))
                } footer: {
                    Text(L("没有上月同一段日子的按量花费。本月金额已经算进上面的柱和涨跌幅。"))
                }
            }
        }
        .navigationTitle(L("较上月同期"))
        .navigationBarTitleDisplayMode(.large)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.sm) {
            Text(content.percentText)
                .font(MeterFont.largeTitle.weight(.semibold))
                .foregroundStyle(heroPercentColor)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .contentTransition(.numericText(value: content.current))
            Text(content.windowCaption)
                .font(MeterFont.subheadline)
                .foregroundStyle(Color.meterSecondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
            if content.tone != .unknown || content.current > 0 {
                CompactComparisonBars(
                    current: content.current,
                    previous: content.tone == .unknown ? nil : content.previous,
                    currentLabel: content.currentLabel,
                    previousLabel: content.previousLabel,
                    plotHeight: MeterSpacing.donut,
                    isInteractive: true
                )
                .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, MeterSpacing.xs)
    }

    @ViewBuilder
    private func row(_ item: ComparisonItem) -> some View {
        let inner = DashboardInsightRow(
            colorKey: item.colorKey,
            title: item.displayName,
            subtitle: item.subtitle(previousMonthName: content.previousMonthName),
            trailingText: item.trailingText,
            trailingColor: trailingColor(item.tone),
            spokenLabel: item.spokenLabel(previousMonthName: content.previousMonthName),
            animationValue: NSDecimalNumber(decimal: item.currentUSD.usd).doubleValue
        )
        // 挂厂商的无主订阅段没有账号，但详情页本来就按厂商开，照样可点。
        // 只有「手动订阅」段（连厂商都没有）无处可去，摆成普通行。
        if let accountID = item.accountID {
            DashboardRouteLink(route: .account(accountID)) {
                inner
            }
            .accessibilityHint(L("查看 \(item.displayName) 详情"))
        } else if let providerID = item.providerID {
            DashboardRouteLink(route: .provider(providerID)) {
                inner
            }
            .accessibilityHint(L("查看 \(item.displayName) 详情"))
        } else {
            inner
        }
    }

    /// 这一家的钱花在了哪些子服务上。和构成页、「花在哪了」全屏页同一个
    /// `SpendSublineRow`；缩进对齐 glyph 后面的名字，不是对齐 glyph 本身。
    private func sublineRows(_ item: ComparisonItem) -> some View {
        ForEach(item.sublines) { subline in
            SpendSublineRow(
                title: subline.title,
                amountCaption: subline.amountCaption,
                comparisonSubtitle: subline.comparisonSubtitle,
                changeCaption: subline.changeCaption,
                changeRatio: subline.changeRatio,
                indent: MeterSpacing.providerGlyph + MeterSpacing.sm,
                spokenLabel: subline.spokenLabel
            )
        }
    }

    private var heroPercentColor: Color {
        switch content.tone {
        case .up: MeterColor.warn
        case .down: MeterColor.good
        case .flat, .unknown: Color.meterLabel
        }
    }

    private func trailingColor(_ tone: ComparisonModuleContent.Tone) -> Color {
        switch tone {
        case .up: MeterColor.warn
        case .down: MeterColor.good
        case .flat, .unknown: Color.meterSecondaryLabel
        }
    }
}

#Preview("Light") {
    NavigationStack {
        ComparisonDetailView(content: ComparisonDetailPreview.partial)
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        ComparisonDetailView(content: ComparisonDetailPreview.partial)
    }
    .preferredColorScheme(.dark)
}

#Preview("都不能比") {
    NavigationStack {
        ComparisonDetailView(content: ComparisonDetailPreview.unknown)
    }
}

private enum ComparisonDetailPreview {
    static let partial = ComparisonBuilder.make(
        from: MonthToDate(
            totalUSD: Money(usd: 30),
            projectedMonthEndUSD: Money(usd: 30),
            confidence: .exact,
            estimatedAccounts: [],
            facts: [
                Fact(
                    providerID: .aws,
                    accountID: AccountID.fixture(for: .aws),
                    kind: .usage,
                    amountUSD: Money(usd: 20),
                    comparisonUSD: Money(usd: 10),
                    changeRatio: 1,
                    confidence: .exact,
                    type: .monthToDateUsage
                ),
                Fact(
                    providerID: .neon,
                    accountID: AccountID.fixture(for: .neon),
                    kind: .usage,
                    amountUSD: Money(usd: 10),
                    confidence: .exact,
                    type: .monthToDateUsage
                ),
            ],
            comparisonWindow: ComparisonWindow(
                start: Date(timeIntervalSince1970: 1_783_468_800),
                end: Date(timeIntervalSince1970: 1_784_851_200),
                dayOfMonth: 16
            ),
            variableUSD: Money(usd: 30),
            projectedVariableUSD: Money(usd: 30)
        ),
        calendar: {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(secondsFromGMT: 0)!
            return calendar
        }(),
        sublines: [
            .account(AccountID.fixture(for: .aws)): [
                SpendSubline(
                    id: "EC2",
                    title: "EC2",
                    amountCaption: "$12.10",
                    spokenLabel: "EC2 较上月同期上升百分之 73，本月 $12.10 · 7 月同期 $7.00",
                    comparisonSubtitle: "本月 $12.10 · 7 月同期 $7.00",
                    changeCaption: "+73%",
                    changeRatio: 0.73
                ),
                SpendSubline(
                    id: "S3",
                    title: "S3",
                    amountCaption: "$6.30",
                    spokenLabel: "S3，6 美元 30 美分"
                ),
            ],
        ]
    )

    static let unknown = ComparisonBuilder.make(
        from: MonthToDate(
            totalUSD: Money(usd: 10),
            projectedMonthEndUSD: Money(usd: 10),
            confidence: .exact,
            estimatedAccounts: [],
            facts: [
                Fact(
                    providerID: .neon,
                    accountID: AccountID.fixture(for: .neon),
                    kind: .usage,
                    amountUSD: Money(usd: 10),
                    confidence: .exact,
                    type: .monthToDateUsage
                ),
            ],
            variableUSD: Money(usd: 10),
            projectedVariableUSD: Money(usd: 10)
        ),
        calendar: Calendar(identifier: .gregorian)
    )
}
