import Foundation
import MeterCore

/// Cerebrium 项目发票（`GET /v2/projects/{project_id}/invoices`）。
///
/// 文档：https://cerebrium.ai/docs/api-reference/subscriptions/list-invoices
/// 认证：`Authorization: Bearer <Service Account Token>`（Dashboard → API Keys）。
/// Host：`rest.cerebrium.ai`。
/// 金额：`amountDue`（最小货币单位）+ `currency`（ISO 4217）同资源。
/// 凭据：`apiToken`/`apiKey`/`personalAccessToken` + `projectID`。
/// 跳过 `void` / `draft` / `uncollectible`；零小数币不除 100。
public struct CerebriumBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.cerebrium }
    public static let apiHost = "rest.cerebrium.ai"
    static let skipStatuses: Set<String> = [
        "void", "draft", "uncollectible", "cancelled", "canceled",
    ]

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
        let token: String
        if let primary = try? RequiredCredential.value(.personalAccessToken, in: credential, providerID: .cerebrium) {
            token = primary
        } else if let apiToken = try? RequiredCredential.value(.apiToken, in: credential, providerID: .cerebrium) {
            token = apiToken
        } else {
            token = try RequiredCredential.value(.apiKey, in: credential, providerID: .cerebrium)
        }
        let projectID = try RequiredCredential.value(.projectID, in: credential, providerID: .cerebrium)
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let invoices = try await loadInvoices(projectID: projectID, headers: headers)
        for inv in invoices {
            let status = (inv.paymentStatus ?? "").lowercased()
            if Self.skipStatuses.contains(status) { continue }
            let currency = inv.currency?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
            guard let currency, !currency.isEmpty else { continue }
            let minors = inv.amountDue?.value ?? 0
            guard minors != 0 else { continue }
            let amount = Self.majorUnits(minors, currency: currency)
            try currencies.observe(currency, providerID: .cerebrium)
            let stamp = inv.createdAt.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            let label = inv.id ?? "invoice"
            if current.contains(stamp) {
                currentTotal += amount
                daily.add(day: stamp, amount: Money(usd: amount))
                lines.add(
                    SpendLine(
                        category: inv.paymentStatus ?? "invoice",
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

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .cerebrium
        )
        return Snapshot(
            providerID: .cerebrium,
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

    /// `amountDue` 为最小货币单位；零小数币不除 100。
    static func majorUnits(_ minor: Decimal, currency: String) -> Decimal {
        let zeroDecimal: Set<String> = ["JPY", "KRW", "VND", "CLP", "ISK", "UGX", "XAF", "XOF", "XPF"]
        if zeroDecimal.contains(currency.uppercased()) { return minor }
        return minor / 100
    }

    private func loadInvoices(
        projectID: String,
        headers: [String: String]
    ) async throws -> [Invoice] {
        let data = try await ProviderHTTP.get(
            url: Self.invoicesURL(projectID: projectID),
            headers: headers,
            client: httpClient,
            providerID: .cerebrium
        )
        if let list = try? ProviderHTTP.decode([Invoice].self, from: data, providerID: .cerebrium) {
            return list
        }
        let envelope = try ProviderHTTP.decode(InvoiceList.self, from: data, providerID: .cerebrium)
        return envelope.invoices ?? envelope.data ?? envelope.items ?? []
    }

    static func invoicesURL(projectID: String) -> URL {
        ProviderURL.https(
            host: apiHost,
            path: "/v2/projects/\(projectID)/invoices"
        )
    }

    struct InvoiceList: Decodable, Sendable {
        var invoices: [Invoice]?
        var data: [Invoice]?
        var items: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var id: String?
        var amountDue: FlexibleDecimal?
        var currency: String?
        var createdAt: String?
        var paymentStatus: String?
        var accountCountry: String?
        var accountName: String?
        var fileUrl: String?
    }
}
