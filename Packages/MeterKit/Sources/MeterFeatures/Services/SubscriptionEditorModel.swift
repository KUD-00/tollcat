import Foundation
import Observation
import SwiftData
import MeterCore
import MeterFormat
import MeterPersistence
import MeterProviders

/// 订阅编辑的唯一 model：`providerID` 有值就是「挂在这家」（详情页入口，
/// 可从目录挑档位），nil 就是独立手动订阅（服务页入口，自己选归属）。
///
/// **档位和从量是两条独立的记录,不是一条 snapshot 的两个字段。**
/// 用量是 API 读回来的 `Snapshot`,档位是用户录的 `MonthlySubscription`。
/// 目录档位自带 `period`：抽屉先选月付/年付，再只列对得上的档位。
/// 月付问开始年月（不问几号）；年付问首次扣款日，用来落到哪一个月。
@MainActor
@Observable
final class SubscriptionEditorModel {
    /// 有值＝挂在这家；nil＝独立手动订阅。
    let providerID: ProviderID?
    /// 挂厂商模式下随入口带入；编辑时以已有那一笔为准。
    var accountID: AccountID?
    /// 只在独立手动订阅（`providerID == nil`）时有意义。
    var affiliation: SubscriptionAffiliation = .none

    /// 目录里属于这家的档位。独立手动订阅没有档位，只能自定义。
    /// 只有 `prepare()` 和测试会写它，所以 internal 而不是 private(set)。
    var plans: [SubscriptionPlan] = []
    /// 新建默认 `.none`：列表里不要预先勾「自定义」。
    var planChoice: PlanChoice = .none

    enum PlanChoice: Hashable {
        case none
        case catalog(String)
        case custom
    }

    var name = ""
    var amountText = ""
    /// 存下来才能在档位之外改月付 / 年付。选档位时用档位自带的周期盖掉。
    var period: SubscriptionPeriod = .monthly
    var anchorDate: Date
    var quantity = 1
    var saveToken = 0

    var dashboard: DashboardModel
    private let catalogSource: any CatalogSource
    /// `prepare()` 跑完才知道这家有没有预置商品。没跑完先别画出名称/单价，避免闪一帧自定义。
    private(set) var hasPrepared = false
    /// 有值就是改已有的那一笔，保存时覆盖而不是再插一条。
    private(set) var existingID: PersistentIdentifier?
    /// 退订那个月。nil = 还在付。
    ///
    /// 这是一个**字段**，不是一个动作。订阅是一段区间「开始 → 结束」：
    /// 1–3 月用了 Pro、5 月又订回来，那是两段，要新加一笔——
    /// 不能把第一笔「恢复」，那会把没付钱的 4 月一起补上。
    /// 所以这里只有「填一个结束月 / 清掉它」，没有恢复。
    var endDate: Date?
    private let originalName: String

    init(
        dashboard: DashboardModel,
        providerID: ProviderID? = nil,
        accountID: AccountID? = nil,
        catalogSource: (any CatalogSource)? = nil,
        editing: ManualSubscriptionItem? = nil
    ) {
        self.dashboard = dashboard
        self.providerID = providerID
        self.catalogSource = catalogSource ?? dashboard.catalogResolver
        if let editing {
            existingID = editing.id
            endDate = editing.endDate
            originalName = editing.name
            name = editing.name
            amountText = NSDecimalNumber(decimal: editing.unitAmount.usd).stringValue
            period = editing.period
            anchorDate = editing.anchorDate
            quantity = editing.quantity
            planChoice = .custom
            if providerID != nil {
                self.accountID = editing.accountID
            } else if let accountID = editing.accountID {
                affiliation = .account(accountID)
            } else if let vendor = editing.providerID {
                affiliation = .vendor(vendor)
            }
        } else {
            originalName = ""
            self.accountID = accountID
            self.anchorDate = dashboard.clock.now
        }
        if period == .monthly {
            self.anchorDate = Self.yearMonthAnchor(
                self.anchorDate,
                calendar: dashboard.clock.calendar
            )
        }
    }

