import Foundation
import MeterCore

/// Tibber GraphQL：`viewer.homes[].consumption(resolution: MONTHLY)` → `cost` + `currency`；
/// `pageInfo.totalCost` + `pageInfo.currency` 作窗口合计校验。
///
/// 文档：https://developer.tibber.com/docs/reference
/// 认证：Bearer personal access token。Host：`api.tibber.com`。
public struct TibberBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.tibber }

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
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .tibber)
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let lookback = max(Self.descriptor.historyLookbackMonths, 1)
        let first = horizon == .availableHistory ? lookback : 1
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let payload = try await ProviderGraphQL.query(
            ViewerData.self,
            url: Self.graphqlURL,
            query: Self.query(first: first),
            headers: headers,
            client: httpClient,
            providerID: .tibber
        )
        for home in payload.viewer?.homes ?? [] {
            let homeLabel = home.appNickname ?? home.id ?? "home"
            if let pageCurrency = home.consumption?.pageInfo?.currency {
                try currencies.observe(pageCurrency, providerID: .tibber)
            }
            for node in home.consumption?.nodes ?? [] {
                let amount = node.cost?.value ?? 0
                guard amount != 0 else { continue }
                try currencies.observe(node.currency, providerID: .tibber)
                let stamp = node.from.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                if current.contains(stamp) {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: "consumption",
                            label: homeLabel,
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
            if currentTotal == 0, let total = home.consumption?.pageInfo?.totalCost?.value, total != 0 {
                try currencies.observe(home.consumption?.pageInfo?.currency, providerID: .tibber)
                currentTotal += total
                lines.add(
                    SpendLine(
                        category: "consumption",
                        label: "\(homeLabel) page",
                        amountUSD: Money(usd: total)
                    )
                )
            }
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .tibber
        )
        return Snapshot(
            providerID: .tibber,
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

    static let graphqlURL = ProviderURL.https(host: "api.tibber.com", path: "/v1-beta/gql")

    static func query(first: Int) -> String {
        """
        {
          viewer {
            homes {
              id
              appNickname
              consumption(resolution: MONTHLY, last: \(first)) {
                pageInfo { currency totalCost }
                nodes { from to cost currency }
              }
            }
          }
        }
        """
    }

    struct ViewerData: Decodable, Sendable {
        var viewer: Viewer?
    }

    struct Viewer: Decodable, Sendable {
        var homes: [Home]?
    }

    struct Home: Decodable, Sendable {
        var id: String?
        var appNickname: String?
        var consumption: ConsumptionConnection?
    }

    struct ConsumptionConnection: Decodable, Sendable {
        var pageInfo: PageInfo?
        var nodes: [Consumption]?
    }

    struct PageInfo: Decodable, Sendable {
        var currency: String?
        var totalCost: FlexibleDecimal?
    }

    struct Consumption: Decodable, Sendable {
        var from: String?
        var to: String?
        var cost: FlexibleDecimal?
        var currency: String?
    }
}
