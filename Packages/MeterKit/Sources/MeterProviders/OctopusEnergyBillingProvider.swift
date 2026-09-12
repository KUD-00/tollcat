import Foundation
import MeterCore

/// Octopus Energy GraphQL：`costOfUsage` 周期上的 `currency` + `totalCost`（CostOfUsagePeriod；
/// 金额为最小货币单位，如 GBP pence）；亦接受 `EstimatedMoneyType.costCurrency` + `estimatedAmount`。
///
/// 文档：https://developer.octopus.energy/graphql/reference/objects/costofusageperiod/
/// 认证：Bearer API key。Host：`api.octopus.energy`。
/// `accountID` = Octopus 账号号（如 A-XXXX）。
public struct OctopusEnergyBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.octopusenergy }

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
        let token = try RequiredCredential.value(.apiKey, in: credential, providerID: .octopusenergy)
        let account = try RequiredCredential.value(.accountID, in: credential, providerID: .octopusenergy)
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let lookback = max(Self.descriptor.historyLookbackMonths, 1)
        let start = horizon == .availableHistory
            ? (calendar.date(byAdding: .month, value: -lookback, to: current.start) ?? current.start)
            : current.start
        let startISO = ISO8601DateFormatter().string(from: start)

        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        for fuel in ["ELECTRICITY", "GAS"] {
            let payload = try await ProviderGraphQL.query(
                CostRoot.self,
                url: Self.graphqlURL,
                query: Self.costQuery,
                variables: [
                    "accountNumber": account,
                    "fuelType": fuel,
                    "grouping": "DAY",
                    "startAt": startISO,
                ],
                headers: headers,
                client: httpClient,
                providerID: .octopusenergy
            )
            guard payload.costOfUsage?.costEnabled != false else { continue }
            for edge in payload.costOfUsage?.details?.edges ?? [] {
                guard let node = edge.node else { continue }
                let currency = node.currency
                    ?? node.costExclTax?.costCurrency
                    ?? node.costInclTax?.costCurrency
                let rawMinor = node.totalCost?.value
                    ?? node.costExclTax?.estimatedAmount?.value
                    ?? node.costInclTax?.estimatedAmount?.value
                    ?? node.cost?.value
                guard let raw = rawMinor, raw != 0 else { continue }
                try currencies.observe(currency, providerID: .octopusenergy)
                let amount = Self.majorUnits(raw, currency: currency ?? "GBP")
                let stamp = node.period?.start.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? node.startAt.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                if current.contains(stamp) {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: fuel.lowercased(),
                            label: fuel.lowercased(),
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
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .octopusenergy
        )
        return Snapshot(
            providerID: .octopusenergy,
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

    /// CostOfUsagePeriod.totalCost / EstimatedMoneyType.estimatedAmount 为最小货币单位。
    static func majorUnits(_ minor: Decimal, currency: String) -> Decimal {
        let zeroDecimal: Set<String> = ["JPY", "KRW", "VND", "CLP", "ISK", "UGX", "XAF", "XOF", "XPF"]
        if zeroDecimal.contains(currency.uppercased()) { return minor }
        return minor / 100
    }

    static let graphqlURL = ProviderURL.https(host: "api.octopus.energy", path: "/v1/graphql/")

    static let costQuery = """
    query CostOfUsage(
      $accountNumber: String,
      $fuelType: FuelType,
      $grouping: ConsumptionGroupings!,
      $startAt: DateTime
    ) {
      costOfUsage(
        accountNumber: $accountNumber,
        fuelType: $fuelType,
        grouping: $grouping,
        startAt: $startAt
      ) {
        costEnabled
        details {
          edges {
            node {
              ... on CostOfUsagePeriod {
                currency
                totalCost
                period { start end }
              }
              ... on IntervalCostOfUsageType {
                cost
                startAt
                endAt
              }
            }
          }
        }
      }
    }
    """

    struct CostRoot: Decodable, Sendable {
        var costOfUsage: CostOfUsage?
    }

    struct CostOfUsage: Decodable, Sendable {
        var costEnabled: Bool?
        var details: Connection?
    }

    struct Connection: Decodable, Sendable {
        var edges: [Edge]?
    }

    struct Edge: Decodable, Sendable {
        var node: Node?
    }

    struct Node: Decodable, Sendable {
        var currency: String?
        var totalCost: FlexibleDecimal?
        var cost: FlexibleDecimal?
        var startAt: String?
        var endAt: String?
        var period: Period?
        var costExclTax: EstimatedMoney?
        var costInclTax: EstimatedMoney?
    }

    struct Period: Decodable, Sendable {
        var start: String?
        var end: String?
    }

    struct EstimatedMoney: Decodable, Sendable {
        var costCurrency: String?
        var estimatedAmount: FlexibleDecimal?
    }
}
