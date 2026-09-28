import Foundation
import MeterCore

/// Azion Billing GraphQL：`paymentsClientDebt` 的 `amount` + `currency`。
///
/// 文档：`POST https://api.azion.com/v4/billing/graphql`
/// 认证：`Authorization: Token <personal token>`。
/// `billDetail.invoiceNumber` 仅作行标签（无金额）；优先债务窗口 `startDate`/`endDate`。
public struct AzionBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.azion }

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
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .azion)
        let headers = [
            "Authorization": "Token \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let debts = try await loadDebts(headers: headers)
        for debt in debts {
            try currencies.observe(debt.currency, providerID: .azion)
            let amount = debt.amount?.value ?? 0
            guard amount != 0 else { continue }
            let stamp = Self.debtStamp(debt: debt, calendar: calendar) ?? current.start
            let inCurrent = Self.debtOverlaps(debt: debt, current: current, calendar: calendar)
                || current.contains(stamp)
            if inCurrent {
                currentTotal += amount
                let label = debt.created?.trimmed ?? "debt"
                lines.add(
                    SpendLine(
                        category: "debt",
                        label: label,
                        amountUSD: Money(usd: amount)
                    )
                )
            } else if horizon == .availableHistory {
                daily.addPastMonth(
                    start: stamp,
                    amount: Money(usd: amount),
                    current: current,
                    calendar: calendar
                )
            }
        }

        // 以前债务为空时会退回 `balanceFinancialEntry`，但那张表查不到日期，
        // 最多 200 条历史流水会整批算成本月花费。无法按月归属的数不进本月总数；
        // 没有债务就如实报本月没有待付。
        return try Snapshot(
            providerID: .azion,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentTotal),
            dailyUSD: daily.snapshotDaily,
            lines: lines.snapshot
        ).convertedToUSD(using: currencies, rates: rateSource.current)
    }

    private func loadDebts(headers: [String: String]) async throws -> [Debt] {
        let payload = try await ProviderGraphQL.query(
            DebtData.self,
            url: Self.graphqlURL,
            query: Self.debtQuery,
            headers: headers,
            client: httpClient,
            providerID: .azion
        )
        return payload.paymentsClientDebt ?? []
    }

    static let graphqlURL = ProviderURL.https(
        host: "api.azion.com",
        path: "/v4/billing/graphql"
    )

    static let debtQuery = """
    query {
      paymentsClientDebt(limit: 200) {
        amount
        currency
        created
        startDate
        endDate
      }
    }
    """

    static func debtStamp(debt: Debt, calendar: Calendar) -> Date? {
        if let end = debt.endDate.flatMap({ BillingDateParser.parse($0, calendar: calendar) }) {
            return end
        }
        if let start = debt.startDate.flatMap({ BillingDateParser.parse($0, calendar: calendar) }) {
            return start
        }
        return debt.created.flatMap { BillingDateParser.parse($0, calendar: calendar) }
    }

    static func debtOverlaps(
        debt: Debt,
        current: CalendarMonthWindow,
        calendar: Calendar
    ) -> Bool {
        let start = debt.startDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
        let end = debt.endDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
        if let start, let end {
            return start <= current.endInclusive && end >= current.start
        }
        return false
    }

    struct DebtData: Decodable, Sendable {
        var paymentsClientDebt: [Debt]?
    }

    struct Debt: Decodable, Sendable {
        var amount: FlexibleDecimal?
        var currency: String?
        var created: String?
        var startDate: String?
        var endDate: String?
    }
}

private extension String {
    var trimmed: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
