import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore

/// DNScale DNS 账单（`GET /v1/billing/summary` + `/v1/billing/history`）。
///
/// 文档：https://dnscale.eu/api/billing
/// 认证：`Authorization: Bearer <API key>`（scope `billing:read`）。
/// Host：`api.dnscale.eu`。
/// 金额：`charges.total` + `charges.currency`（EUR）；历史 `amount` + `currency` + `period`。
/// 凭据：`apiToken`/`apiKey`。
public struct DNScaleBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.dnscale }
    public static let apiHost = "api.dnscale.eu"

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
        if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .dnscale) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiKey, in: credential, providerID: .dnscale)
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

        let summary = try await loadSummary(headers: headers)
        if let charges = summary.data?.charges {
            let amount = charges.total?.value ?? 0
            let code = (charges.currency ?? summary.data?.plan?.currency ?? "EUR")
                .trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            try currencies.observe(code.isEmpty ? "EUR" : code, providerID: .dnscale)
            if amount != 0 {
                currentTotal += amount
                daily.add(day: current.start, amount: Money(usd: amount))
                lines.add(
                    SpendLine(
                        category: "charges",
                        label: summary.data?.plan?.name ?? "summary",
                        amountUSD: Money(usd: amount)
                    )
                )
            }
        }

        if horizon == .availableHistory {
            let history = try await loadHistory(headers: headers)
            for item in history.data?.items ?? [] {
                let period = item.period ?? ""
                guard let stamp = Self.periodStart(period, calendar: calendar) else { continue }
                if current.contains(stamp) { continue }
                let amount = item.amount?.value ?? 0
                guard amount != 0 else { continue }
                let code = (item.currency ?? "EUR")
                    .trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                try currencies.observe(code.isEmpty ? "EUR" : code, providerID: .dnscale)
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
            providerID: .dnscale
        )
        return Snapshot(
            providerID: .dnscale,
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

    private func loadSummary(headers: [String: String]) async throws -> SummaryEnvelope {
        let data = try await ProviderHTTP.get(
            url: Self.summaryURL,
            headers: headers,
            client: httpClient,
            providerID: .dnscale
        )
        return try ProviderHTTP.decode(SummaryEnvelope.self, from: data, providerID: .dnscale)
    }

    private func loadHistory(headers: [String: String]) async throws -> HistoryEnvelope {
        let data = try await ProviderHTTP.get(
            url: Self.historyURL,
            headers: headers,
            client: httpClient,
            providerID: .dnscale
        )
        return try ProviderHTTP.decode(HistoryEnvelope.self, from: data, providerID: .dnscale)
    }

    static let summaryURL = ProviderURL.https(host: apiHost, path: "/v1/billing/summary")
    static let historyURL = ProviderURL.https(
        host: apiHost,
        path: "/v1/billing/history",
        query: [URLQueryItem(name: "limit", value: "24")]
    )

    static func periodStart(_ period: String, calendar: Calendar) -> Date? {
        let parts = period.split(separator: "-")
        guard parts.count >= 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              (1...12).contains(month)
        else { return nil }
        return calendar.date(from: DateComponents(year: year, month: month, day: 1))
    }

    struct SummaryEnvelope: Decodable, Sendable {
        var data: SummaryData?
    }

    struct SummaryData: Decodable, Sendable {
        var plan: Plan?
        var charges: Charges?
    }

    struct Plan: Decodable, Sendable {
        var name: String?
        var currency: String?
    }

    struct Charges: Decodable, Sendable {
        var total: FlexibleDecimal?
        var currency: String?
    }

    struct HistoryEnvelope: Decodable, Sendable {
        var data: HistoryData?
    }

    struct HistoryData: Decodable, Sendable {
        var items: [HistoryItem]?
    }

    struct HistoryItem: Decodable, Sendable {
        var id: String?
        var period: String?
        var amount: FlexibleDecimal?
        var currency: String?
        var status: String?
    }
}
