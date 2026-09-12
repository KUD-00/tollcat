import Foundation
import MeterCore

/// Deel 平台费发票（`GET /rest/invoices/deel`；ISO `currency` + `total`）。
///
/// 文档：https://developer.deel.com — scope `accounting:read`。
/// 认证：`Authorization: Bearer <API key>`。
/// 优先 `/invoices/deel`（平台费），不用通用 `/invoices`（工资过账混入）。
/// 跳过 canceled / skipped / failed / refunded / credited。
public struct DeelBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.deel }
    public static let apiHost = "api.letsdeel.com"
    static let pageSize = 50
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
        let token = try RequiredCredential.value(.apiKey, in: credential, providerID: .deel)
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let invoices = try await loadDeelInvoices(headers: headers)
        for invoice in invoices {
            let status = (invoice.status ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            if Self.skipStatuses.contains(status) { continue }
            let currency = invoice.currency?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
            try currencies.observe(currency, providerID: .deel)
            let amount = invoice.total?.value ?? 0
            guard amount != 0 else { continue }
            let stamp = invoice.created_at.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            let rawLabel = invoice.label?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let resolvedLabel = rawLabel.isEmpty ? (invoice.id ?? "invoice") : rawLabel

            if current.contains(stamp) {
                currentTotal += amount
                daily.add(day: stamp, amount: Money(usd: amount))
                lines.add(
                    SpendLine(
                        category: status.isEmpty ? "invoice" : status,
                        label: resolvedLabel,
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
            providerID: .deel
        )
        return Snapshot(
            providerID: .deel,
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

    static let skipStatuses: Set<String> = [
        "canceled", "cancelled", "skipped", "failed", "refunded", "credited",
    ]

    private func loadDeelInvoices(headers: [String: String]) async throws -> [Invoice] {
        var all: [Invoice] = []
        var offset = 0
        for _ in 0..<Self.maxPages {
            let url = ProviderURL.https(
                host: Self.apiHost,
                path: "/rest/invoices/deel",
                query: [
                    URLQueryItem(name: "limit", value: String(Self.pageSize)),
                    URLQueryItem(name: "offset", value: String(offset)),
                ]
            )
            let data = try await ProviderHTTP.get(
                url: url,
                headers: headers,
                client: httpClient,
                providerID: .deel
            )
            let page = try ProviderHTTP.decode(InvoiceList.self, from: data, providerID: .deel)
            let rows = page.data ?? []
            all.append(contentsOf: rows)
            if let totalDec = page.page?.total_rows?.value {
                let reportedTotal = NSDecimalNumber(decimal: totalDec).intValue
                if all.count >= reportedTotal {
                    break
                }
            }
            offset += max(rows.count, 1)
            if rows.isEmpty || rows.count < Self.pageSize {
                break
            }
        }
        return all
    }

    struct InvoiceList: Decodable, Sendable {
        var data: [Invoice]?
        var page: PageMeta?
    }

    struct PageMeta: Decodable, Sendable {
        var offset: FlexibleDecimal?
        var total_rows: FlexibleDecimal?
        var items_per_page: FlexibleDecimal?
    }

    struct Invoice: Decodable, Sendable {
        var id: String?
        var label: String?
        var total: FlexibleDecimal?
        var status: String?
        var currency: String?
        var created_at: String?
    }
}
