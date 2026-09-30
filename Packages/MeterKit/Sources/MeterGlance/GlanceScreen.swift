#if os(watchOS)
import SwiftUI

/// 手表 App：本月、预算、花得最多的几家，各占一页，表冠一页一页翻。
///
/// 竖向分页而不是一条长列表：每页一件事、各有一层底色，翻过去就知道换了一段——
/// 和系统的天气、活动是同一种手势。最后一页（服务）自己能滚，滚到底表冠才停。
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
            TabView {
                GlanceMonthPage(month: month, synced: GlanceText.synced(glance?.lastRefreshAt, now: now))
                    .containerBackground(GlanceStyle.accent.gradient, for: .tabView)
                if let budget = month.budget {
                    GlanceBudgetPage(budget: budget)
                        .containerBackground(GlanceStyle.color(for: budget.level).gradient, for: .tabView)
                }
                if !month.services.isEmpty {
                    GlanceServicesPage(services: month.services)
                        .containerBackground(Color.gray.gradient, for: .tabView)
                }
            }
            .tabViewStyle(.verticalPage)
        case .noBills:
            message(GlanceText.noBills, detail: GlanceText.noBillsHint, now: now)
        case .waitingForMonth:
            message(GlanceText.waitingForMonth, detail: nil, now: now)
        case .neverSynced:
            message(GlanceText.neverSynced, detail: GlanceText.neverSyncedDetail, now: now)
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

/// 一页的骨架：左上一行段名，下面是这一段的内容，贴顶排。
struct GlancePage<Accessory: View, Content: View>: View {
    let title: LocalizedStringResource
    @ViewBuilder var accessory: Accessory
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.headline)
                accessory
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .scenePadding(.horizontal)
    }
}

/// 第一页：大数字、预计月底，最底下一行这些数有多新。
struct GlanceMonthPage: View {
    let month: GlanceMonth
    let synced: LocalizedStringResource?

    var body: some View {
        GlancePage(title: GlanceText.monthTitle) {
            if let period = month.periodText {
                Text(verbatim: period)
            }
        } content: {
            Text(verbatim: month.amountText)
                .font(.system(size: 40, weight: .bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            if let projection = month.projectionText {
                Text(verbatim: projection)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            if let overspend = month.budget?.projectedOverspendText {
                Text(verbatim: overspend)
                    .font(.body)
                    .foregroundStyle(GlanceStyle.color(for: .close))
                    .monospacedDigit()
            }
            Spacer(minLength: 8)
            if let synced {
                Text(synced)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(GlanceText.spokenMonth(month))
    }
}

/// 预算页：用了几成、一根条、还剩多少（或超出多少）。
struct GlanceBudgetPage: View {
    let budget: GlanceBudget

    var body: some View {
        GlancePage(title: GlanceText.budgetTitle) {
            Spacer(minLength: 4)
            Text(verbatim: budget.limitText)
                .monospacedDigit()
        } content: {
            Text(verbatim: budget.percentText)
                .font(.system(size: 40, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(GlanceStyle.color(for: budget.level))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Gauge(value: min(max(budget.fraction, 0), 1)) {
                EmptyView()
            }
            .gaugeStyle(.linearCapacity)
            .tint(GlanceStyle.color(for: budget.level))
            Text(verbatim: budget.caption)
                .font(.body)
                .foregroundStyle(budget.level == .over ? AnyShapeStyle(GlanceStyle.color(for: .over)) : AnyShapeStyle(.secondary))
                .monospacedDigit()
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(budget.spokenLabel)
    }
}

/// 最后一页：花得最多的几家。多了自己滚；有详情的那几家点进去（「其他」不能点）。
struct GlanceServicesPage: View {
    let services: [GlanceService]

    var body: some View {
        List {
            Section {
                ForEach(services) { service in
                    if let detail = service.detail {
                        NavigationLink {
                            GlanceServiceDetailView(service: service, detail: detail)
                        } label: {
                            GlanceScreenServiceRow(service: service)
                        }
                    } else {
                        GlanceScreenServiceRow(service: service)
                    }
                }
            } header: {
                Text(GlanceText.servicesTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .textCase(nil)
            }
        }
    }
}

/// 一家一行：名次色点、名字、金额。
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
    NavigationStack {
        GlanceScreen(glance: GlanceSamples.month)
    }
}

#Preview("手表 App · 会超预算") {
    NavigationStack {
        GlanceScreen(glance: GlanceSamples.overBudget)
    }
}

#Preview("手表 App · 空") {
    GlanceScreen(glance: nil)
}
#endif
