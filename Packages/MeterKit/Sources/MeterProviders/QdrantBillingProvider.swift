import Foundation
import MeterCore

/// Qdrant Cloud 本月计量与发票。
///
/// 文档（Cloud Public API / grpc-gateway）：
/// - `GET /api/metering/v1/accounts/{accountId}/meterings` — 按月 `amountMillicents` + `currency`
/// - `GET /api/metering/v1/accounts/{accountId}/meterings/{year}/{month}` — 明细行
/// - `GET /api/billing/v1/accounts/{accountId}/invoices` — `totalAmount` 毫分（草稿作回退）
///
/// 认证：`Authorization: apikey <Cloud Management Key>`，权限 `read:payment_information`。
/// 金额单位是**毫分**（millicents，一分的千分之一）：除以 100000 才是主币单位。
public struct QdrantBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.qdrant }
    public static let draftStatus = "INVOICE_STATUS_DRAFT"
    /// 毫分 → 主币（USD/EUR 等）。
    static let millicentsPerUnit = Decimal(100_000)

    public var httpClient: any HTTPClient
    public var now: @Sendable () -> Date
    public var calendar: Calendar
    public var rateSource: SharedExchangeRates

    public init(
        httpClient: any HTTPClient,
        now: @escaping @Sendable () -> Date,
        calendar: Calendar,
        rateSource: SharedExchangeRates
    ) {
        self.httpClient = httpClient
        self.now = now
        self.calendar = calendar
        self.rateSource = rateSource
    }

    public func fetch(credential: Credential) async throws -> Snapshot {
        try await fetch(credential: credential, horizon: .currentMonth)
    }

    public func fetch(
        credential: Credential,
        horizon: BillingFetchHorizon
    ) async throws -> Snapshot {
        let now = now()
        let key = try RequiredCredential.value(.apiKey, in: credential, providerID: .qdrant)
        let headers = [
            "Authorization": "apikey \(key)",
        ]
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()

        let accountID: String
        if let pinned = credential.value(for: .accountID)?
            .trimmingCharacters(in: .whitespacesAndNewlines), !pinned.isEmpty {
            accountID = pinned
        } else {
            accountID = try await loadFirstAccountID(headers: headers)
        }

        let year = calendar.component(.year, from: window.start)
        let month = calendar.component(.month, from: window.start)

        let monthly = try await loadMonthlyMeterings(accountID: accountID, headers: headers)
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()

        if horizon == .availableHistory {
            for summary in monthly {
                guard let y = summary.year, let m = summary.month else { continue }
                guard !(y == year && m == month) else { continue }
                try currencies.observe(summary.currency, providerID: .qdrant)
                guard let start = Self.monthStart(year: y, month: m, calendar: calendar) else { continue }
                daily.addPastMonth(
                    start: start,
                    amount: Self.money(millicents: summary.amountMillicents),
                    current: window,
                    calendar: calendar
                )
            }
        }

        let currentSummary = monthly.first { $0.year == year && $0.month == month }
        if let currentSummary {
            try currencies.observe(currentSummary.currency, providerID: .qdrant)
        }

        // 明细：日线 + 行项目；失败不阻断（月汇总仍可用）。
        if let detail = try? await loadMonthDetail(
            accountID: accountID,
            year: year,
            month: month,
            headers: headers
        ) {
            for item in detail {
                try? currencies.observe(item.currency ?? currentSummary?.currency, providerID: .qdrant)
                let amount = Self.netMoney(
                    millicents: item.amountMillicents,
                    discount: item.discountAmountMillicents
                )
                let day = item.startTime.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? window.start
                if window.contains(day) {
                    daily.add(day: day, amount: amount)
                    let label = item.clusterName?.trimmed
                        ?? item.billableEntityReferenceName?.trimmed
                        ?? item.clusterId?.trimmed
                        ?? "usage"
                    lines.add(
                        SpendLine(
                            category: item.billableEntityType?.trimmed ?? "metering",
                            label: label,
                            scope: item.clusterId?.trimmed,
                            amountUSD: amount,
                            quantity: item.usageHours?.value,
                            unit: item.usageHours == nil ? nil : "hours"
                        )
                    )
                }
            }
        }

        var currentMillicents = currentSummary?.amountMillicents
        if currentMillicents == nil {
            // 计量尚无当月行时回退草稿发票。
            let invoices = try await loadInvoices(accountID: accountID, headers: headers)
            if horizon == .availableHistory {
                for invoice in invoices where invoice.status != Self.draftStatus {
                    let start = invoice.createdAt.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    guard let start else { continue }
                    daily.addPastMonth(
                        start: start,
                        amount: Self.money(millicents: invoice.totalAmount),
                        current: window,
                        calendar: calendar
                    )
                }
            }
            if let draft = Self.draftInvoice(invoices) {
                currentMillicents = draft.totalAmount
            }
        }

        guard let millicents = currentMillicents else {
            // 周期刚开始还没计量/草稿。返回没有读数的快照，不要写成 $0。
            return Snapshot(
                providerID: .qdrant,
                kind: .usage,
                fetchedAt: now,
                periodStart: window.start,
                periodEnd: window.endInclusive,
                dailyUSD: daily.snapshotDaily,
                lines: lines.snapshot
            )
        }

        let raw = Self.decimal(millicents: millicents)
        let converted = try currencies.convert(raw, rates: rateSource.current, providerID: .qdrant)
        return Snapshot(
            providerID: .qdrant,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: converted.money,
            dailyUSD: currencies.scaled(daily.snapshotDaily, by: converted.usdPerUnit),
            converted: currencies.needsConversionNote ? converted : nil,
            lines: lines.snapshot
        )
    }

    private func loadFirstAccountID(headers: [String: String]) async throws -> String {
        let data = try await ProviderHTTP.get(
            url: Self.accountsURL,
            headers: headers,
            client: httpClient,
            providerID: .qdrant
        )
        let payload = try ProviderHTTP.decode(AccountList.self, from: data, providerID: .qdrant)
        guard let id = payload.items?.first?.id, !id.isEmpty else {
            throw ProviderError.malformedResponse(providerID: .qdrant)
        }
        return id
    }

    private func loadMonthlyMeterings(
        accountID: String,
        headers: [String: String]
    ) async throws -> [MonthlyMetering] {
        let data = try await ProviderHTTP.get(
            url: Self.meteringsURL(accountID: accountID),
            headers: headers,
            client: httpClient,
            providerID: .qdrant
        )
        let payload = try ProviderHTTP.decode(MonthlyMeteringList.self, from: data, providerID: .qdrant)
        return payload.items ?? []
    }

    private func loadMonthDetail(
        accountID: String,
        year: Int,
        month: Int,
        headers: [String: String]
    ) async throws -> [MeteringItem] {
        let data = try await ProviderHTTP.get(
            url: Self.monthMeteringsURL(accountID: accountID, year: year, month: month),
            headers: headers,
            client: httpClient,
            providerID: .qdrant
        )
        let payload = try ProviderHTTP.decode(MeteringItemList.self, from: data, providerID: .qdrant)
        return payload.items ?? []
    }

    private func loadInvoices(
        accountID: String,
        headers: [String: String]
    ) async throws -> [Invoice] {
        let data = try await ProviderHTTP.get(
            url: Self.invoicesURL(accountID: accountID),
            headers: headers,
            client: httpClient,
            providerID: .qdrant
        )
        let payload = try ProviderHTTP.decode(InvoiceList.self, from: data, providerID: .qdrant)
        return payload.items ?? []
    }

    /// 只认草稿。同时存在多张就取最新创建的那张。
    static func draftInvoice(_ invoices: [Invoice]) -> Invoice? {
        invoices
            .filter { $0.status == draftStatus }
            .max { lhs, rhs in (lhs.createdAt ?? "") < (rhs.createdAt ?? "") }
    }

    static func monthStart(year: Int, month: Int, calendar: Calendar) -> Date? {
        calendar.date(from: DateComponents(year: year, month: month, day: 1))
    }

    static func decimal(millicents: FlexibleDecimal?) -> Decimal {
        guard let raw = millicents?.value else { return 0 }
        return raw / millicentsPerUnit
    }

    static func money(millicents: FlexibleDecimal?) -> Money {
        Money(usd: decimal(millicents: millicents))
    }

    static func netMoney(millicents: FlexibleDecimal?, discount: FlexibleDecimal?) -> Money {
        let gross = decimal(millicents: millicents)
        let disc = decimal(millicents: discount)
        return Money(usd: max(gross - disc, 0))
    }

    static let accountsURL = URL(string: "https://api.cloud.qdrant.io/api/account/v1/accounts")!

    static func meteringsURL(accountID: String) -> URL {
        ProviderURL.https(
            host: "api.cloud.qdrant.io",
            path: "/api/metering/v1/accounts/\(accountID)/meterings"
        )
    }

    static func monthMeteringsURL(accountID: String, year: Int, month: Int) -> URL {
        ProviderURL.https(
            host: "api.cloud.qdrant.io",
            path: "/api/metering/v1/accounts/\(accountID)/meterings/\(year)/\(month)"
        )
    }

    static func invoicesURL(accountID: String) -> URL {
        ProviderURL.https(
            host: "api.cloud.qdrant.io",
            path: "/api/billing/v1/accounts/\(accountID)/invoices"
        )
    }

    struct AccountList: Decodable, Sendable {
        var items: [Account]?
    }

    struct Account: Decodable, Sendable {
        var id: String?
        var name: String?
    }

    struct MonthlyMeteringList: Decodable, Sendable {
        var items: [MonthlyMetering]?
    }

    struct MonthlyMetering: Decodable, Sendable {
        var year: Int?
        var month: Int?
        var amountMillicents: FlexibleDecimal?
        var currency: String?
    }

    struct MeteringItemList: Decodable, Sendable {
        var items: [MeteringItem]?
    }

    struct MeteringItem: Decodable, Sendable {
        var accountId: String?
        var clusterId: String?
        var clusterName: String?
        var startTime: String?
        var endTime: String?
        var billableEntityType: String?
        var billableEntityReferenceName: String?
        var usageHours: FlexibleDecimal?
        var amountMillicents: FlexibleDecimal?
        var discountAmountMillicents: FlexibleDecimal?
        var currency: String?
    }

    struct InvoiceList: Decodable, Sendable {
        var items: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var id: String?
        var number: String?
        var totalAmount: FlexibleDecimal?
        var createdAt: String?
        var status: String?
    }
}

private extension String {
    var trimmed: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
