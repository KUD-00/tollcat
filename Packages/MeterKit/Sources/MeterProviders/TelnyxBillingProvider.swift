import Foundation
import MeterCore

/// Telnyx 本月用量花费（跳过 `/v2/balance` 预充值）。
///
/// 文档：`GET /v2/usage_reports?product=&metrics=cost&dimensions=currency,date&date_range=…`
/// 认证：`Authorization: Bearer <API key>`。
///
/// 先 `GET /v2/usage_reports/options` 枚举产品，再对每个产品查 `metrics=cost`；
/// `currency` 维按目录汇率折。失败的产品跳过（权限/无用量）。
public struct TelnyxBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.telnyx }

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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .telnyx)
        let headers = [
            "Authorization": "Bearer \(apiKey)",
        ]
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let products = try await loadProducts(headers: headers)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var current: Decimal = 0

        let rangeStart = window.rfc3339(window.start)
        let rangeEnd = window.rfc3339(window.nextStart)

        for product in products {
            guard let rows = try? await loadCost(
                product: product,
                start: rangeStart,
                end: rangeEnd,
                headers: headers
            ) else { continue }
            for row in rows {
                try currencies.observe(row.currency, providerID: .telnyx)
                let amount = row.cost?.value ?? 0
                guard amount != 0 else { continue }
                current += amount
                let day = row.date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? window.start
                if window.contains(day) {
                    daily.add(day: calendar.startOfDay(for: day), amount: Money(usd: amount))
                }
                lines.add(
                    SpendLine(
                        category: product,
                        label: row.direction?.trimmed ?? product,
                        amountUSD: Money(usd: amount)
                    )
                )
            }
        }

        // History: one aggregated past-month pull is expensive per product; skip unless needed.
        if horizon == .availableHistory {
            // Keep current-month daily only; multi-product history would amplify API calls.
        }

        let converted = try currencies.convert(current, rates: rateSource.current, providerID: .telnyx)
        return Snapshot(
            providerID: .telnyx,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: converted.money,
            dailyUSD: currencies.scaled(daily.snapshotDaily, by: converted.usdPerUnit),
            converted: currencies.needsConversionNote ? converted : nil,
            lines: lines.snapshot
        )
    }

    private func loadProducts(headers: [String: String]) async throws -> [String] {
        let data = try await ProviderHTTP.get(
            url: Self.optionsURL,
            headers: headers,
            client: httpClient,
            providerID: .telnyx
        )
        let payload = try ProviderHTTP.decode(OptionsEnvelope.self, from: data, providerID: .telnyx)
        let names = (payload.data ?? []).compactMap { $0.product?.trimmed }
        // Prefer messaging + sip-trunking first (common $); then the rest.
        let preferred = ["messaging", "sip-trunking", "wireless", "call-control", "inference"]
        var ordered: [String] = []
        for p in preferred where names.contains(p) {
            ordered.append(p)
        }
        for n in names where !ordered.contains(n) {
            ordered.append(n)
        }
        // Cap to avoid rate limits on accounts with many products.
        return Array(ordered.prefix(12))
    }

    private func loadCost(
        product: String,
        start: String,
        end: String,
        headers: [String: String]
    ) async throws -> [UsageRow] {
        let url = ProviderURL.https(
            host: "api.telnyx.com",
            path: "/v2/usage_reports",
            query: [
                URLQueryItem(name: "product", value: product),
                URLQueryItem(name: "start_date", value: start),
                URLQueryItem(name: "end_date", value: end),
                URLQueryItem(name: "metrics", value: "cost"),
                URLQueryItem(name: "dimensions", value: "currency,date"),
                URLQueryItem(name: "page[number]", value: "1"),
                URLQueryItem(name: "page[size]", value: "100"),
            ]
        )
        let data = try await ProviderHTTP.get(
            url: url,
            headers: headers,
            client: httpClient,
            providerID: .telnyx
        )
        let payload = try ProviderHTTP.decode(UsageEnvelope.self, from: data, providerID: .telnyx)
        return payload.data ?? []
    }

    static let optionsURL = URL(string: "https://api.telnyx.com/v2/usage_reports/options")!

    struct OptionsEnvelope: Decodable, Sendable {
        var data: [ProductOptions]?
    }

    struct ProductOptions: Decodable, Sendable {
        var product: String?
        var product_metrics: [String]?
    }

    struct UsageEnvelope: Decodable, Sendable {
        var data: [UsageRow]?
    }

    struct UsageRow: Decodable, Sendable {
        var product: String?
        var currency: String?
        var date: String?
        var direction: String?
        var cost: FlexibleDecimal?
    }
}

private extension String {
    var trimmed: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
