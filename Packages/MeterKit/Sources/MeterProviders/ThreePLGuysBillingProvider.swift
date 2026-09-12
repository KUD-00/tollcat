import Foundation
import MeterCore

/// 3PLGuys 履约买方发票（`GET /v0/invoices`）。
///
/// 文档：https://developer.3plguys.com/docs/invoices/
/// 认证：`Authorization: Bearer <API key>`（需 `invoices` scope；亦可 OAuth access token）。
/// Host：`api.3plguys.com`。
/// 金额：`totalAmount` 为**分**（cents）+ `currency`（ISO 4217，常见 USD）。
/// 日期优先 `createdAt`，其次 `dueDate`。跳过 `cancelled` / `refunded`。
public struct ThreePLGuysBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.threeplguys }
    public static let apiHost = "api.3plguys.com"
    static let centsPerUnit = Decimal(100)
    static let pageSize = 10
    static let maxPages = 40

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
        if let primary = try? RequiredCredential.value(.personalAccessToken, in: credential, providerID: .threeplguys) {
            token = primary
        } else if let apiToken = try? RequiredCredential.value(.apiToken, in: credential, providerID: .threeplguys) {
            token = apiToken
        } else {
            token = try RequiredCredential.value(.apiKey, in: credential, providerID: .threeplguys)
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

        var skip = 0
        var pages = 0
        while pages < Self.maxPages {
            pages += 1
            let batch = try await loadInvoices(skip: skip, headers: headers)
            if batch.isEmpty { break }
            for inv in batch {
                let status = (inv.status ?? "").lowercased()
                if status == "cancelled" || status == "canceled" || status == "refunded" {
                    continue
                }
                let cents = inv.totalAmount?.value ?? 0
                guard cents > 0 else { continue }
                let amount = cents / Self.centsPerUnit
                try currencies.observe(inv.currency ?? "USD", providerID: .threeplguys)
                let stamp = inv.createdAt.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? inv.dueDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                let label = inv.name ?? inv.id ?? "invoice"
                if current.contains(stamp) {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: inv.status ?? "invoice",
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
            if batch.count < Self.pageSize { break }
            skip += Self.pageSize
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .threeplguys
        )
        return Snapshot(
            providerID: .threeplguys,
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

    private func loadInvoices(skip: Int, headers: [String: String]) async throws -> [Invoice] {
        let data = try await ProviderHTTP.get(
            url: Self.invoicesURL(skip: skip),
            headers: headers,
            client: httpClient,
            providerID: .threeplguys
        )
        if let list = try? ProviderHTTP.decode([Invoice].self, from: data, providerID: .threeplguys) {
            return list
        }
        let envelope = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .threeplguys)
        return envelope.data ?? envelope.items ?? envelope.invoices ?? []
    }

    static func invoicesURL(skip: Int) -> URL {
        ProviderURL.https(
            host: apiHost,
            path: "/v0/invoices",
            query: [
                URLQueryItem(name: "skip", value: String(skip)),
                URLQueryItem(name: "take", value: String(pageSize)),
                URLQueryItem(name: "sortBy", value: "createdAt"),
                URLQueryItem(name: "sortOrder", value: "desc"),
            ]
        )
    }

    struct Envelope: Decodable, Sendable {
        var data: [Invoice]?
        var items: [Invoice]?
        var invoices: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var id: String?
        var status: String?
        var name: String?
        var dueDate: String?
        var createdAt: String?
        var totalAmount: FlexibleDecimal?
        var currency: String?
    }
}
