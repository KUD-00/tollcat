import SwiftUI
import MeterCore
import MeterDesign

/// 金额本身不挂精度记号。用户看首屏是想知道「这个月花了多少」，
/// 「其中有几家是估的」属于追查时才需要的信息——由「含估算」那行小字承担。
///
/// `MonthToDate.confidence` 照旧计算并入库，provider 详情页仍然按家展示精度。
public struct MonthToDateModuleView: View {
    public let content: MonthToDateModuleContent
    public var onSelectSubscription: (() -> Void)? = nil
    public var onToggleSubscriptions: ((Bool) -> Void)? = nil

    public init(
        content: MonthToDateModuleContent,
        onSelectSubscription: (() -> Void)? = nil,
        onToggleSubscriptions: ((Bool) -> Void)? = nil
    ) {
        self.content = content
        self.onSelectSubscription = onSelectSubscription
        self.onToggleSubscriptions = onToggleSubscriptions
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.moduleWidth) private var width

    /// 挤到 compact（2×2 的 widget）时只留大数字和预计月底。
    /// 限定语、币种注、订阅那行、陈旧提示都是**整句**，126pt 宽里每句要折三行，
    /// 折完就把主角挤没了。**这一条看宽不看高**：4×2 同样只有一格高，
    /// 但 306pt 宽一句一行放得下，那一档保持原样。
    private var showsCaptions: Bool { width > .compact }

