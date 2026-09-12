import Foundation
import MeterCore

/// Dynatrace Platform Subscription 成本：
/// `GET https://api.dynatrace.com/sub/v2/accounts/{accountUuid}/subscriptions/{subscriptionUuid}/cost`
/// → `data[].value` + `currencyCode`（scope: `account-uac-read`）。
///
/// 文档：https://docs.dynatrace.com/docs/dynatrace-api/account-management-api/dynatrace-platform-subscription-api/cost/get-cost
/// 认证：Bearer OAuth access token（client_credentials via sso.dynatrace.com）。
/// `accountID` = accountUuid；`projectID` = subscriptionUuid；
/// `clientID` + `clientSecret` 换 token，或直接给 `apiToken`。
public struct DynatraceBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.dynatrace }

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
        let token = try await accessToken(credential: credential)
        let accountUUID = try RequiredCredential.value(.accountID, in: credential, providerID: .dynatrace)
        let subscriptionUUID = try RequiredCredential.value(.projectID, in: credential, providerID: .dynatrace)
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let lookback = max(Self.descriptor.historyLookbackMonths, 1)
        let windowStart = horizon == .availableHistory
            ? (calendar.date(byAdding: .month, value: -lookback, to: current.start) ?? current.start)
            : current.start

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let url = ProviderURL.https(
            host: "api.dynatrace.com",
            path: "/sub/v2/accounts/\(accountUUID)/subscriptions/\(subscriptionUUID)/cost",
            query: [
                URLQueryItem(name: "startDate", value: formatter.string(from: windowStart)),
                URLQueryItem(name: "endDate", value: formatter.string(from: now)),
            ]
        )
        let data = try await ProviderHTTP.get(
            url: url, headers: headers, client: httpClient, providerID: .dynatrace
        )
        let payload = try ProviderHTTP.decode(CostResponse.self, from: data, providerID: .dynatrace)

        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        for row in payload.data ?? [] {
            let amount = row.value?.value ?? 0
            guard amount != 0 else { continue }
            try currencies.observe(row.currencyCode, providerID: .dynatrace)
            let stamp = row.date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? row.startDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            let label = row.capability ?? row.costType ?? "cost"
            if current.contains(stamp) {
                currentTotal += amount
                daily.add(day: stamp, amount: Money(usd: amount))
                lines.add(
                    SpendLine(
                        category: row.costType ?? "subscription",
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

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .dynatrace
        )
        return Snapshot(
            providerID: .dynatrace,
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

    private func accessToken(credential: Credential) async throws -> String {
        if let ready = credential.value(for: .apiToken)?
            .trimmingCharacters(in: .whitespacesAndNewlines), !ready.isEmpty
        {
            return ready
        }
        let clientID = try RequiredCredential.value(.clientID, in: credential, providerID: .dynatrace)
        let clientSecret = try RequiredCredential.value(.clientSecret, in: credential, providerID: .dynatrace)
        let body = Data(
            "grant_type=client_credentials&client_id=\(Self.formEncode(clientID))&client_secret=\(Self.formEncode(clientSecret))&scope=account-uac-read"
                .utf8
        )
        let url = ProviderURL.https(host: "sso.dynatrace.com", path: "/sso/oauth2/token")
        let data = try await ProviderHTTP.post(
            url: url,
            headers: [
                "Content-Type": "application/x-www-form-urlencoded",
                "Accept": "application/json",
            ],
            body: body,
            client: httpClient,
            providerID: .dynatrace
        )
        let token = try ProviderHTTP.decode(TokenResponse.self, from: data, providerID: .dynatrace)
        guard let access = token.access_token, !access.isEmpty else {
            throw ProviderError.unauthorized(providerID: .dynatrace)
        }
        return access
    }

    static func formEncode(_ value: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&=+")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }

    struct TokenResponse: Decodable, Sendable {
        var access_token: String?
        var expires_in: Int?
        var token_type: String?
    }

    struct CostResponse: Decodable, Sendable {
        var data: [CostRow]?
    }

    struct CostRow: Decodable, Sendable {
        var value: FlexibleDecimal?
        var currencyCode: String?
        var date: String?
        var startDate: String?
        var endDate: String?
        var capability: String?
        var costType: String?
    }
}
