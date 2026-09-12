import Foundation
import Testing
import MeterCore
@testable import MeterFeatures

struct ServiceRowBuilderTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()
    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: 17))!
    }

    @Test("同厂商两份用量收成一行")
    func twoConnectionsSameProviderMakeOneVendorRow() {
        let work = AccountID.fixture(1)
        let personal = AccountID.fixture(2)
        let rows = ServiceRowBuilder.rows(
            memberships: [ProviderMembership(providerID: .cloudflare, sortIndex: 0)],
            connections: [
                ProviderConnectionState(
                    accountID: work,
                    providerID: .cloudflare,
                    nickname: "工作",
                    isEnabled: true,
                    sortIndex: 0,
                    lastSuccessfulRefreshAt: now,
                    credentialReference: "credential.\(work.rawValue.uuidString)",
                    includeInGlobalRefresh: true
                ),
                ProviderConnectionState(
                    accountID: personal,
                    providerID: .cloudflare,
                    nickname: "个人",
                    isEnabled: true,
                    sortIndex: 1,
                    lastSuccessfulRefreshAt: now,
                    credentialReference: "credential.\(personal.rawValue.uuidString)",
                    includeInGlobalRefresh: true
                ),
            ],
            latest: [:],
            monthToDate: nil,
            marks: [:],
            subscriptions: [],
            now: now,
            calendar: calendar
        )
        #expect(rows.count == 1)
        #expect(rows[0].id == .cloudflare)
        #expect(rows[0].displayName == "Cloudflare")
        let usageCount = 2
        #expect(rows[0].subtitle == String(localized: L("\(usageCount) 份用量")))
        #expect(rows[0].kind == .usage)
    }

    @Test("没快照时类别跟目录走，从量和预充值不会糊成一种")
    func kindFallsBackToDescriptor() {
        let rows = ServiceRowBuilder.rows(
            memberships: [
                ProviderMembership(providerID: .cloudflare, sortIndex: 0),
                ProviderMembership(providerID: .openrouter, sortIndex: 1),
            ],
            connections: [],
            latest: [:],
            monthToDate: nil,
            marks: [:],
            subscriptions: [],
            now: now,
            calendar: calendar
        )
        #expect(rows.map(\.id) == [.cloudflare, .openrouter])
        #expect(rows.map(\.kind) == [.usage, .prepaid])
    }

    @Test("陈旧行的副标题用快照和盖章里更近的一次，不要卡在过期的 lastSuccessfulRefreshAt")
    func staleSubtitlePrefersNewerSnapshotFetchedAt() {
        let old = now.addingTimeInterval(-8 * 60)
        let account = AccountID.fixture(for: .cloudflare)
        let start = calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 8, day: 31))!
        let snapshot = Snapshot(
            providerID: .cloudflare,
            accountID: account,
            kind: .usage,
            fetchedAt: now,
            periodStart: start,
            periodEnd: end,
            currentSpendUSD: Money(roundedUSD: 11.05)
        )
        let rows = ServiceRowBuilder.rows(
            memberships: [ProviderMembership(providerID: .cloudflare, sortIndex: 0)],
            connections: [
                ProviderConnectionState(
                    accountID: account,
                    providerID: .cloudflare,
                    isEnabled: true,
                    sortIndex: 0,
                    lastSuccessfulRefreshAt: old,
                    credentialReference: "cf-ref",
                    includeInGlobalRefresh: true
                ),
            ],
            latest: AccountLatest.reduceAll(snapshots: [snapshot], calendar: calendar),
            monthToDate: nil,
            marks: [account: .stale],
            subscriptions: [],
            now: now,
            calendar: calendar
        )
        #expect(rows.first?.subtitle == String(localized: L("刚刚")))
    }

    @Test("读数是新的就不写刷新时刻：服务卡上不出现「刚刚」")
    func freshRowOmitsRefreshCaption() {
        let account = AccountID.fixture(for: .cloudflare)
        let start = calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 8, day: 31))!
        let snapshot = Snapshot(
            providerID: .cloudflare,
            accountID: account,
            kind: .usage,
            fetchedAt: now,
            periodStart: start,
            periodEnd: end,
            currentSpendUSD: Money(roundedUSD: 11.05)
        )
        let rows = ServiceRowBuilder.rows(
            memberships: [ProviderMembership(providerID: .cloudflare, sortIndex: 0)],
            connections: [
                ProviderConnectionState(
                    accountID: account,
                    providerID: .cloudflare,
                    isEnabled: true,
                    sortIndex: 0,
                    lastSuccessfulRefreshAt: now,
                    credentialReference: "cf-ref",
                    includeInGlobalRefresh: true
                ),
            ],
            latest: AccountLatest.reduceAll(snapshots: [snapshot], calendar: calendar),
            monthToDate: nil,
            marks: [account: .current],
            subscriptions: [],
            now: now,
            calendar: calendar
        )
        #expect(rows.first?.subtitle == nil)
    }

    /// `AccountLatest` 只存标量（原币码 + 厂商自己报的汇率），不再整个搬
    /// `ConvertedAmount` 过来——见它的准入准则第 4 条。原币金额由
    /// `balanceUSD ÷ balanceUSDPerUnit` 还原，**用厂商的汇率折回去**。
    ///
    /// 这一条钉住的是：换成两个标量之后，副标题在美元和人民币两种显示货币下
    /// 和从前逐字相同。
    @Test("换算余额的副标题：美元 / 人民币两种显示货币下都还是原来那串")
    func convertedBalanceSubtitleIsUnchanged() {
        let account = AccountID.fixture(for: .deepseek)
        let start = calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 8, day: 31))!
        let converted = ConvertedAmount(
            currency: "CNY",
            amount: Decimal(string: "14.17")!,
            usdPerUnit: Decimal(string: "0.1404")!,
            usd: Decimal(string: "1.99")!
        )
        let snapshot = Snapshot(
            providerID: .deepseek,
            accountID: account,
            kind: .prepaid,
            fetchedAt: now,
            periodStart: start,
            periodEnd: end,
            balanceUSD: Money(usd: converted.usd),
            converted: converted
        )
        let latest = AccountLatest.reduceAll(snapshots: [snapshot], calendar: calendar)
        #expect(latest[account]?.balanceOriginalCurrency == "CNY")
        #expect(latest[account]?.balanceUSDPerUnit == converted.usdPerUnit)

        func subtitle(_ presentation: MoneyPresentation) -> String? {
            ServiceRowBuilder.rows(
                memberships: [ProviderMembership(providerID: .deepseek, sortIndex: 0)],
                connections: [
                    ProviderConnectionState(
                        accountID: account,
                        providerID: .deepseek,
                        isEnabled: true,
                        sortIndex: 0,
                        lastSuccessfulRefreshAt: now,
                        credentialReference: "ds-ref",
                        includeInGlobalRefresh: true
                    ),
                ],
                latest: latest,
                monthToDate: nil,
                marks: [account: .current],
                subscriptions: [],
                now: now,
                calendar: calendar,
                presentation: presentation
            ).first?.subtitle
        }

        // 显示美元：走汇率表把 $1.99 写出来。
        #expect(subtitle(.usd) == String(localized: L("余额 $1.99")))

        // 显示人民币：**用厂商自己报的汇率**折回原币，不是拿我们的汇率表折一遍。
        let rates = ExchangeRates(usdPerUnit: ["CNY": Decimal(string: "0.14")!])
        let cny = MoneyPresentation(currencyCode: "CNY", rates: rates)
        let text = subtitle(cny)
        #expect(text == String(localized: L("余额 CN¥14.17")) || text == String(localized: L("余额 ¥14.17")), "\(text ?? "nil")")
    }
}