    /// 数字底下那行小字。挤到 compact 时只留「预计月底 $87.70」，
    /// 统计区间那半句掐掉——126pt 宽里接上「9月1日至6日」就要折成三行。
    /// 回看过去某个月没有可推的东西，那一档留下的是区间本身（「整月 · 七月」）。
    private var captionLine: String? {
        guard showsCaptions else { return content.projectedCaption ?? content.periodCaption }
        return content.fullProjectedCaption
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
            amountRow

            if let captionLine {
                Text(captionLine)
                    .font(MeterFont.subheadline)
                    .foregroundStyle(Color.meterSecondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    // 读的始终是完整那句：VoiceOver 没有版面预算，区间不该跟着掐掉。
                    .accessibilityLabel(content.spokenProjected ?? captionLine)
            }

            if showsCaptions, let subscriptionCaption = content.subscriptionCaption {
                subscriptionLine(subscriptionCaption)
            }

            if showsCaptions, let currencyNote = content.currencyNote {
                Text(currencyNote)
                    .font(MeterFont.footnote)
                    .foregroundStyle(Color.meterTertiaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(currencyNote)
            }

            // 限定语跟着数字走，不做成会滚走的横幅。
            if showsCaptions, let filterNote = content.filterNote {
                Label(filterNote, systemImage: "line.3.horizontal.decrease")
                    .font(MeterFont.footnote)
                    .foregroundStyle(Color.accentColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, MeterSpacing.xxs)
                    .accessibilityLabel(L("筛选中：\(filterNote)"))
            }

            if showsCaptions, let staleCaption = content.staleCaption {
                Text(staleCaption)
                    .font(MeterFont.footnote)
                    .foregroundStyle(MeterColor.warn)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        // 大标题底下那 8pt content margin 不够 34pt 顶边。垫一截，数字才不贴「八月」。
        .padding(.top, MeterSpacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 数字和口径切换同一行；挤不下（超大金额、猫占着右侧、超大字号）时
    /// 切换落到数字下一行——**宁可多占一行，不缩小数字**。
    /// 同排那份金额用 `fixedSize` 报出全尺寸宽度，`ViewThatFits` 才知道
    /// 「放不下」；落行那份保留 `minimumScaleFactor` 兜自己的底。
    @ViewBuilder
    private var amountRow: some View {
        if let scopeControl, !dynamicTypeSize.isAccessibilitySize {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: MeterSpacing.sm) {
                    amountText(scalable: false)
                    // HStack 的 spacing 两侧各 12，数字和胶囊之间本来就隔着 24；
                    // Spacer 再要 12 只是让四位数金额提前掉行。
                    Spacer(minLength: 0)
                    scopeControl
                }
                VStack(alignment: .leading, spacing: MeterSpacing.xs) {
                    amountText(scalable: true)
                    scopeControl
                }
            }
        } else if let scopeControl {
            // 超大字号下数字自己就要一整行，切换固定在下一行，不跟数字挤。
            amountText(scalable: true)
            scopeControl
        } else {
            amountText(scalable: true)
        }
    }

    private func amountText(scalable: Bool) -> some View {
        Text(content.amountText)
            .meterAmountStyle()
            .foregroundStyle(Color.meterLabel)
            .minimumScaleFactor(scalable ? 0.6 : 1)
            .lineLimit(1)
            // 34pt 数字的字形会画出 SwiftUI 行框；List 再裁行，顶边的 $ / 7 会被削。
            .fixedSize(horizontal: !scalable, vertical: true)
            .contentTransition(.numericText(value: content.totalValue))
            .accessibilityLabel(content.spokenTotal)
            .accessibilityIdentifier(UITestID.dashboardTotal)
            .animation(DashboardMotion.number, value: content.totalValue)
    }

    /// 有订阅可切、外面接了线，才摆这颗。没有订阅时它是死重。
    private var scopeControl: SubscriptionScopeControl? {
        guard let onToggleSubscriptions, content.showsSubscriptionScope else { return nil }
        return SubscriptionScopeControl(
            includesSubscriptions: content.includesSubscriptions,
            onChange: onToggleSubscriptions
        )
    }

    @ViewBuilder
    private func subscriptionLine(_ caption: String) -> some View {
        let label = Text(caption)
            .font(MeterFont.subheadline)
            .foregroundStyle(Color.meterSecondaryLabel)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(content.spokenSubscription ?? caption)
        if let onSelectSubscription, content.subscriptionAccountID != nil {
            Button(action: onSelectSubscription) {
                label
                    .meterListRowHitTarget()
            }
            .buttonStyle(.plain)
            .accessibilityHint(L("查看这家的订阅详情"))
        } else {
            label
        }
    }

}

#Preview("Light") {
    List {
        Section {
            MonthToDateModuleView(content: MonthToDatePreviewData.sample)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    List {
        Section {
            MonthToDateModuleView(content: MonthToDatePreviewData.stale)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("XXL") {
    List {
        Section {
            MonthToDateModuleView(content: MonthToDatePreviewData.sample)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
    }
    .dynamicTypeSize(.accessibility3)
}

/// 预览直接摆现成的值。折算（`MonthToDateModuleContent.make`）在 MeterFeatures，
/// 模块这一层看不到，也不该看到——它只负责把已经算好的字摆对。
private enum MonthToDatePreviewData {
    static let sample = MonthToDateModuleContent(
        estimateCaption: "含预估",
        amountText: "$47.20",
        totalValue: 47.20,
        spokenTotal: String(localized: L("47 美元 20 美分")),
        projectedCaption: "预计月底 $87.70",
        periodCaption: "9月1日至6日",
        projectedValue: 87.70,
        spokenProjected: "预计月底 87 美元 70 美分",
        estimatedNames: ["Neon"],
        staleCaption: nil,
        filterNote: nil,
        currencyNote: nil,
        subscriptionCaption: "本月订阅 $24.00 · 已计入",
        spokenSubscription: "本月订阅 24 美元，已计入合计",
        subscriptionAccountID: nil,
        includesSubscriptions: true,
        showsSubscriptionScope: true
    )

    static let stale = MonthToDateModuleContent(
        estimateCaption: "含预估",
        amountText: "$47.20",
        totalValue: 47.20,
        spokenTotal: String(localized: L("47 美元 20 美分")),
        projectedCaption: "预计月底 $87.70",
        periodCaption: "9月1日至6日",
        projectedValue: 87.70,
        spokenProjected: "预计月底 87 美元 70 美分",
        estimatedNames: ["Neon"],
        staleCaption: String(localized: L("部分数据陈旧，仍显示上次成功的数字")),
        filterNote: nil,
        currencyNote: nil,
        subscriptionCaption: nil,
        spokenSubscription: nil,
        subscriptionAccountID: nil,
        includesSubscriptions: false,
        showsSubscriptionScope: false
    )
}
