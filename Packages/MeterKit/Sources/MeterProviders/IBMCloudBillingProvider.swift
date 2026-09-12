import Foundation
import MeterCore

/// IBM Cloud 本月用量花费（Usage Reports，非 SoftLayer Classic）。
///
/// 文档：`GET /v4/accounts/{account_id}/usage/{yyyy-mm}`
/// 认证：API Key → IAM token，再 Bearer。
///
/// 优先 `resources[].billable_cost`，缺省回退 `rated_cost` / `cost`；
/// `currency_code` 按目录汇率折。
public struct IBMCloudBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.ibm }

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
        let accountID = try RequiredCredential.value(.accountID, in: credential, providerID: .ibm)
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .ibm)
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let months = CalendarMonthWindow.months(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )

        let token = try await ProviderOAuth.clientCredentialsToken(
            url: Self.tokenURL,
            basic: nil,
            form: [
                "grant_type": "urn:ibm:params:oauth:grant-type:apikey",
                "apikey": apiKey,
            ],
            client: httpClient,
            providerID: .ibm
        )
        var currency = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0
        for month in months {
            let data: Data
            do {
                data = try await ProviderHTTP.get(
                    url: Self.usageURL(accountID: accountID, window: month, calendar: calendar),
                    headers: [
                        "Authorization": "Bearer \(token)",
                    ],
                    client: httpClient,
                    providerID: .ibm
                )
            } catch let error as ProviderError where error.code == .billingAPIUnavailable {
                if month.start == current.start { throw error }
                continue
            }
            let payload = try ProviderHTTP.decode(AccountUsage.self, from: data, providerID: .ibm)
            try currency.observe(payload.currency_code, providerID: .ibm)
            var total: Decimal = 0
            for resource in payload.resources ?? [] {
                let amount = resource.billable_cost?.value
                    ?? resource.rated_cost?.value
                    ?? resource.cost?.value
                    ?? 0
                guard amount != 0 else { continue }
                total += amount
                if month.start == current.start {
                    let label = resource.resource_name?.trimmed
                        ?? resource.resource_id?.trimmed
                        ?? "resource"
                    lines.add(
                        SpendLine(
                            category: "resource",
                            label: label,
                            amountUSD: Money(usd: amount)
                        )
                    )
                }
            }
            if month.start == current.start {
                currentTotal = total
            } else {
                daily.addPastMonth(
                    start: month.start,
                    amount: Money(usd: total),
                    current: current,
                    calendar: calendar
                )
            }
        }
        return try Snapshot(
            providerID: .ibm,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentTotal),
            dailyUSD: daily.snapshotDaily,
            lines: lines.snapshot
        ).convertedToUSD(using: currency, rates: rateSource.current)
    }

    static let tokenURL = URL(string: "https://iam.cloud.ibm.com/identity/token")!

    static func usageURL(
        accountID: String,
        window: CalendarMonthWindow,
        calendar: Calendar
    ) -> URL {
        let parts = calendar.dateComponents([.year, .month], from: window.start)
        let month = String(format: "%04d-%02d", parts.year ?? 0, parts.month ?? 0)
        return ProviderURL.https(
            host: "billing.cloud.ibm.com",
            path: "/v4/accounts/\(accountID)/usage/\(month)"
        )
    }

    struct AccountUsage: Decodable, Sendable {
        var account_id: String?
        var currency_code: String?
        var month: String?
        var resources: [Resource]?
    }

    struct Resource: Decodable, Sendable {
        var resource_id: String?
        var resource_name: String?
        var billable_cost: FlexibleDecimal?
        var rated_cost: FlexibleDecimal?
        var cost: FlexibleDecimal?
    }
}

private extension String {
    var trimmed: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
