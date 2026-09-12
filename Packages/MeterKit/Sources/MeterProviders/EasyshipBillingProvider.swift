import Foundation
import MeterCore

/// Easyship 本月账单文件合计。
///
/// 文档：`GET /2024-09/billing_documents`
/// 认证：`Authorization: Bearer <token>`，scope `public.billing_document:read`。
///
/// 按 `from_date`/`to_date` 拉本月文档，累加每份 `total` + `currency`（credit_note 等已为符号金额）。
public struct EasyshipBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.easyship }
    public static let maxPages = 20

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
        let now = now()
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .easyship)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var total = Decimal(0)
        var page = 1
        var pages = 0

        while pages < Self.maxPages {
            pages += 1
            let data = try await ProviderHTTP.get(
                url: Self.documentsURL(page: page, window: window),
                headers: [
                    "Authorization": "Bearer \(token)",
                ],
                client: httpClient,
                providerID: .easyship
            )
            let payload = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .easyship)
            let docs = payload.billing_documents ?? []
            for doc in docs {
                guard let amount = doc.total?.value else { continue }
                try currencies.observe(doc.currency, providerID: .easyship)
                total += amount
            }
            let next = payload.meta?.pagination?.next
            if docs.isEmpty || next == nil { break }
            page = next ?? (page + 1)
        }

        let converted = try currencies.convert(total, rates: rateSource.current, providerID: .easyship)
        return Snapshot(
            providerID: .easyship,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: converted.money,
            converted: currencies.needsConversionNote ? converted : nil
        )
    }

    static func documentsURL(page: Int, window: CalendarMonthWindow) -> URL {
        let fmt = DateFormatter()
        fmt.calendar = Calendar(identifier: .gregorian)
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone(secondsFromGMT: 0)
        fmt.dateFormat = "yyyy-MM-dd"
        return ProviderURL.https(
            host: "public-api.easyship.com",
            path: "/2024-09/billing_documents",
            query: [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "per_page", value: "100"),
                URLQueryItem(name: "from_date", value: fmt.string(from: window.start)),
                URLQueryItem(name: "to_date", value: fmt.string(from: window.endInclusive)),
            ]
        )
    }

    struct Envelope: Decodable, Sendable {
        var billing_documents: [Document]?
        var meta: Meta?
    }

    struct Meta: Decodable, Sendable {
        var pagination: Pagination?
    }

    struct Pagination: Decodable, Sendable {
        var page: Int?
        var next: Int?
    }

    struct Document: Decodable, Sendable {
        var id: String?
        var type: String?
        var currency: String?
        var total: FlexibleDecimal?
    }
}