struct ServiceListArrangementTests {
    @Test("默认按计费模式：从量和预充值拆开，组内保持加入顺序")
    func groupsByKindAndKeepsJoinOrder() {
        let rows = [
            item(.cloudflare, kind: .usage, name: "Cloudflare", amount: 11.05),
            item(.openrouter, kind: .prepaid, name: "OpenRouter", amount: 74.75),
            item(.aws, kind: .usage, name: "AWS", amount: 21.40),
        ]
        let sections = ServiceListArrangement.sections(from: rows, sort: .kind)
        #expect(sections.map(\.kind) == [.usage, .prepaid])
        #expect(sections[0].title == String(localized: L("用量后付费")))
        #expect(sections[1].title == String(localized: L("预充值余额")))
        #expect(sections[0].rows.map(\.id) == [.cloudflare, .aws])
        #expect(sections[1].rows.map(\.id) == [.openrouter])
    }

    @Test("只有一种计费模式时不画小标题")
    func omitsTitlesWhenEveryRowSharesAKind() {
        let rows = [
            item(.cloudflare, kind: .usage, name: "Cloudflare", amount: 11.05),
            item(.aws, kind: .usage, name: "AWS", amount: 21.40),
        ]
        let sections = ServiceListArrangement.sections(from: rows, sort: .kind)
        #expect(sections.count == 1)
        #expect(sections[0].title == nil)
        #expect(sections[0].rows.map(\.id) == [.cloudflare, .aws])
    }

    @Test("按价格：一张扁列表，行首数字从高到低")
    func priceSortIsFlatDescending() {
        let rows = [
            item(.cloudflare, kind: .usage, name: "Cloudflare", amount: 11.05),
            item(.openrouter, kind: .prepaid, name: "OpenRouter", amount: 74.75),
            item(.aws, kind: .usage, name: "AWS", amount: 21.40),
        ]
        let sections = ServiceListArrangement.sections(from: rows, sort: .price)
        #expect(sections.count == 1)
        #expect(sections[0].title == nil)
        #expect(sections[0].rows.map(\.id) == [.openrouter, .aws, .cloudflare])
    }

