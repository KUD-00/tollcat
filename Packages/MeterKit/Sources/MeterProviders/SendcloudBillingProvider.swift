import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore

/// Sendcloud 买方发票（`GET /api/v3/invoices`）。
///
/// 文档：https://sendcloud.dev/api/v3/invoices/retrieve-a-list-of-invoices
/// OpenAPI：https://sendcloud.dev/.openapi/v3/invoices/openapi.yaml
/// 认证：HTTP Basic（Public Key + Private Key；Settings → Integrations）。
/// Host：`panel.sendcloud.sc`。
/// 金额：`price_taxable` / `price_non_taxable` / `tax` 同资源 `{value,currency}`（ISO 4217）；
/// 合计 = 三者 value 之和（含税应付）。
/// 类别：`subscription` + `transactional` 均为买方账单，无 prepaid 充值字段可跳。
/// 凭据：`apiKey`/`clientID`/`accessKeyID`/`accountID`/`email` = Public Key，
/// `clientSecret`/`secretAccessKey`/`apiToken` = Private Key。
public struct SendcloudBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.sendcloud }
    public static let apiHost = "panel.sendcloud.sc"
    static let maxPages = 40
    static let pageSize = 100

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
        let publicKey: String
        if let primary = try? RequiredCredential.value(.apiKey, in: credential, providerID: .sendcloud) {
            publicKey = primary
        } else if let primary = try? RequiredCredential.value(.clientID, in: credential, providerID: .sendcloud) {
            publicKey = primary
        } else if let primary = try? RequiredCredential.value(.accessKeyID, in: credential, providerID: .sendcloud) {
            publicKey = primary
        } else if let primary = try? RequiredCredential.value(.accountID, in: credential, providerID: .sendcloud) {
            publicKey = primary
        } else {
            publicKey = try RequiredCredential.value(.email, in: credential, providerID: .sendcloud)
        }
        let privateKey: String
        if let primary = try? RequiredCredential.value(.clientSecret, in: credential, providerID: .sendcloud) {
            privateKey = primary
        } else if let primary = try? RequiredCredential.value(.secretAccessKey, in: credential, providerID: .sendcloud) {
            privateKey = primary
        } else {
            privateKey = try RequiredCredential.value(.apiToken, in: credential, providerID: .sendcloud)
        }
        let headers = [
            "Authorization": "Basic \(ProviderOAuth.basicValue(id: publicKey, secret: privateKey))",
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

        var cursor: String?
        var pages = 0
        while pages < Self.maxPages {
            pages += 1
            let page = try await loadInvoices(cursor: cursor, headers: headers)
            if page.invoices.isEmpty { break }
            var reachedOlder = false
            for inv in page.invoices {
                let stamp = inv.createdAt.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? inv.dueDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                if stamp < from {
                    reachedOlder = true
                    continue
                }
                let amount = inv.totalAmount
                guard amount != 0 else { continue }
                let currency = inv.currencyCode
                guard let currency, !currency.isEmpty else { continue }
                try currencies.observe(currency, providerID: .sendcloud)
                let label = inv.reference
                    ?? inv.description
                    ?? inv.id.map { "\($0)" }
                    ?? "invoice"
                let category = inv.category?.nonEmpty ?? "invoice"
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
            guard let next = page.nextCursor, !next.isEmpty, next != cursor else { break }
            cursor = next
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .sendcloud
        )
        return Snapshot(
            providerID: .sendcloud,
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

    private func loadInvoices(
        cursor: String?,
        headers: [String: String]
    ) async throws -> (invoices: [Invoice], nextCursor: String?) {
        let url = Self.invoicesURL(cursor: cursor)
        let (data, response) = try await ProviderHTTP.getResponse(
            url: url,
            headers: headers,
            client: httpClient,
            providerID: .sendcloud
        )
        let envelope = try ProviderHTTP.decode(InvoiceList.self, from: data, providerID: .sendcloud)
        let invoices = envelope.data ?? []
        return (invoices, Self.nextCursor(from: response))
    }

    static func invoicesURL(cursor: String?) -> URL {
        var components = URLComponents(
            url: ProviderURL.https(host: apiHost, path: "/api/v3/invoices"),
            resolvingAgainstBaseURL: false
        )!
        var items = [
            URLQueryItem(name: "page_size", value: String(pageSize)),
        ]
        if let cursor, !cursor.isEmpty {
            items.append(URLQueryItem(name: "cursor", value: cursor))
        }
        components.queryItems = items
        return components.url!
    }

    /// RFC8288 `Link: <url>; rel="next"` → cursor query value.
    static func nextCursor(from response: HTTPURLResponse) -> String? {
        let header = response.value(forHTTPHeaderField: "Link")
            ?? response.value(forHTTPHeaderField: "link")
        guard let header, !header.isEmpty else { return nil }
        for part in header.split(separator: ",") {
            let segment = part.trimmingCharacters(in: .whitespacesAndNewlines)
            guard segment.lowercased().contains("rel=\"next\"")
                || segment.lowercased().contains("rel=next")
            else { continue }
            guard let start = segment.firstIndex(of: "<"),
                  let end = segment.firstIndex(of: ">"),
                  start < end
            else { continue }
            let urlString = String(segment[segment.index(after: start)..<end])
            guard let url = URL(string: urlString),
                  let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let cursor = comps.queryItems?.first(where: { $0.name == "cursor" })?.value,
                  !cursor.isEmpty
            else { continue }
            return cursor
        }
        return nil
    }

    struct InvoiceList: Decodable, Sendable {
        var data: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var id: Int?
        var reference: String?
        var createdAt: String?
        var dueDate: String?
        var priceTaxable: Price?
        var priceNonTaxable: Price?
        var tax: Price?
        var description: String?
        var category: String?

        enum CodingKeys: String, CodingKey {
            case id
            case reference
            case createdAt = "created_at"
            case dueDate = "due_date"
            case priceTaxable = "price_taxable"
            case priceNonTaxable = "price_non_taxable"
            case tax
            case description
            case category
        }

        var totalAmount: Decimal {
            (priceTaxable?.value?.value ?? 0)
                + (priceNonTaxable?.value?.value ?? 0)
                + (tax?.value?.value ?? 0)
        }

        var currencyCode: String? {
            let raw = priceTaxable?.currency
                ?? priceNonTaxable?.currency
                ?? tax?.currency
            guard let raw else { return nil }
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            return trimmed.isEmpty ? nil : trimmed
        }
    }

    struct Price: Decodable, Sendable {
        var value: FlexibleDecimal?
        var currency: String?
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
