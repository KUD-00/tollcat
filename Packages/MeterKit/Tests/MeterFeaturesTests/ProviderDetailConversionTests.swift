import Foundation
import SwiftData
import Testing
import MeterCore
import MeterPersistence
import MeterProviders
@testable import MeterFeatures

@MainActor
struct ProviderDetailConversionTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    @Test("单币种换算：大数字下面是短汇率，右边跟显示货币走")
    func captionSitsOnHeroAndFollowsDisplayCurrency() async throws {
        let dashboard = try makeDashboard()
        try await seedMoonshotCNY(on: dashboard)

        let usd = ProviderDetailModel(providerID: .moonshot, dashboard: dashboard)
        #expect(usd.conversionNote != nil)
        #expect(usd.walletBreakdown.isEmpty)
        #expect(usd.conversionRateCaptions == [
            String(localized: L("（1 CNY = $0.1404）"))
        ])

        dashboard.setDisplayCurrency("JPY")
        let yen = ProviderDetailModel(providerID: .moonshot, dashboard: dashboard)
        #expect(yen.conversionRateCaptions == [
            String(localized: L("（1 CNY = ¥21）"))
        ])
        #expect(!yen.conversionRateCaptions[0].contains("$"))

        dashboard.setDisplayCurrency("CNY")
        let yuan = ProviderDetailModel(providerID: .moonshot, dashboard: dashboard)
        #expect(yuan.conversionRateCaptions.isEmpty)
    }

    @Test("多钱包只给换过币的槽出汇率，空美元槽不出")
    func walletsOnlyCaptionConvertedSlots() throws {
        let dashboard = try makeDashboard()
        let accountID = AccountID.fixture(for: .deepseek)
        let cny = ConvertedAmount(
            currency: "CNY",
            amount: Decimal(string: "14.17")!,
            usdPerUnit: Decimal(string: "0.1404")!,
            usd: Decimal(string: "1.99")!
        )
        try dashboard.applyConnection(
            accountID: accountID,
            providerID: .deepseek,
            nickname: nil,
            identityHint: nil,
            remoteIdentityFingerprint: "test-deepseek-wallets",
            fields: [CredentialField.apiKey.rawValue: "sk-test"],
            snapshots: [
                Snapshot(
                    providerID: .deepseek,
                    accountID: accountID,
                    kind: .prepaid,
                    fetchedAt: date(2026, 8, 16, 12),
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    balanceUSD: Money(usd: Decimal(string: "1.99")!),
                    converted: cny,
                    wallets: [
                        cny,
                        ConvertedAmount(currency: "USD", amount: 0, usdPerUnit: 1, usd: 0),
                    ]
                )
            ],
            mode: .create
        )

        let model = ProviderDetailModel(providerID: .deepseek, dashboard: dashboard)
        #expect(model.conversionNote == nil)
        #expect(model.walletBreakdown.count == 2)
        #expect(model.conversionRateCaptions == [
            String(localized: L("（1 CNY = $0.1404）"))
        ])
    }

    /// `row` / `history` 这些派生值缓存在 model 里，钥匙是 `presentationToken`。
    /// 缓存的风险不是算错而是**吐旧数字**：换显示货币不写库、写库不换实例，
    /// 两条失效路径都必须让同一个 model 实例给出新结果。
    @Test("派生缓存随货币切换与写库失效，同一个实例不吐旧数字")
    func derivedCachesInvalidateOnPresentationChanges() async throws {
        let dashboard = try makeDashboard()
        try await seedMoonshotCNY(on: dashboard)
        let model = ProviderDetailModel(providerID: .moonshot, dashboard: dashboard)

        let usdAmount = model.amountText
        #expect(usdAmount == model.amountText, "连续两次读必须一致，第二次走缓存")
        #expect(model.history.count == 1)

        dashboard.setDisplayCurrency("JPY")
        #expect(model.amountText != usdAmount, "换显示货币没写库，缓存也必须失效")

        let accountID = AccountID.fixture(for: .moonshot)
        try dashboard.applyConnection(
            accountID: accountID,
            providerID: .moonshot,
            nickname: nil,
            identityHint: nil,
            remoteIdentityFingerprint: "test-moonshot-cny",
            fields: [CredentialField.apiKey.rawValue: "sk-test"],
            snapshots: [
                Snapshot(
                    providerID: .moonshot,
                    accountID: accountID,
                    kind: .prepaid,
                    fetchedAt: date(2026, 8, 17, 12),
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    balanceUSD: Money(usd: 5)
                )
            ],
            mode: .rotate
        )
        #expect(model.history.count == 2, "写库之后同一个实例必须看到新快照")
    }

    @Test("详情页汇率在大数字下面，不再写按原币换算")
    func viewPutsCaptionUnderHero() throws {
        let detail = try GuardrailSourceScan.sourceText(named: "ProviderDetailView.swift")
        #expect(detail.contains("conversionRateCaptions"))
        #expect(detail.contains("amountBlock"))
        #expect(!detail.contains("originalAmountText"))
        #expect(!detail.contains("换算"))
    }

    @Test("免费额度详情页主角是用了百分之多少")
    func freeTierHeroShowsPercent() async throws {
        let dashboard = try makeDashboard()
        try await seedSentry(on: dashboard, ratio: 0.62)
        let model = ProviderDetailModel(providerID: .sentry, dashboard: dashboard)
        #expect(model.showsFreeQuotaHero)
        #expect(model.freeQuotaPercentText == "62%")
        #expect(model.amountText == String(localized: L("免费额度")))
        #expect(model.spokenAmount == String(localized: L("免费额度，用了百分之 \(62)")))
        #expect(!model.showsHistoryRangePicker)
    }

    @Test("三个范围都画不出点时不出现 7/30/12 切换")
    func hidesRangePickerWhenNoRangeHasPlot() async throws {
        let dashboard = try makeDashboard()
        try await seedSentry(on: dashboard, ratio: 0.1)
        let model = ProviderDetailModel(providerID: .sentry, dashboard: dashboard)
        #expect(!model.showsHistoryRangePicker)
        #expect(!model.chartContent.hasPlot)
    }

    @Test("至少有一个范围能画出点时保留范围切换")
    func keepsRangePickerWhenARangeHasPlot() throws {
        let dashboard = try makeDashboard()
        let accountID = AccountID.fixture(for: .cloudflare)
        try dashboard.applyConnection(
            accountID: accountID,
            providerID: .cloudflare,
            nickname: nil,
            identityHint: nil,
            remoteIdentityFingerprint: "test-cloudflare-daily",
            fields: [
                CredentialField.apiToken.rawValue: "demo-token-cloudflare",
                CredentialField.accountID.rawValue: "demo-account",
            ],
            snapshots: [
                Snapshot(
                    providerID: .cloudflare,
                    accountID: accountID,
                    kind: .usage,
                    fetchedAt: date(2026, 8, 16, 12),
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    currentSpendUSD: Money(roundedUSD: 11.05),
                    dailyUSD: [date(2026, 8, 10): Money(roundedUSD: 2.2)]
                )
            ],
            mode: .create
        )
        let model = ProviderDetailModel(providerID: .cloudflare, dashboard: dashboard)
        #expect(model.showsHistoryRangePicker)
        #expect(model.chartContent.hasPlot)
    }

    @Test("详情页范围切换绑在有图可画上")
    func viewHidesEmptyRangePicker() throws {
        let detail = try GuardrailSourceScan.sourceText(named: "ProviderDetailView.swift")
        #expect(detail.contains("showsHistoryRangePicker"))
        #expect(detail.contains("showsFreeQuotaHero"))
        #expect(detail.contains("freeQuotaPercentText"))
    }

    /// 详情页的大数字是这家的账单事实：本月、全部账号、**永远含订阅**，
    /// 不跟首屏那颗「含订阅 / 仅从量」。默认口径就是「仅从量」，
    /// 所以这条同时也在测「默认打开详情页看到的是两样钱的合计」。
    @Test("大数字含订阅，下面摊开的两半加起来正好是它")
    func heroSumsUsageAndSubscription() async throws {
        let dashboard = try makeDashboard()
        try await seedCloudflareUsage(on: dashboard)
        try await seedWorkersPaid(on: dashboard)

        let model = ProviderDetailModel(providerID: .cloudflare, dashboard: dashboard)
        #expect(!dashboard.filter.includesSubscriptions, "产品默认是仅从量")
        #expect(model.amountText == "$16.05")
        #expect(
            model.amountCompositionCaption
                == String(localized: L("（按量 $11.05 + 订阅 $5.00）"))
        )

        // 换显示货币要跟着换，缓存不能吐旧数字。
        dashboard.setDisplayCurrency("JPY")
        let yen = model.amountCompositionCaption
        #expect(yen != nil)
        #expect(yen?.contains("$") == false)
    }

    /// 仪表盘的取景框改一下就让详情页的钱变一个数，是这一页最容易犯的错。
    @Test("仪表盘的口径和月份都动不了详情页的大数字")
    func heroIgnoresDashboardFilter() async throws {
        let dashboard = try makeDashboard()
        try await seedCloudflareUsage(on: dashboard)
        try await seedWorkersPaid(on: dashboard)
        let model = ProviderDetailModel(providerID: .cloudflare, dashboard: dashboard)
        let caption = String(localized: L("（按量 $11.05 + 订阅 $5.00）"))

        dashboard.setIncludesSubscriptions(true)
        #expect(model.amountText == "$16.05")
        #expect(model.amountCompositionCaption == caption)

        dashboard.setIncludesSubscriptions(false)
        #expect(model.amountText == "$16.05")
        #expect(model.amountCompositionCaption == caption)

        // 回看上个月是首屏的取景：详情页说「本月」，就得还是本月。
        // 顺带把这家排掉——从仪表盘排掉不等于这家不用付钱。
        dashboard.setFilter(
            DashboardFilter(
                monthsBack: 1,
                includesSubscriptions: false,
                excludedAccounts: [AccountID.fixture(for: .cloudflare)]
            )
        )
        #expect(model.amountText == "$16.05")
        #expect(model.amountCompositionCaption == caption)
    }

    /// 列表行和详情页是同一个 tab 的两页，钱必须是同一个数——
    /// 列表 $11.05、点进去 $16.05 是最刺眼的那种不一致。
    @Test("服务列表和详情页同一个数，也一样不跟仪表盘")
    func servicesListMatchesDetailHero() async throws {
        let dashboard = try makeDashboard()
        try await seedCloudflareUsage(on: dashboard)
        try await seedWorkersPaid(on: dashboard)
        dashboard.setFilter(
            DashboardFilter(
                monthsBack: 1,
                includesSubscriptions: false,
                excludedAccounts: [AccountID.fixture(for: .cloudflare)]
            )
        )

        let services = ServicesModel(dashboard: dashboard)
        let row = services.rows.first { $0.id == .cloudflare }
        let detail = ProviderDetailModel(providerID: .cloudflare, dashboard: dashboard)
        #expect(row?.value == "$16.05")
        #expect(row?.value == detail.amountText)
        // 行首那个数含订阅，副标题就把它拆出来（`ServiceRowBuilder.subscriptionBreakdown`）。
        #expect(row?.subtitle?.contains(String(localized: L("含订阅 $5.00"))) == true)
    }

    /// GitHub 这种「月费来自 API」的家，副标题已经写了「含月费 $4.00」，
    /// 拆解那句不能把同一笔钱换个词再说一遍。
    @Test("API 报回来的月费只说一遍，不再叠一句含订阅")
    func reportedMonthlyFeeIsNotStatedTwice() async throws {
        let dashboard = try makeDashboard()
        let accountID = AccountID.fixture(for: .github)
        try dashboard.applyConnection(
            accountID: accountID,
            providerID: .github,
            nickname: nil,
            identityHint: nil,
            remoteIdentityFingerprint: "test-github-plan",
            fields: [CredentialField.apiToken.rawValue: "ghp_test"],
            snapshots: [
                Snapshot(
                    providerID: .github,
                    accountID: accountID,
                    kind: .planAndUsage,
                    fetchedAt: date(2026, 8, 16, 12),
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    currentSpendUSD: Money(usd: 1),
                    committedMonthlyUSD: Money(usd: 4)
                )
            ],
            mode: .create
        )
        await dashboard.syncLedger()

        let row = try #require(ServicesModel(dashboard: dashboard).rows.first { $0.id == .github })
        #expect(row.value == "$5.00", "行首是月费 + 超额")
        #expect(row.subtitle == String(localized: L("含月费 $4.00")))
        #expect(row.subtitle?.contains(String(localized: L("含订阅"))) == false)

        // 再手动录一笔挂到同一份账号上：API 那笔让位，拆解说的是手动录的这笔。
        try dashboard.applySubscription(
            MonthlySubscription(
                name: "Copilot",
                amount: Money(usd: 10),
                period: .monthly,
                anchorDate: date(2026, 7, 1),
                accountID: accountID,
                providerID: .github
            )
        )
        await dashboard.syncLedger()
        let manual = try #require(ServicesModel(dashboard: dashboard).rows.first { $0.id == .github })
        #expect(manual.subtitle?.contains(String(localized: L("含订阅 $10.00"))) == true)
    }

    @Test("只有按量、或只有订阅时不摊开——那一块就是大数字本身")
    func heroSkipsSplitWhenOnlyOneSide() async throws {
        let usageOnly = try makeDashboard()
        try await seedCloudflareUsage(on: usageOnly)
        #expect(
            ProviderDetailModel(providerID: .cloudflare, dashboard: usageOnly)
                .amountCompositionCaption == nil
        )

        let subscriptionOnly = try makeDashboard()
        try subscriptionOnly.addMembership(.github)
        try subscriptionOnly.applySubscription(
            MonthlySubscription(
                name: "Copilot",
                amount: Money(usd: 10),
                period: .monthly,
                anchorDate: date(2026, 7, 1),
                providerID: .github
            )
        )
        #expect(
            ProviderDetailModel(providerID: .github, dashboard: subscriptionOnly)
                .amountCompositionCaption == nil
        )
    }

    @Test("详情页把拆解摆在大数字下面，也读给旁白")
    func viewPutsSplitUnderHero() throws {
        let detail = try GuardrailSourceScan.sourceText(named: "ProviderDetailView.swift")
        #expect(detail.contains("amountCompositionCaption"))
    }

    /// 门上那个口带范围：详情页最长就是 12 个月（再往前留一个月给预充值的月初锚点）。
    ///
    /// 第二轮审视第 9 条：以前 `accountReadings` 不传 `since`，于是每次
    /// `presentationToken` 变都要把这家**全部**历史解一遍三个 blob——代价正比于
    /// 这个账号刷过多少回，而屏幕上最多只画得下 12 个月。
    @Test("13 个月前的读数不进详情页的历史和图")
    func readingsOlderThanTheWindowNeverReachTheDetailPage() async throws {
        let dashboard = try makeDashboard()
        let accountID = AccountID.fixture(for: .cloudflare)
        let ancient = date(2024, 1, 5, 12)
        try dashboard.applyConnection(
            accountID: accountID,
            providerID: .cloudflare,
            nickname: nil,
            identityHint: nil,
            remoteIdentityFingerprint: "test-cf-window",
            fields: [CredentialField.apiToken.rawValue: "tok"],
            snapshots: [
                Snapshot(
                    providerID: .cloudflare,
                    accountID: accountID,
                    kind: .usage,
                    fetchedAt: ancient,
                    periodStart: date(2024, 1, 1),
                    periodEnd: date(2024, 1, 31),
                    currentSpendUSD: Money(usd: 999),
                    dailyUSD: [calendar.startOfDay(for: ancient): Money(usd: 999)]
                ),
                Snapshot(
                    providerID: .cloudflare,
                    accountID: accountID,
                    kind: .usage,
                    fetchedAt: date(2026, 8, 16, 12),
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    currentSpendUSD: Money(roundedUSD: 11.05),
                    dailyUSD: [calendar.startOfDay(for: date(2026, 8, 16)): Money(roundedUSD: 11.05)]
                ),
            ],
            mode: .create
        )
        await dashboard.syncLedger()

        let model = ProviderDetailModel(providerID: .cloudflare, dashboard: dashboard)
        // 2024 年 1 月那笔 $999 在任何一个范围里都不该出现。
        for range in ProviderHistoryRange.allCases {
            model.setHistoryRange(range)
            #expect(
                !model.history.contains { $0.amountCaption.contains("999") },
                "\(range) 里出现了窗口外的读数"
            )
        }
        // 而库里那一条**还在**——压缩是另一件事，门只是没把它端上来。
        #expect(dashboard.debugAllReadings().contains { $0.currentSpendUSD == Money(usd: 999) })
    }

    private func seedWorkersPaid(on dashboard: DashboardModel) async throws {
        try dashboard.applySubscription(
            MonthlySubscription(
                name: "Workers Paid",
                amount: Money(usd: 5),
                period: .monthly,
                anchorDate: date(2026, 7, 1),
                accountID: AccountID.fixture(for: .cloudflare),
                providerID: .cloudflare
            )
        )
        // 写完库之后那一趟折叠是后台排的（`loadFromPersistence` 结尾那个 Task）。
        // 同步调用链一返回它还没跑——测试里显式等一趟，**不是**为了测试留同步路径。
        await dashboard.syncLedger()
    }

    private func seedCloudflareUsage(on dashboard: DashboardModel) async throws {
        let accountID = AccountID.fixture(for: .cloudflare)
        try dashboard.applyConnection(
            accountID: accountID,
            providerID: .cloudflare,
            nickname: nil,
            identityHint: nil,
            remoteIdentityFingerprint: "test-cloudflare-usage",
            fields: [
                CredentialField.apiToken.rawValue: "demo-token-cloudflare",
                CredentialField.accountID.rawValue: "demo-account",
            ],
            snapshots: [
                Snapshot(
                    providerID: .cloudflare,
                    accountID: accountID,
                    kind: .usage,
                    fetchedAt: date(2026, 8, 16, 12),
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    currentSpendUSD: Money(roundedUSD: 11.05)
                )
            ],
            mode: .create
        )
        // 写完库之后那一趟折叠是后台排的（`loadFromPersistence` 结尾那个 Task）。
        // 同步调用链一返回它还没跑——测试里显式等一趟，**不是**为了测试留同步路径。
        await dashboard.syncLedger()
    }

    private func seedSentry(on dashboard: DashboardModel, ratio: Double) async throws {
        let accountID = AccountID.fixture(for: .sentry)
        try dashboard.applyConnection(
            accountID: accountID,
            providerID: .sentry,
            nickname: nil,
            identityHint: nil,
            remoteIdentityFingerprint: "test-sentry-quota",
            fields: [
                CredentialField.apiToken.rawValue: "sntrys_test_token",
                CredentialField.accountID.rawValue: "demo-org",
            ],
            snapshots: [
                Snapshot(
                    providerID: .sentry,
                    accountID: accountID,
                    kind: .freeTier,
                    fetchedAt: date(2026, 8, 16, 12),
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    currentSpendUSD: .zero,
                    freeQuotaUsedRatio: ratio
                )
            ],
            mode: .create
        )
        // 写完库之后那一趟折叠是后台排的（`loadFromPersistence` 结尾那个 Task）。
        // 同步调用链一返回它还没跑——测试里显式等一趟，**不是**为了测试留同步路径。
        await dashboard.syncLedger()
    }

    private func seedMoonshotCNY(on dashboard: DashboardModel) async throws {
        let accountID = AccountID.fixture(for: .moonshot)
        let converted = ConvertedAmount(
            currency: "CNY",
            amount: 15,
            usdPerUnit: Decimal(string: "0.1404")!,
            usd: Decimal(string: "2.11")!
        )
        try dashboard.applyConnection(
            accountID: accountID,
            providerID: .moonshot,
            nickname: nil,
            identityHint: nil,
            remoteIdentityFingerprint: "test-moonshot-cny",
            fields: [CredentialField.apiKey.rawValue: "sk-test"],
            snapshots: [
                Snapshot(
                    providerID: .moonshot,
                    accountID: accountID,
                    kind: .prepaid,
                    fetchedAt: date(2026, 8, 16, 12),
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    balanceUSD: Money(usd: Decimal(string: "2.11")!),
                    converted: converted
                )
            ],
            mode: .create
        )
        // 写完库之后那一趟折叠是后台排的（`loadFromPersistence` 结尾那个 Task）。
        // 同步调用链一返回它还没跑——测试里显式等一趟，**不是**为了测试留同步路径。
        await dashboard.syncLedger()
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private func makeDashboard() throws -> DashboardModel {
        DashboardModel(
            providers: [:],
            container: try PersistenceContainer.makeContainer(inMemory: true),
            credentials: InMemoryCredentialStore(),
            clock: MeterClock(now: date(2026, 8, 16, 12), calendar: calendar),
            httpClient: StubHTTPClient()
        )
    }
}
