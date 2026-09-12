import Foundation
import MeterCore

/// Botpress 工作区即将出账发票（`GET /v1/admin/workspaces/{id}/billing/upcoming-invoice`）。
///
/// 概念文档：https://www.botpress.com/docs/api-reference/admin-api/concepts/
/// 金额字段：`lineItems[].totalInCents` + `currency`（样例 total 与 cents 对齐）；合计 /100。
/// 认证：`Authorization: Bearer <PAT>`。Host：`api.botpress.cloud`。
/// 凭据：`apiToken`/`apiKey` + `accountID`（workspace id）。
public struct BotpressBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.botpress }
    public static let apiHost = "api.botpress.cloud"
    static let centsPerUnit = Decimal(100)

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
        _ = horizon
        let token: String
        if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .botpress) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiKey, in: credential, providerID: .botpress)
        }
        let workspaceID = try RequiredCredential.value(.accountID, in: credential, providerID: .botpress)
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
            "x-workspace-id": workspaceID,
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let data = try await ProviderHTTP.get(
            url: Self.upcomingInvoiceURL(workspaceID: workspaceID),
            headers: headers,
            client: httpClient,
            providerID: .botpress
        )
        let envelope = try ProviderHTTP.decode(UpcomingInvoice.self, from: data, providerID: .botpress)
        var currencies = CurrencyAccumulator()
        var lines = SpendLineAccumulator()
        var total: Decimal = 0

        let items = envelope.lineItems ?? []
        if items.isEmpty {
            let cents = envelope.total?.value ?? 0
            if cents != 0 {
                let amount = cents / Self.centsPerUnit
                try currencies.observe(envelope.currency ?? "USD", providerID: .botpress)
                total = amount
                lines.add(
                    SpendLine(
                        category: "invoice",
                        label: "upcoming",
                        amountUSD: Money(usd: amount)
                    )
                )
            }
        } else {
            for item in items {
                let cents = item.totalInCents?.value ?? 0
                guard cents != 0 else { continue }
                let amount = cents / Self.centsPerUnit
                try currencies.observe(item.currency ?? envelope.currency ?? "USD", providerID: .botpress)
                total += amount
                lines.add(
                    SpendLine(
                        category: "invoice",
                        label: item.description ?? item.id ?? "line",
                        amountUSD: Money(usd: amount)
                    )
                )
            }
        }

        let converted = try currencies.convert(
            total,
            rates: rateSource.current,
            providerID: .botpress
        )
        return Snapshot(
            providerID: .botpress,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: converted.money,
            dailyUSD: [:],
            converted: currencies.needsConversionNote ? converted : nil,
            lines: lines.snapshot
        )
    }

    static func upcomingInvoiceURL(workspaceID: String) -> URL {
        ProviderURL.https(
            host: apiHost,
            path: "/v1/admin/workspaces/\(workspaceID)/billing/upcoming-invoice"
        )
    }

    struct UpcomingInvoice: Decodable, Sendable {
        var total: FlexibleDecimal?
        var currency: String?
        var lineItems: [LineItem]?
    }

    struct LineItem: Decodable, Sendable {
        var id: String?
        var description: String?
        var totalInCents: FlexibleDecimal?
        var currency: String?
    }
}
