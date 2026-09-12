import Foundation
import MeterCore

/// Azure 订阅本月至今成本，日粒度。
///
/// 文档：`POST /subscriptions/{id}/providers/Microsoft.CostManagement/query`
/// 认证：Entra 服务主体 `client_credentials`，scope 是 `https://management.azure.com/.default`。
/// 服务主体要在订阅上有 Cost Management Reader。
///
/// 这是 A 档之外唯一给完整日线的一家。代价是四个凭据字段和两段鉴权。
/// Azure 的账单数据有 8–24 小时延迟，今天那一格偏小是正常的，不是取数错。
public struct AzureBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.azure }
    public static let apiVersion = "2025-03-01"
    public static let scope = "https://management.azure.com/.default"

    /// 不同计费账户类型下成本列名不一样，按优先级认。
    static let costColumnNames = ["Cost", "PreTaxCost", "CostUSD", "PreTaxCostUSD"]

    public var httpClient: any HTTPClient
    public var now: @Sendable () -> Date
    public var calendar: Calendar
    /// 厂商用非美元结算时按这张表换。默认只认美元，行为和加它之前一样。
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
        let tenantID = try RequiredCredential.value(.tenantID, in: credential, providerID: .azure)
        let clientID = try RequiredCredential.value(.clientID, in: credential, providerID: .azure)
        let clientSecret = try RequiredCredential.value(.clientSecret, in: credential, providerID: .azure)
        let subscriptionID = try RequiredCredential.value(.accountID, in: credential, providerID: .azure)

        let token = try await ProviderOAuth.clientCredentialsToken(
            url: Self.tokenURL(tenantID: tenantID),
            basic: nil,
            form: [
                "grant_type": "client_credentials",
                "client_id": clientID,
                "client_secret": clientSecret,
                "scope": Self.scope,
            ],
            client: httpClient,
            providerID: .azure
        )
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let months = CalendarMonthWindow.months(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        var currency = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        for month in months {
            let data = try await ProviderHTTP.post(
                url: Self.queryURL(subscriptionID: subscriptionID),
                headers: [
                    "Authorization": "Bearer \(token)",
                    "Content-Type": "application/json",
                ],
                body: month.start == current.start && horizon == .currentMonth
                    ? Self.queryBody
                    : Self.customDailyBody(window: month, calendar: calendar),
                client: httpClient,
                providerID: .azure
            )
            let payload = try ProviderHTTP.decode(QueryResult.self, from: data, providerID: .azure)
            let piece = try Self.accumulate(
                payload.properties,
                window: month,
                calendar: calendar,
                currency: &currency
            )
            for (day, amount) in piece.snapshotDaily ?? [:] {
                daily.add(day: day, amount: amount)
            }
        }

        return try Snapshot(
            providerID: .azure,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: daily.total(in: current, calendar: calendar),
            dailyUSD: daily.snapshotDaily ?? [:]
        ).convertedToUSD(using: currency, rates: rateSource.current)
    }

    /// `rows` 的值顺序跟着 `columns` 走，只能按列名找下标，不能写死位置。
    static func accumulate(
        _ properties: Properties?,
        window: CalendarMonthWindow,
        calendar: Calendar,
        currency: inout CurrencyAccumulator
    ) throws -> DailySpendAccumulator {
        var daily = DailySpendAccumulator()
        guard let properties, let columns = properties.columns else { return daily }

        let names = columns.map { $0.name ?? "" }
        guard let costIndex = costColumnNames.lazy.compactMap({ names.firstIndex(of: $0) }).first else {
            throw ProviderError.malformedResponse(providerID: .azure)
        }
        let dateIndex = names.firstIndex(of: "UsageDate")
        let currencyIndex = names.firstIndex(of: "Currency")

        for row in properties.rows ?? [] {
            if let currencyIndex, currencyIndex < row.count {
                try currency.observe(row[currencyIndex].stringValue, providerID: .azure)
            }
            guard costIndex < row.count, let cost = row[costIndex].decimalValue, cost != 0 else { continue }
            let day = dateIndex
                .flatMap { $0 < row.count ? row[$0].compactDateValue(calendar: calendar) : nil }
                ?? window.start
            guard window.contains(day) else { continue }
            daily.add(day: day, amount: Money(usd: cost))
        }
        return daily
    }

    static func tokenURL(tenantID: String) -> URL {
        return ProviderURL.https(host: "login.microsoftonline.com", path: "/\(tenantID)/oauth2/v2.0/token")
    }

    static func queryURL(subscriptionID: String) -> URL {
        return ProviderURL.https(
            host: "management.azure.com",
            path: "/subscriptions/\(subscriptionID)/providers/Microsoft.CostManagement/query",
            query: [URLQueryItem(name: "api-version", value: apiVersion)]
        )
    }

    /// 固定的只读查询：本月至今、按天、只要总成本。写死成字面量，省得每次拼 JSON。
    static let queryBody = Data("""
    {"type":"ActualCost","timeframe":"MonthToDate","dataset":{"granularity":"Daily",\
    "aggregation":{"totalCost":{"name":"Cost","function":"Sum"}}}}
    """.utf8)

    /// Daily 最长 31 天，历史按月一段一段问。
    static func customDailyBody(window: CalendarMonthWindow, calendar: Calendar) -> Data {
        let from = window.dayString(window.start, calendar: calendar)
        let to = window.dayString(window.endInclusive, calendar: calendar)
        return Data("""
        {"type":"ActualCost","timeframe":"Custom","timePeriod":{"from":"\(from)","to":"\(to)"},\
        "dataset":{"granularity":"Daily","aggregation":{"totalCost":{"name":"Cost","function":"Sum"}}}}
        """.utf8)
    }

    struct QueryResult: Decodable, Sendable {
        var properties: Properties?
    }

    struct Properties: Decodable, Sendable {
        var columns: [Column]?
        var rows: [[Cell]]?
    }

    struct Column: Decodable, Sendable {
        var name: String?
        var type: String?
    }

    /// 一行里数字和字符串混着来，用一个宽松的单元格类型收。
    enum Cell: Decodable, Sendable {
        case number(Decimal)
        case text(String)
        case none

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if container.decodeNil() {
                self = .none
            } else if let int = try? container.decode(Int64.self) {
                self = .number(Decimal(int))
            } else if let double = try? container.decode(Double.self) {
                var raw = Decimal(double)
                var rounded = Decimal()
                NSDecimalRound(&rounded, &raw, 8, .plain)
                self = .number(rounded)
            } else if let string = try? container.decode(String.self) {
                self = .text(string)
            } else {
                self = .none
            }
        }

        var decimalValue: Decimal? {
            switch self {
            case .number(let value): value
            case .text(let raw): Decimal(string: raw, locale: Locale(identifier: "en_US_POSIX"))
            case .none: nil
            }
        }

        var stringValue: String? {
            switch self {
            case .text(let raw): raw
            case .number, .none: nil
            }
        }

        /// `UsageDate` 是 `20260817` 这种紧凑数字，不是 ISO 串。
        func compactDateValue(calendar: Calendar) -> Date? {
            let raw: String
            switch self {
            case .number(let value): raw = NSDecimalNumber(decimal: value).stringValue
            case .text(let text): raw = text
            case .none: return nil
            }
            guard raw.count == 8, let packed = Int(raw) else {
                return BillingDateParser.parse(raw, calendar: calendar)
            }
            return calendar.date(from: DateComponents(
                year: packed / 10000,
                month: (packed / 100) % 100,
                day: packed % 100
            ))
        }
    }
}
