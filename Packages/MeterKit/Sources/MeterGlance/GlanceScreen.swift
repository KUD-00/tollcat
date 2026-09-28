import SwiftUI

/// 手表 App 唯一的一屏：本月金额、预算、花得最多的几家、这些数有多新。
///
/// 只读。添加服务、填凭据、设预算都在 iPhone 上做——41mm 的屏幕上塞不下，也没人会在手表上做。
public struct GlanceScreen: View {
    private let glance: Glance?

    public init(glance: Glance?) {
        self.glance = glance
    }

    public var body: some View {
        // 「几分钟前」和跨月都是时间一走就要变的话，每分钟重算一次。
        TimelineView(.everyMinute) { context in
            content(now: context.date)
        }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        switch GlanceDisplay.resolve(glance, now: now) {
        case let .month(month, _):
            List {
                GlanceScreenHeader(month: month)
                    .listRowBackground(Color.clear)
                if let budget = month.budget {
                    Section {
                        GlanceScreenBudgetRow(budget: budget)
                    }
                }
                if !month.services.isEmpty {
                    Section {
                        ForEach(month.services) { service in
                            GlanceScreenServiceRow(service: service)
                        }
                    } header: {
                        Text(GlanceText.servicesTitle)
                    }
                }
                footer(now: now)
            }
        case .noBills:
            message(GlanceText.noBills, detail: GlanceText.noBillsHint, now: now)
        case .waitingForMonth:
            message(GlanceText.waitingForMonth, detail: nil, now: now)
        case .neverSynced:
            message(GlanceText.neverSynced, detail: GlanceText.neverSyncedDetail, now: now)
        }
    }

    @ViewBuilder
    private func footer(now: Date) -> some View {
        if let synced = GlanceText.synced(glance?.lastRefreshAt, now: now) {
            Text(synced)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .listRowBackground(Color.clear)
        }
    }

    private func message(_ title: LocalizedStringResource, detail: LocalizedStringResource?, now: Date) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                Text(GlanceText.monthTitle)
                    .font(.headline)
                    .foregroundStyle(GlanceStyle.accent)
                Text(title)
                    .font(.title3.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                if let detail {
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let synced = GlanceText.synced(glance?.lastRefreshAt, now: now) {
                    Text(synced)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .scenePadding(.horizontal)
        }
    }
}

/// 最上面那块：标题、大数字、预计月底。
struct GlanceScreenHeader: View {
    let month: GlanceMonth

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                Text(GlanceText.monthTitle)
                    .font(.headline)
                    .foregroundStyle(GlanceStyle.accent)
                if let period = month.periodText {
                    Text(verbatim: period)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Text(verbatim: month.amountText)
                .font(.system(size: 36, weight: .bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            if let projection = month.projectionText {
                Text(verbatim: projection)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            if let overspend = month.budget?.projectedOverspendText {
                Text(verbatim: overspend)
                    .font(.footnote)
                    .foregroundStyle(GlanceStyle.color(for: .close))
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(GlanceText.spokenMonth(month))
    }
}

/// 预算那一行：一根条，一句还剩多少。
struct GlanceScreenBudgetRow: View {
    let budget: GlanceBudget

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(GlanceText.budgetTitle)
                    .font(.headline)
                Spacer(minLength: 4)
                Text(verbatim: budget.limitText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Gauge(value: min(max(budget.fraction, 0), 1)) {
                EmptyView()
            }
            .gaugeStyle(.linearCapacity)
            .tint(GlanceStyle.color(for: budget.level))
            Text(verbatim: budget.caption)
                .font(.footnote)
                .foregroundStyle(budget.level == .over ? AnyShapeStyle(GlanceStyle.color(for: .over)) : AnyShapeStyle(.secondary))
                .monospacedDigit()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(budget.spokenLabel)
    }
}

/// 一家一行：名次色点、名字、金额。不能点——手表上没有详情页。
struct GlanceScreenServiceRow: View {
    let service: GlanceService

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(GlanceStyle.color(for: service))
                .frame(width: 8, height: 8)
            Text(verbatim: service.name)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 4)
            Text(verbatim: service.amountText)
                .monospacedDigit()
                .lineLimit(1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(service.name)，\(service.spokenAmount)")
    }
}

#Preview("手表 App") {
    GlanceScreen(glance: GlanceSamples.month)
        .environment(\.colorScheme, .dark)
}

#Preview("手表 App · 空") {
    GlanceScreen(glance: nil)
        .environment(\.colorScheme, .dark)
}