    @Test("价格相同按显示名")
    func priceTiesBreakByName() {
        let rows = [
            item(.neon, kind: .usage, name: "Neon", amount: 10),
            item(.aws, kind: .usage, name: "AWS", amount: 10),
        ]
        let sections = ServiceListArrangement.sections(from: rows, sort: .price)
        #expect(sections[0].rows.map(\.id) == [.aws, .neon])
    }

    @Test("按类别：一组一类活，组内保持加入顺序")
    func groupsByCategoryAndKeepsJoinOrder() {
        let rows = [
            item(.cloudflare, kind: .usage, name: "Cloudflare", amount: 11.05, category: .networkEdge),
            item(.openrouter, kind: .prepaid, name: "OpenRouter", amount: 74.75, category: .aiInference),
            item(.neon, kind: .usage, name: "Neon", amount: 3, category: .database),
            item(.openai, kind: .prepaid, name: "OpenAI", amount: 8, category: .aiInference),
        ]
        let sections = ServiceListArrangement.sections(from: rows, sort: .category)
        #expect(sections.map(\.category) == [.aiInference, .database, .networkEdge])
        #expect(sections[0].title == String(localized: L("AI 推理")))
        #expect(sections[0].rows.map(\.id) == [.openrouter, .openai])
        #expect(sections[1].rows.map(\.id) == [.neon])
        #expect(sections[2].rows.map(\.id) == [.cloudflare])
    }

    @Test("类别组序按目录声明序，不按金额")
    func categoryOrderFollowsCatalogDeclaration() {
        let rows = [
            item(.vercel, kind: .usage, name: "Vercel", amount: 200, category: .hosting),
            item(.openrouter, kind: .prepaid, name: "OpenRouter", amount: 1, category: .aiInference),
        ]
        let sections = ServiceListArrangement.sections(from: rows, sort: .category)
        #expect(sections.map(\.category) == [.aiInference, .hosting])
        #expect(ServiceListArrangement.categoryOrder.first == .aiInference)
        #expect(ServiceListArrangement.categoryOrder.last == .other)
    }

    @Test("只有一类时不画小标题")
    func omitsTitlesWhenEveryRowSharesACategory() {
        let rows = [
            item(.openrouter, kind: .prepaid, name: "OpenRouter", amount: 74.75, category: .aiInference),
            item(.openai, kind: .prepaid, name: "OpenAI", amount: 8, category: .aiInference),
        ]
        let sections = ServiceListArrangement.sections(from: rows, sort: .category)
        #expect(sections.count == 1)
        #expect(sections[0].title == nil)
        #expect(sections[0].rows.map(\.id) == [.openrouter, .openai])
    }

    @Test("空列表不造空组")
    func emptyRowsMakeNoSections() {
        #expect(ServiceListArrangement.sections(from: [], sort: .kind).isEmpty)
        #expect(ServiceListArrangement.sections(from: [], sort: .category).isEmpty)
        #expect(ServiceListArrangement.sections(from: [], sort: .price).isEmpty)
    }

    @Test("计费模式顺序：从量、月费加超额、预充值、订阅、额度")
    func kindOrderMatchesWhatTheNumberMeans() {
        let rows = [
            item(.vercel, kind: .freeTier, name: "Vercel", amount: 0.34),
            item(.cursor, kind: .subscription, name: "Cursor", amount: 20),
            item(.github, kind: .planAndUsage, name: "GitHub", amount: 4),
            item(.openrouter, kind: .prepaid, name: "OpenRouter", amount: 40),
            item(.cloudflare, kind: .usage, name: "Cloudflare", amount: 11),
        ]
        let sections = ServiceListArrangement.sections(from: rows, sort: .kind)
        #expect(sections.map(\.kind) == [
            .usage, .planAndUsage, .prepaid, .subscription, .freeTier,
        ])
        #expect(sections.allSatisfy { $0.title != nil })
    }

    private func item(
        _ id: ProviderID,
        kind: ProviderKind,
        name: String,
        amount: Double,
        category: ProviderCategory = .other
    ) -> ServiceRowItem {
        ServiceRowItem(
            id: id,
            kind: kind,
            category: category,
            nickname: nil,
            displayName: name,
            spokenName: name,
            colorKey: "x",
            value: "\(amount)",
            spokenValue: "\(amount)",
            subtitle: nil,
            usesSecondaryValue: false,
            isConnected: true,
            isStale: false,
            valueCaption: nil,
            amountValue: amount,
            supersededByManual: false
        )
    }
}
