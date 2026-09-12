import Foundation
import MeterCore

/// Azion Billing GraphQL：`paymentsClientDebt` / `balanceFinancialEntry` 的 `amount` + `currency`。
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

        if debts.isEmpty {
            let entries = try await loadEntries(headers: headers)
            for entry in entries {
                let type = entry.entryType?.lowercased() ?? ""
                guard type.contains("debit") || type.isEmpty else { continue }
                try currencies.observe(entry.currency, providerID: .azion)
                let amount = entry.amount?.value ?? 0
                guard amount != 0 else { continue }
                currentTotal += amount
                let label = entry.description?.trimmed
                    ?? entry.entryType?.trimmed
                    ?? "entry"
                lines.add(
                    SpendLine(
                        category: "entry",
                        label: label,
                        amountUSD: Money(usd: amount)
                    )
                )
            }
        }

        let converted = try currencies.convert(currentTotal, rates: rateSource.current, providerID: .azion)
        return Snapshot(
            providerID: .azion,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: converted.money,
            dailyUSD: currencies.scaled(daily.snapshotDaily, by: converted.usdPerUnit),
            converted: currencies.needsConversionNote ? converted : nil,
            lines: lines.snapshot
        )
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

    private func loadEntries(headers: [String: String]) async throws -> [Entry] {
        let payload = try await ProviderGraphQL.query(
            EntryData.self,
            url: Self.graphqlURL,
            query: Self.entryQuery,
            headers: headers,
            client: httpClient,
            providerID: .azion
        )
        return payload.balanceFinancialEntry ?? []
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

    static let entryQuery = """
    query {
      balanceFinancialEntry(limit: 200) {
        entryType
        description
        amount
        currency
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

    struct EntryData: Decodable, Sendable {
        var balanceFinancialEntry: [Entry]?
    }

    struct Debt: Decodable, Sendable {
        var amount: FlexibleDecimal?
        var currency: String?
        var created: String?
        var startDate: String?
        var endDate: String?
    }

    struct Entry: Decodable, Sendable {
        var entryType: String?
        var description: String?
        var amount: FlexibleDecimal?
        var currency: String?
    }
}

private extension String {
    var trimmed: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
