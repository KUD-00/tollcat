import Foundation
import MeterCore

/// DoiT 云发票列表（`GET /billing/v1/invoices`）。
///
/// 文档：https://developer.doit.com/docs/invoice
/// 认证：`Authorization: Bearer`（API key）。Host：`api.doit.com`。
/// 金额：`totalAmount`（主币；不用 `balanceAmount`）+ `currency`。
/// 日期：`invoiceDate`（毫秒 epoch）。跳过空金额。
public struct DoitBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.doit }
    public static let apiHost = "api.doit.com"
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
        if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .doit) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiKey, in: credential, providerID: .doit)
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

        var pageToken: String? = nil
        var page = 0
        while page < Self.maxPages {
            page += 1
            let envelope = try await loadInvoices(pageToken: pageToken, headers: headers)
            for inv in envelope.invoices ?? [] {
                let amount = inv.totalAmount?.value ?? 0
                guard amount != 0 else { continue }
                try currencies.observe(inv.currency, providerID: .doit)
                let stamp: Date
                if let ms = inv.invoiceDate?.value {
                    stamp = Date(timeIntervalSince1970: NSDecimalNumber(decimal: ms).doubleValue / 1000.0)
                } else {
                    stamp = current.start
                }
                let label = inv.id ?? "invoice"
                if current.contains(stamp) {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: inv.platform ?? "invoice",
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
            let next = envelope.pageToken
            guard let next, !next.isEmpty, !(envelope.invoices ?? []).isEmpty else { break }
            pageToken = next
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .doit
        )
        return Snapshot(
            providerID: .doit,
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

    private func loadInvoices(pageToken: String?, headers: [String: String]) async throws -> Envelope {
        var query: [URLQueryItem] = []
        if let pageToken {
            query.append(URLQueryItem(name: "pageToken", value: pageToken))
        }
        let data = try await ProviderHTTP.get(
            url: ProviderURL.https(
                host: Self.apiHost,
                path: "/billing/v1/invoices",
                query: query
            ),
            headers: headers,
            client: httpClient,
            providerID: .doit
        )
        return try ProviderHTTP.decode(Envelope.self, from: data, providerID: .doit)
    }

    static var invoicesURL: URL {
        ProviderURL.https(host: apiHost, path: "/billing/v1/invoices")
    }

    struct Envelope: Decodable, Sendable {
        var invoices: [Invoice]?
        var pageToken: String?
        var rowCount: Int?
    }

    struct Invoice: Decodable, Sendable {
        var id: String?
        var invoiceDate: FlexibleDecimal?
        var platform: String?
        var totalAmount: FlexibleDecimal?
        var balanceAmount: FlexibleDecimal?
        var currency: String?
        var status: String?
    }
}
