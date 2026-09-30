#if os(watchOS)
import Charts
import SwiftUI

/// 手表 App 里点进一家服务：本月多少、较上月同期、近 30 天每天、余额、花在哪了。
///
/// 一段一个圆角块（List 的 Section），和首页一样表冠滚下去有段落感。
/// 只读，数都是 iPhone 排好推来的。
struct GlanceServiceDetailView: View {
    let service: GlanceService
    let detail: GlanceServiceDetail

    private var tint: Color { GlanceStyle.color(for: service) }

    var body: some View {
        List {
            Section {
                header
                    .listRowBackground(Color.clear)
            }
            if !detail.days.isEmpty {
                Section {
                    // 说明和图放在同一块里：List 里每个子视图各占一块，分开放就成了两段。
                    VStack(alignment: .leading, spacing: 6) {
                        GlanceDailyChart(days: detail.days, tint: tint)
                        if let note = detail.subscriptionNote {
                            Text(verbatim: note)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            if let balance = detail.balance {
                Section {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: balance.balanceText)
                            .font(.headline)
                            .monospacedDigit()
                        if let runway = balance.runwayText {
                            Text(verbatim: runway)
                                .font(.body)
                                .foregroundStyle(balance.isLow ? AnyShapeStyle(GlanceStyle.crit) : AnyShapeStyle(.secondary))
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            if !detail.sublines.isEmpty {
                Section {
                    ForEach(detail.sublines) { line in
                        HStack(spacing: 6) {
                            Text(verbatim: line.title)
                                .lineLimit(2)
                            Spacer(minLength: 4)
                            Text(verbatim: line.amountText)
                                .monospacedDigit()
                                .lineLimit(1)
                        }
                        .accessibilityElement(children: .combine)
                    }
                } header: {
                    Text(GlanceText.sublinesTitle)
                }
            }
        }
        .navigationTitle(Text(verbatim: service.name))
        .containerBackground(tint.gradient, for: .navigation)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: service.amountText)
                .font(.system(size: 34, weight: .bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .accessibilityLabel(service.spokenAmount)
            if let share = detail.shareText {
                Text(verbatim: share)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if let change = detail.change {
                Text(verbatim: change.text)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(color(for: change.direction))
                    .monospacedDigit()
                    .padding(.top, 4)
                Text(verbatim: change.detailText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 和分享卡、对比卡同一套：花得多了是橙，少了是绿。
    private func color(for direction: GlanceChange.Direction) -> AnyShapeStyle {
        switch direction {
        case .up: AnyShapeStyle(GlanceStyle.warn)
        case .down: AnyShapeStyle(GlanceStyle.good)
        case .flat: AnyShapeStyle(.secondary)
        }
    }
}

/// 近 30 天每天一根柱。
///
/// 手指按住拖是临时看一眼；点一下图表拿到焦点后转表冠，一天一格地走、每格一下震动，
/// 松开焦点（点别处或滚走）就回到「近 30 天」。上方那行读出选中那天是哪天、多少钱。
struct GlanceDailyChart: View {
    let days: [GlanceDay]
    let tint: Color

    @State private var touched: Date?
    @State private var crown: Double = 0
    @FocusState private var isFocused: Bool

    private var selected: GlanceDay? {
        if let touched {
            return days.min { abs($0.date.distance(to: touched)) < abs($1.date.distance(to: touched)) }
        }
        guard isFocused, !days.isEmpty else { return nil }
        let index = min(max(Int(crown.rounded()), 0), days.count - 1)
        return days[index]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            readout
            Chart(days) { day in
                BarMark(
                    x: .value(String(localized: L("日期")), day.date, unit: .day),
                    y: .value(String(localized: L("金额")), day.value)
                )
                .foregroundStyle(tint.opacity(selected == nil || selected == day ? 1 : 0.35))
                .cornerRadius(1.5)
                .accessibilityLabel(Text(day.date, format: .dateTime.month().day()))
                .accessibilityValue(Text(verbatim: day.amountText))
            }
            .chartYAxis(.hidden)
            .chartXAxis {
                // 从今天往回每 7 天一个刻度，最右边那个就是今天；`.aligned` 让两头的字不出框。
                AxisMarks(preset: .aligned, values: axisDates) {
                    AxisValueLabel(format: .dateTime.day())
                }
            }
            .chartXSelection(value: $touched)
            .frame(height: 72)
        }
        .focusable()
        .focused($isFocused)
        .digitalCrownRotation(
            $crown,
            from: 0,
            through: Double(max(days.count - 1, 0)),
            by: 1,
            sensitivity: .low,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        // 拿到焦点先停在今天：最新的一天是最常要看的。
        .onChange(of: isFocused) { _, focused in
            if focused { crown = Double(max(days.count - 1, 0)) }
        }
    }

    private var axisDates: [Date] {
        stride(from: days.count - 1, through: 0, by: -7).map { days[$0].date }
    }

    private var readout: some View {
        HStack(alignment: .firstTextBaseline) {
            if let selected {
                Text(selected.date, format: .dateTime.month().day())
                    .foregroundStyle(.secondary)
                Spacer(minLength: 4)
                Text(verbatim: selected.amountText)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            } else {
                Text(GlanceText.last30Days)
                    .foregroundStyle(.secondary)
            }
        }
        .font(.footnote)
        .lineLimit(1)
    }
}

#Preview("服务详情") {
    NavigationStack {
        if case let .month(month) = GlanceSamples.month.content,
           let service = month.services.first,
           let detail = service.detail {
            GlanceServiceDetailView(service: service, detail: detail)
        }
    }
}
#endif