    var isEditing: Bool { existingID != nil }

    var isCustom: Bool {
        switch planChoice {
        case .custom: true
        case .none, .catalog: false
        }
    }

    /// 当前周期下的预置档位。月付/年付是目录字段，混在一列里选会改掉刚选的周期。
    /// 按名称排，不跟目录原文顺序——Cloudflare 那一长串否则看起来像没排过。
    var visiblePlans: [SubscriptionPlan] {
        plans
            .filter { $0.period == period }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// 新建且这一档周期有预置档位才出示。编辑已经是某一笔商品，不再从目录挑。
    var showsTierPicker: Bool { providerID != nil && !isEditing && !visiblePlans.isEmpty }

    var showsIdentityFields: Bool {
        if isEditing || isCustom || providerID == nil { return true }
        return hasPrepared && !showsTierPicker
    }

    /// 两种周期都要落到哪个月：月付选年月，年付选首次扣款日。
    var showsAnchorDate: Bool { true }

    /// 月付只要年月；年付要完整日期。
    var usesYearMonthAnchor: Bool { period == .monthly }

    /// 独立手动订阅才需要自己选归属；挂厂商模式的归属就是入口那家。
    var showsAffiliationPicker: Bool { providerID == nil }

    var selectedPlan: SubscriptionPlan? {
        guard case .catalog(let name) = planChoice else { return nil }
        return plans.first { $0.name == name }
    }

    var clockCalendar: Calendar { dashboard.clock.calendar }

    var navigationTitle: String {
        if isEditing {
            let name = resolvedName
            return name.isEmpty ? originalName : name
        }
        return providerID == nil
            ? String(localized: L("手动订阅"))
            : String(localized: L("加一笔固定订阅"))
    }

    var anchorLabel: String {
        switch period {
        case .monthly:
            String(localized: L("开始时间"))
        case .annual:
            String(localized: L("首次扣款日"))
        }
    }

    /// 改周期会离开对不上的预置档位，名称和金额留在自定义里。
    func setPeriod(_ new: SubscriptionPeriod) {
        guard new != period else { return }
        period = new
        if new == .monthly {
            snapAnchorToYearMonth()
        }
        if let plan = selectedPlan, plan.period != new {
            selectPlan(nil)
        }
    }

    func setAnchorDate(_ date: Date) {
        let clamped = anchorUpperBound.map { min(date, $0) } ?? date
        if period == .monthly {
            anchorDate = Self.yearMonthAnchor(clamped, calendar: clockCalendar)
        } else {
            anchorDate = clamped
        }
        // 开始往后挪之后，结束月不能还留在开始之前。
        if let endDate, endDate < endLowerBound {
            self.endDate = endLowerBound
        }
    }

    /// 自定义单价。档位价是 $0 也合法（免费层要能记零），手填 0 不算数。
    var parsedAmount: Money? {
        Self.parseAmount(amountText).flatMap { amount in
            amount > .zero ? amount : nil
        }
    }

    var unitAmount: Money? {
        if let selectedPlan { return selectedPlan.amount }
        return parsedAmount
    }

    /// 单价 × 份数。落库的 `amount` 始终是总额。
    var total: Money? {
        guard let unit = unitAmount else { return nil }
        return Money(usd: unit.usd * Decimal(quantity))
    }

    var resolvedName: String {
        if let selectedPlan { return selectedPlan.name }
        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSave: Bool {
        if showsTierPicker, case .none = planChoice { return false }
        if let endDate, endDate < endLowerBound { return false }
        return !resolvedName.isEmpty && total != nil && quantity >= 1
    }

    func selectPlan(_ planName: String?) {
        if let planName {
            planChoice = .catalog(planName)
            if let plan = selectedPlan {
                setPeriod(plan.period)
            }
            return
        }
        if let plan = selectedPlan {
            if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                name = plan.name
            }
            if amountText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                amountText = NSDecimalNumber(decimal: plan.amount.usd).stringValue
            }
        }
        planChoice = .custom
    }

