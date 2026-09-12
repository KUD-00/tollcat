import Foundation
import MeterCore

/// MySendingBox 本月信件费用合计。
///
/// 文档：`GET /letters`
/// 认证：HTTP Basic（API key 作用户名，密码空）。
///
/// `price.total` 是欧元；按 `created_at` 落在本月的信件相加。
public struct MySendingBoxBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.mysendingbox }
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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .mysendingbox)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let auth = "Basic \(ProviderOAuth.basicValue(id: apiKey, secret: String()))"
        var total = Decimal(0)
        var page = 1
        var pages = 0

        while pages < Self.maxPages {
            pages += 1
            let data = try await ProviderHTTP.get(
                url: Self.lettersURL(page: page, window: window),
                headers: ["Authorization": auth],
                client: httpClient,
                providerID: .mysendingbox
            )
            let payload = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .mysendingbox)
            let letters = payload.letters ?? payload.data ?? []
            for letter in letters {
                let day = letter.created_at.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                if let day, day < window.start || day >= window.nextStart { continue }
                total += letter.price?.total?.value ?? 0
            }
            if letters.isEmpty { break }
            page += 1
            if letters.count < 10 { break }
        }

        let converted = try BillingCurrency.convert(
            total,
            currency: "EUR",
            rates: rateSource.current,
            providerID: .mysendingbox
        )
        return Snapshot(
            providerID: .mysendingbox,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: converted.money,
            converted: converted.isConverted ? converted : nil
        )
    }

    static func lettersURL(page: Int, window: CalendarMonthWindow) -> URL {
        let fmt = ISO8601DateFormatter()
        return ProviderURL.https(
            host: "api.mysendingbox.fr",
            path: "/letters",
            query: [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "created_at[gt]", value: fmt.string(from: window.start)),
                URLQueryItem(name: "created_at[lt]", value: fmt.string(from: window.nextStart)),
            ]
        )
    }

    struct Envelope: Decodable, Sendable {
        var letters: [Letter]?
        var data: [Letter]?
    }

    struct Letter: Decodable, Sendable {
        var id: String?
        var created_at: String?
        var price: Price?
    }

    struct Price: Decodable, Sendable {
        var total: FlexibleDecimal?
    }
}
