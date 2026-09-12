import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore

/// Make（原 Integromat）组织付款记录（`GET /organizations/{id}/payments`）。
///
/// 文档：https://developers.make.com/api-documentation/api-reference/organizations
/// 认证：API Token，`Authorization: Token …`（`apiToken` / `apiKey`）。
/// Host：区站 `eu1|eu2|us1|us2.make.com`（`tenantID` 选区，默认 `eu1`）。
/// 凭据：`accountID` = organizationId。
/// 金额：同资源 `amount_total` + `currency_code`（主单位）；按 `period_from`/`created` 落入当月。
public struct MakeBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.make }
    public static let defaultZone = "eu1"
    public static let pageLimit = 100
    public static let maxPages = 40

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
        if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .make) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiKey, in: credential, providerID: .make)
        }
        let organizationID = try RequiredCredential.value(.accountID, in: credential, providerID: .make)
        let zone = Self.zone(for: credential.value(for: .tenantID))
        let host = Self.host(for: zone)
        let headers = [
            "Authorization": "Token \(token)",
            "Accept": "application/json",
        ]

        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let from: Date
        if horizon == .availableHistory {
            let lookback = max(1, Self.descriptor.historyLookbackMonths)
            from = calendar.date(byAdding: .month, value: -(lookback - 1), to: current.start) ?? current.start
        } else {
            from = current.start
        }

        var offset = 0
        var pages = 0
        while pages < Self.maxPages {
            pages += 1
            let page = try await loadPage(
                host: host,
                organizationID: organizationID,
                offset: offset,
                headers: headers
            )
            let batch = page.payments ?? []
            if batch.isEmpty { break }
            var reachedOlder = false
            for payment in batch {
                let stamp = Self.stamp(for: payment, calendar: calendar) ?? current.start
                if stamp < from {
                    reachedOlder = true
                    continue
                }
                let currency = payment.currency_code?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .uppercased()
                guard let currency, !currency.isEmpty else { continue }
                let amount = payment.amount_total?.value ?? 0
                guard amount != 0 else { continue }
                try currencies.observe(currency, providerID: .make)

                let label = [
                    payment.invoice_number.map(String.init),
                    payment.type_name,
                    payment.id,
                ]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first { !$0.isEmpty } ?? "payment"
                let category = payment.type_name?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .nonEmpty
                    ?? payment.status_name?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .nonEmpty
                    ?? "payment"

                if current.contains(stamp) {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: category,
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
            if reachedOlder { break }
            if batch.count < Self.pageLimit { break }
            offset += batch.count
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .make
        )
        return Snapshot(
            providerID: .make,
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

    static func zone(for raw: String?) -> String {
        let value = raw?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            ?? ""
        switch value {
        case "eu1", "eu2", "us1", "us2":
            return value
        case "celonis-eu1", "celonis", "make.celonis.com", "eu1.make.celonis.com":
            return "celonis-eu1"
        case "celonis-us1", "us1.make.celonis.com":
            return "celonis-us1"
        case "eu", "europe", "":
            return defaultZone
        case "us", "usa", "united states":
            return "us1"
        default:
            if value.contains("celonis") {
                return value.contains("us") ? "celonis-us1" : "celonis-eu1"
            }
            if value.hasPrefix("eu2") { return "eu2" }
            if value.hasPrefix("us2") { return "us2" }
            if value.hasPrefix("us") { return "us1" }
            return defaultZone
        }
    }

    static func host(for zone: String) -> String {
        switch zone {
        case "celonis-eu1":
            return "eu1.make.celonis.com"
        case "celonis-us1":
            return "us1.make.celonis.com"
        default:
            return "\(zone).make.com"
        }
    }

    static func paymentsURL(host: String, organizationID: String, offset: Int) -> URL {
        ProviderURL.https(
            host: host,
            path: "/api/v2/organizations/\(organizationID)/payments",
            query: [
                URLQueryItem(name: "pg[limit]", value: String(pageLimit)),
                URLQueryItem(name: "pg[offset]", value: String(offset)),
                URLQueryItem(name: "pg[sortBy]", value: "created"),
                URLQueryItem(name: "pg[sortDir]", value: "desc"),
            ]
        )
    }

    static func stamp(for payment: Payment, calendar: Calendar) -> Date? {
        if let from = payment.period_from.flatMap({ BillingDateParser.parse($0, calendar: calendar) }) {
            return from
        }
        return payment.created.flatMap { BillingDateParser.parse($0, calendar: calendar) }
    }

    private func loadPage(
        host: String,
        organizationID: String,
        offset: Int,
        headers: [String: String]
    ) async throws -> Envelope {
        let data = try await ProviderHTTP.get(
            url: Self.paymentsURL(host: host, organizationID: organizationID, offset: offset),
            headers: headers,
            client: httpClient,
            providerID: .make
        )
        return try ProviderHTTP.decode(Envelope.self, from: data, providerID: .make)
    }

    struct Envelope: Decodable, Sendable {
        var payments: [Payment]?
    }

    struct Payment: Decodable, Sendable {
        var id: String?
        var invoice_number: Int?
        var created: String?
        var type_name: String?
        var status_name: String?
        var amount_total: FlexibleDecimal?
        var currency_code: String?
        var period_from: String?
        var period_to: String?
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
