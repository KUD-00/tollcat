import Foundation
import Observation
import MeterCore
import MeterFormat
import MeterProviders

@MainActor
@Observable
final class ManualUsageEntryModel {
    var amountText = ""
    var periodDate: Date
    var saveToken = 0
    let providerID: ProviderID
    private let accountID: AccountID?
    private let dashboard: DashboardModel

    init(providerID: ProviderID, accountID: AccountID?, dashboard: DashboardModel) {
        self.providerID = providerID
        self.accountID = accountID
        self.dashboard = dashboard
        let calendar = dashboard.clock.calendar
        let now = dashboard.clock.now
        periodDate = Self.startOfMonth(now, calendar: calendar)
        amountText = Self.amountText(dashboard: dashboard, accountID: accountID, period: periodDate)
    }

    var displayName: String {
        ProviderCatalog.descriptor(id: providerID)?.displayName ?? providerID.rawValue
    }

    var billingURL: URL? {
        ProviderCatalog.descriptor(id: providerID)?.billingURL
    }

    var calendar: Calendar { dashboard.clock.calendar }
    var now: Date { dashboard.clock.now }

    var earliestPeriod: Date {
        let start = Self.startOfMonth(now, calendar: calendar)
        // 和详情页「12 个月」图同一窗口：含本月共 12 根柱。
        return calendar.date(byAdding: .month, value: -11, to: start) ?? start
    }

    var latestPeriod: Date {
        Self.startOfMonth(now, calendar: calendar)
    }

    var isCurrentPeriod: Bool {
        calendar.isDate(periodDate, equalTo: now, toGranularity: .month)
    }

    var navigationTitle: String {
        accountID == nil
            ? String(localized: L("填入本月花费"))
            : String(localized: L("更新花费"))
    }

    var amountHeader: String {
        if isCurrentPeriod {
            return String(localized: L("本月至今"))
        }
        return MeterDateFormat.yearMonth(periodDate, calendar: calendar)
    }

    var footer: String {
        if isCurrentPeriod {
            return String(localized: L("填控制台 Billing 页上本月至今的数。每次保存记一条读数，本月合计用最新这条。"))
        }
        return String(localized: L("填控制台 Billing 页上那个月的合计。每次保存记一条读数，那个月合计用最新这条。"))
    }

    var canSave: Bool {
        parsedAmount != nil
    }

    var parsedAmount: Money? {
        SubscriptionEditorModel.parseAmount(amountText)
    }

    func setPeriod(_ date: Date) {
        let clamped = clamp(date)
        let changed = !calendar.isDate(clamped, equalTo: periodDate, toGranularity: .month)
        periodDate = clamped
        if changed {
            amountText = Self.amountText(dashboard: dashboard, accountID: accountID, period: clamped)
        }
    }

    func save() throws {
        guard let amount = parsedAmount else { return }
        try dashboard.applyManualUsage(
            providerID: providerID,
            amount: amount,
            to: accountID,
            period: periodDate
        )
        saveToken += 1
    }

    private func clamp(_ date: Date) -> Date {
        var value = Self.startOfMonth(date, calendar: calendar)
        if value < earliestPeriod { value = earliestPeriod }
        if value > latestPeriod { value = latestPeriod }
        return value
    }

    private static func startOfMonth(_ date: Date, calendar: Calendar) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date))
            ?? calendar.startOfDay(for: date)
    }

    /// 这个月已经手填过多少，用来预填输入框。
    ///
    /// 直接问手填那张表，不去快照里捞。以前是在快照里找「source == .manual 且
    /// 属于这个月」的那一条——那是从手填记录折出来的**副产物**，绕一圈回来找它，
    /// 等于让"哪条手填算数"这条规则多一个出处。
    private static func amountText(
        dashboard: DashboardModel,
        accountID: AccountID?,
        period: Date
    ) -> String {
        guard let accountID else { return "" }
        guard let amount = dashboard.manualUsageAmount(accountID: accountID, period: period) else {
            return ""
        }
        return NSDecimalNumber(decimal: amount.usd).stringValue
    }
}
