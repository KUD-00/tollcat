import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore

/// Shipmondo 账户流水扣费（`GET /api/public/v3/user_ledger_entries`）。
///
/// 文档：https://shipmondo.dev/api-reference#/operations/user_ledger_entries_get
/// OpenAPI：https://app.shipmondo.com/api/public/v3/elements.json
/// 认证：HTTP Basic（API User + API Key；Settings → Integrations → API）。
/// Host：`app.shipmondo.com`。
/// 金额：`amount` + `currency_code`（ISO 4217）同资源。
/// 只计 `source_type=sales_document` 扣费（负金额取绝对值）；忽略 `transaction` 充值/回款（prepaid）。
/// 凭据：`email`/`clientID`/`accountID` = API User，`apiKey`/`apiToken`/`clientSecret` = API Key。
public struct ShipmondoBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.shipmondo }
    public static let apiHost = "app.shipmondo.com"
    static let maxPages = 40
    static let pageSize = 50

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
        let username: String
        if let primary = try? RequiredCredential.value(.email, in: credential, providerID: .shipmondo) {
            username = primary
        } else if let primary = try? RequiredCredential.value(.clientID, in: credential, providerID: .shipmondo) {
            username = primary
        } else {
            username = try RequiredCredential.value(.accountID, in: credential, providerID: .shipmondo)
        }
        let password: String
        if let primary = try? RequiredCredential.value(.apiKey, in: credential, providerID: .shipmondo) {
            password = primary
        } else if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .shipmondo) {
            password = primary
        } else {
            password = try RequiredCredential.value(.clientSecret, in: credential, providerID: .shipmondo)
        }
        let headers = [
            "Authorization": "Basic \(ProviderOAuth.basicValue(id: username, secret: password))",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let from: Date
        let to: Date
        if horizon == .availableHistory {
            let lookback = max(1, Self.descriptor.historyLookbackMonths)
            from = calendar.date(byAdding: .month, value: -(lookback - 1), to: current.start) ?? current.start
            to = current.endInclusive
        } else {
            from = current.start
            to = current.endInclusive
        }

        var page = 1
        var pages = 0
        while pages < Self.maxPages {
            pages += 1
            let batch = try await loadEntries(from: from, to: to, page: page, headers: headers)
            if batch.isEmpty { break }
            for entry in batch {
                let source = (entry.sourceType ?? "").lowercased()
                if source == "transaction" { continue }
                let raw = entry.amount?.value ?? 0
                // 扣费为负；忽略充值正数。
                guard raw < 0 else { continue }
                let amount = abs(raw)
                let currency = entry.currencyCode?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .uppercased()
                guard let currency, !currency.isEmpty else { continue }
                try currencies.observe(currency, providerID: .shipmondo)
                let stamp = entry.createdAt.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                let label = entry.description
                    ?? entry.referenceId.map { "\($0)" }
                    ?? entry.id.map { "\($0)" }
                    ?? "charge"
                if current.contains(stamp) {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: entry.referenceType ?? source.nonEmpty ?? "sales_document",
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
            page += 1
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .shipmondo
        )
        return Snapshot(
            providerID: .shipmondo,
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

    private func loadEntries(
        from: Date,
        to: Date,
        page: Int,
        headers: [String: String]
    ) async throws -> [LedgerEntry] {
        let data = try await ProviderHTTP.get(
            url: Self.entriesURL(from: from, to: to, page: page),
            headers: headers,
            client: httpClient,
            providerID: .shipmondo
        )
        if let list = try? ProviderHTTP.decode([LedgerEntry].self, from: data, providerID: .shipmondo) {
            return list
        }
        let envelope = try ProviderHTTP.decode(LedgerList.self, from: data, providerID: .shipmondo)
        return envelope.entries ?? envelope.data ?? envelope.items ?? []
    }

    static func entriesURL(from: Date, to: Date, page: Int) -> URL {
        var components = URLComponents(
            url: ProviderURL.https(host: apiHost, path: "/api/public/v3/user_ledger_entries"),
            resolvingAgainstBaseURL: false
        )!
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        components.queryItems = [
            URLQueryItem(name: "created_at_min", value: formatter.string(from: from)),
            URLQueryItem(name: "created_at_max", value: formatter.string(from: to)),
            URLQueryItem(name: "source_type", value: "sales_document"),
            URLQueryItem(name: "per_page", value: String(pageSize)),
            URLQueryItem(name: "page", value: String(page)),
        ]
        return components.url!
    }

    struct LedgerList: Decodable, Sendable {
        var entries: [LedgerEntry]?
        var data: [LedgerEntry]?
        var items: [LedgerEntry]?
    }

    struct LedgerEntry: Decodable, Sendable {
        var id: Int?
        var createdAt: String?
        var amount: FlexibleDecimal?
        var currencyCode: String?
        var balance: FlexibleDecimal?
        var description: String?
        var referenceType: String?
        var referenceId: Int?
        var sourceType: String?
        var settlementId: Int?

        enum CodingKeys: String, CodingKey {
            case id
            case createdAt = "created_at"
            case amount
            case currencyCode = "currency_code"
            case balance
            case description
            case referenceType = "reference_type"
            case referenceId = "reference_id"
            case sourceType = "source_type"
            case settlementId = "settlement_id"
        }
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