    func prepare() async {
        defer { hasPrepared = true }
        guard let providerID, !isEditing else { return }
        // 档位名要按当前语言选列。少这一步，英文/日文界面里会冒出「（每席位）」这种规范中文。
        let catalog = (try? await catalogSource.load())?
            .localized(for: CatalogDisplay.language)
        plans = (catalog?.plans ?? []).filter { $0.providerID == providerID }
        if case .none = planChoice {
            let periods = Set(plans.map(\.period))
            if periods.count == 1, let only = periods.first {
                setPeriod(only)
            }
        }
    }

    func save() throws {
        guard canSave, let total else { return }
        let subscription = MonthlySubscription(
            name: resolvedName,
            amount: total,
            period: period,
            anchorDate: persistedAnchorDate,
            endDate: endDate,
            accountID: resolvedAccountID,
            providerID: resolvedProviderID,
            quantity: quantity
        )
        if let existingID {
            try dashboard.updateSubscription(id: existingID, subscription)
        } else {
            try dashboard.applySubscription(subscription)
        }
        saveToken += 1
    }

    // MARK: - 结束时间

    var hasEnd: Bool { endDate != nil }

    /// 打开 / 关掉「已经退订」。打开时默认停在本月，但**不早于开始月**——
    /// 一段负长度的订阅没有意义。
    func setHasEnd(_ on: Bool) {
        guard on else {
            endDate = nil
            return
        }
        guard endDate == nil else { return }
        let thisMonth = Self.yearMonthAnchor(dashboard.clock.now, calendar: clockCalendar)
        endDate = max(thisMonth, endLowerBound)
    }

    func setEndDate(_ date: Date) {
        endDate = max(Self.yearMonthAnchor(date, calendar: clockCalendar), endLowerBound)
    }

    /// 结束月不能早于开始月。
    var endLowerBound: Date {
        Self.yearMonthAnchor(anchorDate, calendar: clockCalendar)
    }

    /// **结束可以填在未来**：这个月取消、服务用到 11 月底，是常事。
    /// 那种仍然算进本月，只是从 12 月起归零。所以上界给得宽一点。
    var endUpperBound: Date? {
        clockCalendar.date(byAdding: .year, value: 2, to: dashboard.clock.now)
    }

    /// 开始时间**不能选未来的月份**。一笔从明年三月开始的订阅在账本上是纯 0，
    /// 只会让人以为记错了。当月内的未来日期是可以的——年付的首次扣款日常常
    /// 就在这个月的后几天。
    var anchorUpperBound: Date? {
        guard
            let monthStart = clockCalendar.date(
                from: clockCalendar.dateComponents([.year, .month], from: dashboard.clock.now)
            ),
            let nextMonth = clockCalendar.date(byAdding: .month, value: 1, to: monthStart)
        else {
            return nil
        }
        return nextMonth.addingTimeInterval(-1)
    }

    /// 已经结束了（相对此刻）。填在未来的结束月不算——那种还在付。
    var hasEndedByNow: Bool {
        guard let endDate else { return false }
        return MonthlySubscription(
            name: resolvedName,
            amount: total ?? .zero,
            period: period,
            anchorDate: anchorDate,
            endDate: endDate
        ).hasEnded(by: dashboard.clock.now, calendar: clockCalendar)
    }

    /// 结束那一栏底下那句话。已经结束写「最后计入 X」，还没到写「到 X 为止」。
    var endFooter: String {
        guard let endDate else {
            return String(localized: L("不订了就填一个结束月：那个月照常计入，下个月起不再算。"))
        }
        let month = MeterDateFormat.yearMonth(endDate, calendar: clockCalendar)
        return hasEndedByNow
            ? String(localized: L("最后计入 \(month)。过去付过的月份照旧算数。"))
            : String(localized: L("算到 \(month) 为止，之后不再计入。"))
    }

