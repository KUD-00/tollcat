import Foundation
import Testing
import MeterCore
import MeterPersistence
import MeterProviders
@testable import MeterFeatures

@MainActor
struct ProviderSubscriptionTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()
    private var now: Date { calendar.date(from: DateComponents(year: 2026, month: 8, day: 17))! }

    // MARK: - 目录

    @Test("目录里的档位按 providerID 归属，产品目录里每一家都能对上")
    func catalogPlansBelongToKnownProviders() async throws {
        let catalog = try await BundledCatalogSource().load()
        #expect(!catalog.plans.isEmpty)
        let known = Set(ProviderCatalog.all.map(\.id))
        for plan in catalog.plans {
            guard let id = plan.providerID else { continue }
            #expect(known.contains(id), "\(plan.name) 挂在不存在的 \(id.rawValue) 上")
        }
    }

    @Test("常见的几家都有档位可选，不用每次自定义")
    func popularProvidersHaveTiers() async throws {
        let catalog = try await BundledCatalogSource().load()
        for id in [ProviderID.openai, .anthropic, .github, .cloudflare, .sentry, .clerk, .xai, .cursor, .gitlab, .grafana] {
            let tiers = catalog.plans.filter { $0.providerID == id }
            #expect(!tiers.isEmpty, "\(id.rawValue) 没有档位")
        }
    }

    @Test("Cursor 档位挂在这家，不带厂商名")
    func cursorPlansBelongToCursor() async throws {
        let catalog = try await BundledCatalogSource().load()
        let tiers = catalog.plans.filter { $0.providerID == .cursor }
        let byName = Dictionary(uniqueKeysWithValues: tiers.map { ($0.name, $0) })
        #expect(byName["Pro"]?.amount == Money(usd: 20))
        #expect(byName["Pro+"]?.amount == Money(usd: 60))
        #expect(byName["Ultra"]?.amount == Money(usd: 200))
        #expect(byName["Teams Standard（每席位）"]?.amount == Money(usd: 40))
        #expect(byName["Teams Premium（每席位）"]?.amount == Money(usd: 120))
        for plan in tiers {
            #expect(
                !plan.name.localizedCaseInsensitiveContains("Cursor"),
                "\(plan.name) 不该再带厂商名"
            )
        }
        #expect(!catalog.plans.contains { $0.name.localizedCaseInsensitiveContains("X Premium") })
    }

    @Test("xAI 的固定订阅是 SuperGrok，不是 X Premium")
    func xaiPlansAreSuperGrok() async throws {
        let catalog = try await BundledCatalogSource().load()
        let tiers = catalog.plans.filter { $0.providerID == .xai }
        let byName = Dictionary(uniqueKeysWithValues: tiers.map { ($0.name, $0) })
        #expect(try #require(tiers.first).name == "SuperGrok Lite")
        #expect(byName["SuperGrok"]?.amount == Money(usd: 30))
        #expect(byName["SuperGrok"]?.period == .monthly)
        #expect(byName["SuperGrok（年付）"]?.amount == Money(usd: 300))
        #expect(byName["SuperGrok（年付）"]?.period == .annual)
        #expect(byName["SuperGrok Plus"]?.amount == Money(usd: 100))
        #expect(byName["SuperGrok Heavy"]?.amount == Money(usd: 300))
        #expect(byName["Grok Business（每席位）"]?.amount == Money(usd: 30))
        for plan in tiers {
            #expect(!plan.name.localizedCaseInsensitiveContains("Premium"))
            #expect(!plan.name.localizedCaseInsensitiveContains("Cursor"))
        }
    }

    @Test("Cloudflare 预置的是固定月费，不是账单上那些 $0 Enabled 开关")
    func cloudflarePlansAreRecurringFees() async throws {
        let catalog = try await BundledCatalogSource().load()
        let tiers = catalog.plans.filter { $0.providerID == .cloudflare }
        let first = try #require(tiers.first)
        #expect(first.name == "Workers Paid")
        #expect(first.amount == Money(usd: 5))
        #expect(first.period == .monthly)

        let byName = Dictionary(uniqueKeysWithValues: tiers.map { ($0.name, $0) })
        #expect(byName["Workers for Platforms Paid"]?.amount == Money(usd: 25))
        #expect(byName["R2 Paid"]?.amount == Money.zero)
        #expect(byName["R2 Paid"]?.period == .monthly)
        #expect(byName["Pro（每个站点）"]?.amount == Money(usd: 25))
        #expect(byName["Pro（年付·每个站点）"]?.period == .annual)
        #expect(byName["Pro（年付·每个站点）"]?.amount == Money(usd: 240))
        #expect(byName["Business（每个站点）"]?.amount == Money(usd: 250))
        #expect(byName["Zero Trust（每席位）"]?.amount == Money(usd: 7))
        #expect(byName["Advanced Certificate Manager"]?.amount == Money(usd: 10))
        // 详情页已经写着 Cloudflare，档位名只留商品，不要再叠一层厂商名。
        for plan in tiers {
            #expect(
                !plan.name.localizedCaseInsensitiveContains("Cloudflare"),
                "\(plan.name) 不该再带厂商名"
            )
        }
        // R2 Paid 在控制台是 $0/月 + 用量，和 Workers Paid 同类订阅，不是账单里那些 Enabled 开关。
        let zeroAllowed: Set<String> = ["R2 Paid"]
        for plan in tiers where !zeroAllowed.contains(plan.name) {
            #expect(plan.amount > .zero, "\(plan.name) 不该是 $0 启用开关")
        }
        #expect(!byName.keys.contains { $0.localizedCaseInsensitiveContains("Vectorize") })
        #expect(!byName.keys.contains { $0.localizedCaseInsensitiveContains("Queues") })
        #expect(!byName.keys.contains { $0.localizedCaseInsensitiveContains("Zaraz") })
    }

    @Test("档位金额过十进制字符串，$0 的档位也留着（免费层也要能记零）")
    func planAmountsDecodeAsDecimals() async throws {
        let catalog = try await BundledCatalogSource().load()
        let plus = try #require(catalog.plans.first { $0.name == "ChatGPT Plus" })
        #expect(plus.amount == Money(usd: 20))
        #expect(plus.period == SubscriptionPeriod.monthly)
        let annual = catalog.plans.filter { $0.period == SubscriptionPeriod.annual }
        #expect(!annual.isEmpty, "年付档位没解出来，period 可能拼错了")
    }

    // MARK: - 份数

    @Test("amount 始终是扣款总额，不是单价——折算只看它")
    func amountIsAlwaysTheTotal() {
        let seats = MonthlySubscription(
            name: "GitHub Copilot Business",
            amount: Money(usd: 57),
            period: .monthly,
            anchorDate: now,
            providerID: .github,
            quantity: 3
        )
        #expect(seats.amount == Money(usd: 57))
        #expect(seats.unitAmount == Money(usd: 19))
    }

    @Test("份数至少是 1，0 和负数都夹到 1")
    func quantityIsClamped() {
        for raw in [0, -5] {
            let item = MonthlySubscription(
                name: "x", amount: Money(usd: 10), period: .monthly,
                anchorDate: now, quantity: raw
            )
            #expect(item.quantity == 1)
            #expect(item.unitAmount == item.amount)
        }
    }

    // MARK: - 选择器

    @Test("新建有预置商品时默认不选，自定义也不勾")
    func newEditorSelectsNoPlan() {
        let model = SubscriptionEditorModel(dashboard: .previewEmpty, providerID: .openai)
        model.plans = [
            SubscriptionPlan(
                name: "ChatGPT Plus", amount: Money(usd: 20),
                period: .monthly, providerID: .openai
            ),
            SubscriptionPlan(
                name: "ChatGPT Pro", amount: Money(usd: 200),
                period: .monthly, providerID: .openai
            ),
        ]
        #expect(model.planChoice == .none)
        #expect(!model.isCustom)
        #expect(!model.showsIdentityFields)
        #expect(!model.canSave)
        #expect(model.selectedPlan == nil)
    }

    @Test("选了档位就按 单价 × 份数 算合计")
    func totalIsUnitTimesQuantity() async {
        let model = SubscriptionEditorModel.preview(providerID: .openai)
        model.selectPlan("ChatGPT Plus")
        model.quantity = 3
        #expect(model.unitAmount == Money(usd: 20))
        #expect(model.total == Money(usd: 60))
        #expect(model.canSave)
    }

    @Test("自定义时名称或金额缺一个就不能存")
    func customNeedsBothFields() {
        let model = SubscriptionEditorModel.preview()
        model.selectPlan(nil)
        model.name = ""
        model.amountText = ""
        #expect(!model.canSave)
        model.name = "Cursor Pro"
        #expect(!model.canSave, "只有名称不该能存")
        model.amountText = "20"
        #expect(model.canSave)
        #expect(model.total == Money(usd: 20))
    }

    @Test("金额只认十进制，写字母不算数")
    func rejectsNonNumericAmount() {
        let model = SubscriptionEditorModel.preview()
        model.selectPlan(nil)
        model.name = "x"
        for bad in ["abc", "20元", "-5", ""] {
            model.amountText = bad
            #expect(model.total == nil, "\(bad) 不该解出金额")
        }
    }

    @Test("档位的周期跟着档位走，年付不会被当成月付")
    func periodFollowsThePlan() async {
        let model = SubscriptionEditorModel.preview()
        model.plans = [
            SubscriptionPlan(
                name: "JetBrains 全家桶", amount: Money(usd: 289),
                period: .annual, providerID: model.providerID
            ),
        ]
        model.selectPlan("JetBrains 全家桶")
        #expect(model.period == SubscriptionPeriod.annual)
    }

    @Test("自定义可以改成年付")
    func customCanBeAnnual() {
        let model = SubscriptionEditorModel.preview()
        model.selectPlan(nil)
        model.name = "Cursor Pro"
        model.amountText = "200"
        model.setPeriod(.annual)
        #expect(model.canSave)
        #expect(model.period == SubscriptionPeriod.annual)
        #expect(model.showsAnchorDate)
        #expect(model.usesYearMonthAnchor == false)
        #expect(model.anchorLabel == "首次扣款日")
    }

    @Test("档位列表按当前周期筛，年付不会出现在月付里")
    func visiblePlansFollowTheSelectedPeriod() {
        let model = SubscriptionEditorModel.preview()
        model.plans = [
            SubscriptionPlan(
                name: "ChatGPT Plus", amount: Money(usd: 20),
                period: .monthly, providerID: model.providerID
            ),
            SubscriptionPlan(
                name: "SuperGrok（年付）", amount: Money(usd: 300),
                period: .annual, providerID: model.providerID
            ),
        ]
        model.setPeriod(.monthly)
        #expect(model.visiblePlans.map(\.name) == ["ChatGPT Plus"])
        #expect(model.showsAnchorDate)
        #expect(model.usesYearMonthAnchor)
        #expect(model.anchorLabel == "开始时间")
        model.setPeriod(.annual)
        #expect(model.visiblePlans.map(\.name) == ["SuperGrok（年付）"])
        #expect(model.showsAnchorDate)
        #expect(model.usesYearMonthAnchor == false)
        #expect(model.anchorLabel == "首次扣款日")
    }

    @Test("月付问开始时间，保存只落到年月")
    func monthlyStartMonthSnapsToYearMonth() throws {
        let dashboard = DashboardModel.previewEmpty
        let model = SubscriptionEditorModel(dashboard: dashboard)
        model.name = "ChatGPT Plus"
        model.amountText = "20"
        #expect(model.usesYearMonthAnchor)
        #expect(model.anchorLabel == "开始时间")
        let calendar = model.clockCalendar
        model.anchorDate = calendar.date(
            from: DateComponents(year: 2025, month: 3, day: 20, hour: 15)
        )!
        try model.save()
        let item = try #require(dashboard.subscriptionItems().first)
        #expect(calendar.component(.year, from: item.anchorDate) == 2025)
        #expect(calendar.component(.month, from: item.anchorDate) == 3)
        #expect(calendar.component(.day, from: item.anchorDate) == 1)
        #expect(calendar.component(.hour, from: item.anchorDate) == 12)
    }

    @Test("改成月付时锚点只留年月")
    func switchingToMonthlySnapsToYearMonth() {
        let model = SubscriptionEditorModel.preview()
        model.setPeriod(.annual)
        let calendar = model.clockCalendar
        model.anchorDate = calendar.date(
            from: DateComponents(year: 2025, month: 3, day: 20, hour: 15)
        )!
        model.setPeriod(.monthly)
        #expect(model.usesYearMonthAnchor)
        #expect(calendar.component(.year, from: model.anchorDate) == 2025)
        #expect(calendar.component(.month, from: model.anchorDate) == 3)
        #expect(calendar.component(.day, from: model.anchorDate) == 1)
    }

    @Test("预置商品按名称排序，不跟目录原文顺序")
    func visiblePlansAreSortedByName() {
        let model = SubscriptionEditorModel.preview()
        model.plans = [
            SubscriptionPlan(
                name: "Workers Paid", amount: Money(usd: 5),
                period: .monthly, providerID: model.providerID
            ),
            SubscriptionPlan(
                name: "Argo Smart Routing", amount: Money(usd: 5),
                period: .monthly, providerID: model.providerID
            ),
            SubscriptionPlan(
                name: "R2 Paid", amount: Money.zero,
                period: .monthly, providerID: model.providerID
            ),
        ]
        model.setPeriod(.monthly)
        #expect(model.visiblePlans.map(\.name) == [
            "Argo Smart Routing",
            "R2 Paid",
            "Workers Paid",
        ])
    }

    @Test("改周期会离开对不上的档位，名称金额留在自定义")
    func changingPeriodLeavesTheMismatchedPlan() throws {
        let dashboard = DashboardModel.previewEmpty
        let model = SubscriptionEditorModel(dashboard: dashboard, providerID: .openai)
        model.plans = [
            SubscriptionPlan(
                name: "ChatGPT Plus", amount: Money(usd: 20),
                period: .monthly, providerID: .openai
            ),
        ]
        model.selectPlan("ChatGPT Plus")
        model.setPeriod(.annual)
        #expect(model.isCustom)
        #expect(model.name == "ChatGPT Plus")
        #expect(model.parsedAmount == Money(usd: 20))
        #expect(model.showsAnchorDate)
        try model.save()
        let item = try #require(dashboard.subscriptionItems().first)
        #expect(item.period == SubscriptionPeriod.annual)
        #expect(item.name == "ChatGPT Plus")
        #expect(item.amount == Money(usd: 20))
    }

    @Test("打开编辑页带上原有字段，标题是商品名")
    func editPrefillsExistingFields() throws {
        let dashboard = DashboardModel.previewEmpty
        try dashboard.applySubscription(
            MonthlySubscription(
                name: "ChatGPT Plus",
                amount: Money(usd: 20),
                period: .monthly,
                anchorDate: now,
                accountID: AccountID.fixture(for: .openai),
                providerID: .openai,
                quantity: 2
            )
        )
        let item = try #require(dashboard.subscriptionItems().first)
        let model = SubscriptionEditorModel(
            dashboard: dashboard,
            providerID: .openai,
            editing: item
        )
        #expect(model.isEditing)
        #expect(!model.showsTierPicker)
        #expect(model.showsIdentityFields)
        #expect(model.navigationTitle == "ChatGPT Plus")
        #expect(model.name == "ChatGPT Plus")
        #expect(model.unitAmount == Money(usd: 10))
        #expect(model.quantity == 2)
        #expect(model.period == .monthly)
        #expect(model.total == Money(usd: 20))
        #expect(model.accountID == AccountID.fixture(for: .openai))
    }

    @Test("编辑已有订阅是覆盖不是再插一条")
    func editOverwritesInsteadOfInserting() throws {
        let dashboard = DashboardModel.previewEmpty
        try dashboard.applySubscription(
            MonthlySubscription(
                name: "ChatGPT Plus",
                amount: Money(usd: 20),
                period: .monthly,
                anchorDate: now,
                providerID: .openai
            )
        )
        let item = try #require(dashboard.subscriptionItems().first)
        let model = SubscriptionEditorModel(
            dashboard: dashboard,
            providerID: .openai,
            editing: item
        )
        model.name = "ChatGPT Pro"
        model.amountText = "25"
        model.setPeriod(.annual)
        model.quantity = 2
        try model.save()

        let updated = dashboard.subscriptionItems()
        #expect(updated.count == 1)
        #expect(updated[0].id == item.id)
        #expect(updated[0].name == "ChatGPT Pro")
        #expect(updated[0].amount == Money(usd: 50))
        #expect(updated[0].quantity == 2)
        #expect(updated[0].period == SubscriptionPeriod.annual)
        #expect(updated[0].providerID == .openai)
    }

    @Test("编辑页删除会把这笔拿掉")
    func editDeleteRemovesTheSubscription() throws {
        let dashboard = DashboardModel.previewEmpty
        try dashboard.applySubscription(
            MonthlySubscription(
                name: "Claude Max",
                amount: Money(usd: 200),
                period: .monthly,
                anchorDate: now,
                providerID: .anthropic
            )
        )
        let item = try #require(dashboard.subscriptionItems().first)
        let model = SubscriptionEditorModel(
            dashboard: dashboard,
            providerID: .anthropic,
            editing: item
        )
        try model.delete()
        #expect(dashboard.subscriptionItems().isEmpty)
        #expect(dashboard.subscriptions.isEmpty)
    }

    // MARK: - 服务列表

    /// 真的把 monthToDate 算出来再喂进去。
    ///
    /// 上一版这里传 `monthToDate: nil`，于是走不到基于 fact 的那条路——
    /// 「行首那个数含不含订阅」这件事根本没被测到，我据此下的结论是错的。
    private func row(subscriptions: [MonthlySubscription]) -> ServiceRowItem? {
        let snapshot = Snapshot(
            providerID: .openai,
            accountID: AccountID.fixture(for: .openai),
            kind: .prepaid,
            fetchedAt: now,
            periodStart: calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!,
            periodEnd: calendar.date(from: DateComponents(year: 2026, month: 8, day: 31))!,
            balanceUSD: Money(usd: 30)
        )
        let monthToDate = MonthToDateCalculator.compute(
            snapshots: [snapshot],
            subscriptions: subscriptions,
            now: now,
            calendar: calendar
        )
        return ServiceRowBuilder.rows(
            memberships: [ProviderMembership(providerID: .openai, sortIndex: 0)],
            connections: [
                ProviderConnectionState(
                    accountID: AccountID.fixture(for: .openai),
                    providerID: .openai,
                    isEnabled: true,
                    sortIndex: 0,
                    lastSuccessfulRefreshAt: now,
                    credentialReference: "openai-ref",
                    includeInGlobalRefresh: true
                ),
            ],
            latest: AccountLatest.reduceAll(snapshots: [snapshot], calendar: calendar),
            monthToDate: monthToDate,
            marks: [AccountID.fixture(for: .openai): .current],
            subscriptions: subscriptions,
            now: now,
            calendar: calendar
        ).first { $0.id == .openai }
    }

    @Test("行首那个数含订阅，subtitle 就把它拆出来——同一笔钱不报两遍")
    func rowBreaksDownTheSubscriptionItAlreadyIncludes() throws {
        let plus = MonthlySubscription(
            name: "ChatGPT Plus", amount: Money(usd: 20),
            period: .monthly, anchorDate: now,
            accountID: AccountID.fixture(for: .openai), providerID: .openai
        )
        let withPlan = try #require(row(subscriptions: [plus]))
        let without = try #require(row(subscriptions: []))

        // 行首那个数字**变大了** —— `displayAmount` 会把 .subscriptionIncluded 加进去。
        #expect(withPlan.value != without.value)
        // 所以 subtitle 只能说「含订阅」，不能说「另有订阅」。
        #expect(withPlan.subtitle?.contains("含订阅") == true)
        #expect(withPlan.subtitle?.contains("另有") != true)
    }

    @Test("多笔订阅报的是合计，不是笔数")
    func multipleSubscriptionsReportTheirTotal() throws {
        let items = [
            MonthlySubscription(name: "a", amount: Money(usd: 20), period: .monthly, anchorDate: now, accountID: AccountID.fixture(for: .openai), providerID: .openai),
            MonthlySubscription(name: "b", amount: Money(usd: 25), period: .monthly, anchorDate: now, accountID: AccountID.fixture(for: .openai), providerID: .openai),
        ]
        let item = try #require(row(subscriptions: items))
        #expect(item.subtitle?.contains("45") == true)
    }

    @Test("别家的订阅不会串到这一行上")
    func otherProvidersSubscriptionsDoNotLeak() throws {
        let elsewhere = MonthlySubscription(
            name: "Claude Pro", amount: Money(usd: 20),
            period: .monthly, anchorDate: now,
            accountID: AccountID.fixture(for: .anthropic), providerID: .anthropic
        )
        let item = try #require(row(subscriptions: [elsewhere]))
        #expect(item.subtitle?.contains("含订阅") != true)
    }
}
