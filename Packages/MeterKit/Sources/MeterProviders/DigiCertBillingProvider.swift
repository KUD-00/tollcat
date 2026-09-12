import Foundation
import MeterCore

/// DigiCert CertCentral 本月应付/消费（优先 `unpaid_invoice_balance` + balance-history debit，不用纯存款 wallet）。
///
/// 文档：
/// - `GET /services/v2/finance/balance` → balance / currency / unpaid_invoice_balance
/// - `GET /services/v2/finance/balance-history` → credit/debit + currency + receipt_id
/// - `GET /services/v2/finance/receipt/{id}` → gross_amount + currency（可选 enrichment）
/// 认证：`X-DC-DEVKEY: <API key>`。可选 `accountID` = container_id。
public struct DigiCertBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.digicert }
    public static let apiHost = "www.digicert.com"
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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .digicert)
        let containerID = credential.value(for: .accountID)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let headers = [
            "X-DC-DEVKEY": apiKey,
            "Content-Type": "application/json",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)

        let balanceData = try await ProviderHTTP.get(
            url: Self.balanceURL(containerID: containerID),
            headers: headers,
            client: httpClient,
            providerID: .digicert
        )
        let balance = try ProviderHTTP.decode(Balance.self, from: balanceData, providerID: .digicert)

        var currencies = CurrencyAccumulator()
        try currencies.observe(balance.currency, providerID: .digicert)

        // Prefer unpaid invoices over deposit wallet balance.
        let unpaid = balance.unpaid_invoice_balance?.value ?? 0
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var monthDebit: Decimal = 0

        let history = try await loadBalanceHistory(headers: headers, containerID: containerID)
        for row in history {
            let debit = row.debit?.value ?? 0
            guard debit != 0 else { continue }
            try currencies.observe(row.currency ?? balance.currency, providerID: .digicert)
            let stamp = row.transaction_date.flatMap {
                BillingDateParser.parse($0, calendar: calendar)
            } ?? current.start
            if current.contains(stamp) {
                monthDebit += debit
                daily.add(day: stamp, amount: Money(usd: debit))
                let label = row.transaction_type
                    ?? (row.receipt_id.flatMap { $0 != "0" ? "receipt \($0)" : nil })
                    ?? "debit"
                lines.add(
                    SpendLine(
                        category: row.transaction_type ?? "debit",
                        label: label,
                        amountUSD: Money(usd: debit)
                    )
                )
            } else if horizon == .availableHistory {
                daily.addPastMonth(
                    start: stamp,
                    amount: Money(usd: debit),
                    current: current,
                    calendar: calendar
                )
            }
        }

        // Current spend: unpaid invoice balance when present, else month debit from history.
        let rawCurrent: Decimal
        if unpaid != 0 {
            rawCurrent = unpaid
            if lines.isEmpty {
                lines.add(
                    SpendLine(
                        category: "invoice",
                        label: "unpaid invoices",
                        amountUSD: Money(usd: unpaid)
                    )
                )
            }
        } else {
            rawCurrent = monthDebit
        }

        let converted = try currencies.convert(
            rawCurrent,
            rates: rateSource.current,
            providerID: .digicert
        )
        return Snapshot(
            providerID: .digicert,
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

    private func loadBalanceHistory(
        headers: [String: String],
        containerID: String?
    ) async throws -> [HistoryRow] {
        var offset = 0
        var pages = 0
        var rows: [HistoryRow] = []
        while true {
            let data = try await ProviderHTTP.get(
                url: Self.historyURL(containerID: containerID, offset: offset),
                headers: headers,
                client: httpClient,
                providerID: .digicert
            )
            let payload = try ProviderHTTP.decode(HistoryList.self, from: data, providerID: .digicert)
            let batch = payload.adjustments ?? []
            rows.append(contentsOf: batch)
            pages += 1
            if batch.isEmpty || batch.count < 100 || pages >= Self.maxPages {
                break
            }
            offset += batch.count
        }
        return rows
    }

    static func balanceURL(containerID: String?) -> URL {
        var query: [URLQueryItem] = []
        if let containerID, !containerID.isEmpty {
            query.append(URLQueryItem(name: "container_id", value: containerID))
        }
        return ProviderURL.https(
            host: apiHost,
            path: "/services/v2/finance/balance",
            query: query
        )
    }

    static func historyURL(containerID: String?, offset: Int) -> URL {
        var query: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "100"),
            URLQueryItem(name: "offset", value: "\(offset)"),
        ]
        if let containerID, !containerID.isEmpty {
            query.append(URLQueryItem(name: "filters[container_id]", value: containerID))
        }
        return ProviderURL.https(
            host: apiHost,
            path: "/services/v2/finance/balance-history",
            query: query
        )
    }

    struct Balance: Decodable, Sendable {
        var balance: FlexibleDecimal?
        var currency: String?
        var unpaid_invoice_balance: FlexibleDecimal?
    }

    struct HistoryList: Decodable, Sendable {
        var adjustments: [HistoryRow]?
    }

    struct HistoryRow: Decodable, Sendable {
        var credit: FlexibleDecimal?
        var debit: FlexibleDecimal?
        var currency: String?
        var transaction_type: String?
        var receipt_id: String?
        var transaction_date: String?
        var order_id: String?
    }
}
