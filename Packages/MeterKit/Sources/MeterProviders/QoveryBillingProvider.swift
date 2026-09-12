import Foundation
import MeterCore

/// Qovery 组织发票（`GET /organization/{organizationId}/invoice`）。
///
/// 文档：https://www.qovery.com/docs/api-reference/openapi.yaml（Billing → List organization invoices）
/// 认证：`Authorization: Token <API token>`（Organization Api Token；亦兼容 Bearer）。
/// Host：`api.qovery.com`。
/// 金额：`total` + `currency_code`。按 `created_at` 归入本月。
/// 凭据：`apiToken`/`apiKey` + `accountID`（organization UUID）。
public struct QoveryBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.qovery }
    public static let apiHost = "api.qovery.com"

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
            if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .qovery) {
                token = primary
            } else {
                token = try RequiredCredential.value(.apiKey, in: credential, providerID: .qovery)
            }
        let organizationID = try RequiredCredential.value(
            .accountID, in: credential, providerID: .qovery
        )
        let headers = [
            "Authorization": "Token \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let invoices = try await loadInvoices(organizationID: organizationID, headers: headers)
        for inv in invoices {
            let amount = inv.total?.value ?? 0
            guard amount != 0 else { continue }
            try currencies.observe(inv.currency_code, providerID: .qovery)
            let stamp = inv.created_at.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            let label = inv.id ?? "invoice"
            if current.contains(stamp) {
                currentTotal += amount
                daily.add(day: stamp, amount: Money(usd: amount))
                lines.add(
                    SpendLine(
                        category: "invoice",
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
            providerID: .qovery
        )
        return Snapshot(
            providerID: .qovery,
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

    private func loadInvoices(
        organizationID: String,
        headers: [String: String]
    ) async throws -> [Invoice] {
        let data = try await ProviderHTTP.get(
            url: Self.invoicesURL(organizationID: organizationID),
            headers: headers,
            client: httpClient,
            providerID: .qovery
        )
        if let list = try? ProviderHTTP.decode([Invoice].self, from: data, providerID: .qovery) {
            return list
        }
        let envelope = try ProviderHTTP.decode(InvoiceList.self, from: data, providerID: .qovery)
        return envelope.results ?? envelope.invoices ?? envelope.data ?? []
    }

    static func invoicesURL(organizationID: String) -> URL {
        ProviderURL.https(
            host: apiHost,
            path: "/organization/\(organizationID)/invoice"
        )
    }

    struct InvoiceList: Decodable, Sendable {
        var results: [Invoice]?
        var invoices: [Invoice]?
        var data: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var id: String?
        var total: FlexibleDecimal?
        var total_in_cents: Int?
        var currency_code: String?
        var created_at: String?
        var status: String?
    }
}