    /// 真删。**会改写历史**：这笔钱从过去每一个月里一起消失。
    /// 只给「我根本录错了」用，不是「我不订了」——后者填结束月。
    func delete() throws {
        guard let existingID else { return }
        try dashboard.removeSubscription(id: existingID)
        saveToken += 1
    }

    /// `Decimal(string:)` 只解前缀——"20元" 会静悄悄变成 20。先自己卡字符集，
    /// 否则用户打错字会得到一个看着像对的金额。
    static func parseAmount(_ raw: String) -> Money? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              trimmed.allSatisfy({ $0.isASCII && ($0.isNumber || $0 == ".") }),
              trimmed.filter({ $0 == "." }).count <= 1,
              let value = Decimal(string: trimmed, locale: Locale(identifier: "en_US_POSIX")),
              value >= 0 else {
            return nil
        }
        return Money(usd: value)
    }

    private var resolvedAccountID: AccountID? {
        if providerID != nil { return accountID }
        if case .account(let id) = affiliation { return id }
        return nil
    }

    private var resolvedProviderID: ProviderID? {
        if let providerID { return providerID }
        switch affiliation {
        case .none:
            return nil
        case .vendor(let id):
            return id
        case .account(let accountID):
            return dashboard.connectionStates().first { $0.accountID == accountID }?.providerID
        }
    }

    var connectedAffiliationOptions: [ProviderConnectionState] {
        dashboard.connectionStates()
            .filter(\.isLive)
            .sorted { $0.sortIndex < $1.sortIndex }
    }

    /// 月付落库只留年月。日钉在 1 号中午，和 `SubscriptionRecord` 避开午夜边界同一套。
    private var persistedAnchorDate: Date {
        period == .monthly
            ? Self.yearMonthAnchor(anchorDate, calendar: clockCalendar)
            : anchorDate
    }

    private func snapAnchorToYearMonth() {
        anchorDate = Self.yearMonthAnchor(anchorDate, calendar: clockCalendar)
    }

    private static func yearMonthAnchor(_ date: Date, calendar: Calendar) -> Date {
        var components = calendar.dateComponents([.year, .month], from: date)
        components.day = 1
        components.hour = 12
        return calendar.date(from: components) ?? date
    }

    // MARK: - Preview 工厂

    static func manualPreview() -> SubscriptionEditorModel {
        SubscriptionEditorModel(dashboard: .preview)
    }

    static func manualPreviewEditing() -> SubscriptionEditorModel {
        let dashboard = DashboardModel.preview
        let item = dashboard.subscriptionItems().first
        return SubscriptionEditorModel(dashboard: dashboard, editing: item)
    }

    static func preview(providerID: ProviderID = .openai) -> SubscriptionEditorModel {
        let dashboard = DashboardModel.preview
        let accountID = dashboard.connectionStates()
            .first { $0.providerID == providerID }?.accountID
            ?? AccountID.fixture(for: providerID)
        let model = SubscriptionEditorModel(
            dashboard: dashboard,
            providerID: providerID,
            accountID: accountID
        )
        model.plans = [
            SubscriptionPlan(name: "ChatGPT Plus", amount: Money(usd: 20), period: .monthly, providerID: providerID),
            SubscriptionPlan(name: "ChatGPT Pro 20×", amount: Money(usd: 200), period: .monthly, providerID: providerID),
        ]
        return model
    }

    static func previewEditing(providerID: ProviderID = .openai) -> SubscriptionEditorModel {
        let dashboard = DashboardModel.preview
        let item = dashboard.subscriptionItems().first { $0.providerID == providerID }
            ?? dashboard.subscriptionItems().first
        return SubscriptionEditorModel(
            dashboard: dashboard,
            providerID: item?.providerID ?? providerID,
            accountID: item?.accountID,
            editing: item
        )
    }
}
