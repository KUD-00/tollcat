import Foundation
import MeterCore

/// Realtime Register 财务流水（`GET /v2/billing/financialtransactions`）。
///
/// 文档：https://dm.realtimeregister.com/docs/api/transactions/list
/// 认证：`Authorization: ApiKey <key>`。Host：`api.yoursrs.com`。
/// 金额：`amount` 为分（cents）+ `currency`（EUR/USD）。日期：`date`。
/// 凭据：`apiKey`/`apiToken`。
public struct RealtimeRegisterBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.realtimeregister }
    public static let apiHost = "api.yoursrs.com"
    static let centsPerUnit = Decimal(100)
    static let pageSize = 100
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
        if let primary = try? RequiredCredential.value(.apiKey, in: credential, providerID: .realtimeregister) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiToken, in: credential, providerID: .realtimeregister)
        }
        let headers = [
            "Authorization": "ApiKey \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let transactions = try await loadTransactions(headers: headers)
        for tx in transactions {
            let cents = tx.amount?.value ?? 0
            guard cents != 0 else { continue }
            let amount = cents / Self.centsPerUnit
            try currencies.observe(tx.currency, providerID: .realtimeregister)
            let stamp = tx.date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            let label = tx.processIdentifier
                ?? tx.processAction
                ?? tx.processType
                ?? "transaction"
            if current.contains(stamp) {
                currentTotal += amount
                daily.add(day: stamp, amount: Money(usd: amount))
                lines.add(
                    SpendLine(
                        category: tx.processType ?? "billing",
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
            providerID: .realtimeregister
        )
        return Snapshot(
            providerID: .realtimeregister,
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

    private func loadTransactions(headers: [String: String]) async throws -> [Transaction] {
        var offset = 0
        var pages = 0
        var all: [Transaction] = []
        while pages < Self.maxPages {
            pages += 1
            let data = try await ProviderHTTP.get(
                url: Self.transactionsURL(offset: offset),
                headers: headers,
                client: httpClient,
                providerID: .realtimeregister
            )
            let envelope = try ProviderHTTP.decode(TransactionList.self, from: data, providerID: .realtimeregister)
            let batch = envelope.entities ?? envelope.data ?? []
            all.append(contentsOf: batch)
            if batch.count < Self.pageSize { break }
            offset += Self.pageSize
        }
        return all
    }

    static func transactionsURL(offset: Int) -> URL {
        ProviderURL.https(
            host: apiHost,
            path: "/v2/billing/financialtransactions",
            query: [
                URLQueryItem(name: "limit", value: String(pageSize)),
                URLQueryItem(name: "offset", value: String(offset)),
                URLQueryItem(name: "order", value: "-date"),
            ]
        )
    }

    struct TransactionList: Decodable, Sendable {
        var entities: [Transaction]?
        var data: [Transaction]?
    }

    struct Transaction: Decodable, Sendable {
        var date: String?
        var amount: FlexibleDecimal?
        var currency: String?
        var processType: String?
        var processAction: String?
        var processIdentifier: String?
    }
}
