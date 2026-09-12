import Foundation
import MeterCore

/// Dilmune Cloud 发票（`GET /invoices`）。
///
/// 文档：https://docs.dilmune.com/openapi.yaml
/// 认证：`Authorization: Bearer dcs_…`（`apiToken`/`apiKey`）。
/// Host：`api.dilmune.com`，path 前缀 `/api/v1`。
/// 金额：`amount` 为 Stripe 分（÷100）+ `currency`；日期：`periodStart`。
/// 跳过 `draft` / `void` / `uncollectible`。亦有 `/billing/overview` 的 `currentMonthSpendCents`，
/// 本适配器以发票列表做周期历史。
public struct DilmuneBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.dilmune }
    public static let apiHost = "api.dilmune.com"
    public static let centsPerUnit: Decimal = 100
    static let maxPages = 20

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
        if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .dilmune) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiKey, in: credential, providerID: .dilmune)
        }
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        var page = 1
        while page <= Self.maxPages {
            let envelope = try await loadInvoices(page: page, headers: headers)
            let invoices = envelope.data ?? []
            for inv in invoices {
                let status = (inv.status ?? "").lowercased()
                if status == "draft" || status == "void" || status == "uncollectible" { continue }
                let cents = inv.amount?.value ?? 0
                guard cents != 0 else { continue }
                let amount = cents / Self.centsPerUnit
                try currencies.observe(inv.currency, providerID: .dilmune)
                let stamp = inv.periodStart.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? inv.createdAt.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                let label = inv.stripeInvoiceId ?? inv.id ?? "invoice"
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
            if invoices.count < 50 { break }
            page += 1
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .dilmune
        )
        return Snapshot(
            providerID: .dilmune,
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

    private func loadInvoices(page: Int, headers: [String: String]) async throws -> Envelope {
        let data = try await ProviderHTTP.get(
            url: ProviderURL.https(
                host: Self.apiHost,
                path: "/api/v1/invoices",
                query: [
                    URLQueryItem(name: "page", value: String(page)),
                    URLQueryItem(name: "per_page", value: "50"),
                ]
            ),
            headers: headers,
            client: httpClient,
            providerID: .dilmune
        )
        return try ProviderHTTP.decode(Envelope.self, from: data, providerID: .dilmune)
    }

    static var invoicesURL: URL {
        ProviderURL.https(host: apiHost, path: "/api/v1/invoices")
    }

    struct Envelope: Decodable, Sendable {
        var success: Bool?
        var data: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var id: String?
        var stripeInvoiceId: String?
        var amount: FlexibleDecimal?
        var currency: String?
        var status: String?
        var periodStart: String?
        var periodEnd: String?
        var createdAt: String?
    }
}
