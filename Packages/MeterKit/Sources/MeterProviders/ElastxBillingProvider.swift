import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore

/// Elastx OpenStack CloudKitty 本月评分合计（`rate`/`Cost`，SEK PAYG）。
///
/// 文档：`GET /v2/summary?begin=&end=`（CloudKitty）；Keystone
/// `POST https://ops.elastx.cloud:5000/v3/auth/tokens`（application credential）。
/// 认证：`accessKeyID` = application credential id，`secretAccessKey` = secret；
/// 可选 `accountID` = project id。评分服务 endpoint 从 catalog `rating` 取，
/// 缺省 `https://ops.elastx.cloud:8889`。
public struct ElastxBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.elastx }

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
        let appID = try RequiredCredential.value(.accessKeyID, in: credential, providerID: .elastx)
        let secret = try RequiredCredential.value(.secretAccessKey, in: credential, providerID: .elastx)
        let projectID = credential.value(for: .accountID)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let auth = try await authenticate(appID: appID, secret: secret, projectID: projectID)
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let months = CalendarMonthWindow.months(
            for: horizon,
            lookbackMonths: min(Self.descriptor.historyLookbackMonths, 3),
            now: now,
            calendar: calendar
        )
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0
        try currencies.observe("SEK", providerID: .elastx)

        let headers = [
            "X-Auth-Token": auth.token,
            "Accept": "application/json",
        ]
        for month in months {
            // CloudKitty is ~4h behind; clamp end.
            let endCap = now.addingTimeInterval(-4 * 60 * 60)
            let end = min(month.nextStart, endCap)
            guard end > month.start else { continue }
            let summary = try await loadSummary(
                begin: month.start,
                end: end,
                ratingBase: auth.ratingBase,
                headers: headers
            )
            for row in summary.rows() {
                let amount = row.rate?.value ?? row.total?.value ?? 0
                guard amount != 0 else { continue }
                let label = row.res_type?.trimmed
                    ?? row.service?.trimmed
                    ?? "ALL"
                if month.start == current.start {
                    currentTotal += amount
                    lines.add(
                        SpendLine(
                            category: "rating",
                            label: label,
                            amountUSD: Money(usd: amount)
                        )
                    )
                } else {
                    daily.addPastMonth(
                        start: month.start,
                        amount: Money(usd: amount),
                        current: current,
                        calendar: calendar
                    )
                }
            }
        }

        let converted = try currencies.convert(currentTotal, rates: rateSource.current, providerID: .elastx)
        return Snapshot(
            providerID: .elastx,
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

    private func authenticate(
        appID: String,
        secret: String,
        projectID: String?
    ) async throws -> Auth {
        var identity: [String: Any] = [
            "methods": ["application_credential"],
            "application_credential": [
                "id": appID,
                "secret": secret,
            ],
        ]
        var authBody: [String: Any] = ["identity": identity]
        if let projectID, !projectID.isEmpty {
            authBody["scope"] = ["project": ["id": projectID]]
        }
        let body = try JSONSerialization.data(withJSONObject: ["auth": authBody])
        var request = URLRequest(url: Self.authURL)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await httpClient.send(request)
        } catch {
            throw ProviderError.networkFailure(providerID: .elastx)
        }
        if let mapped = ProviderError.fromHTTPStatus(response.statusCode, providerID: .elastx) {
            throw mapped
        }
        guard let token = response.value(forHTTPHeaderField: "X-Subject-Token"),
              !token.isEmpty else {
            throw ProviderError.unauthorized(providerID: .elastx)
        }
        let catalog = try? JSONDecoder().decode(TokenEnvelope.self, from: data)
        let rating = catalog?.token?.catalog?
            .first(where: { ($0.type ?? "").lowercased() == "rating" })?
            .endpoints?
            .first(where: { ($0.interface ?? "").lowercased() == "public" })?
            .url?
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return Auth(token: token, ratingBase: rating ?? Self.defaultRatingBase)
    }

    private func loadSummary(
        begin: Date,
        end: Date,
        ratingBase: String,
        headers: [String: String]
    ) async throws -> SummaryEnvelope {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let beginS = formatter.string(from: begin)
        let endS = formatter.string(from: end)
        guard var components = URLComponents(string: "\(ratingBase)/v2/summary") else {
            throw ProviderError.malformedResponse(providerID: .elastx)
        }
        components.queryItems = [
            URLQueryItem(name: "begin", value: beginS),
            URLQueryItem(name: "end", value: endS),
        ]
        guard let url = components.url else {
            throw ProviderError.malformedResponse(providerID: .elastx)
        }
        let data = try await ProviderHTTP.get(
            url: url,
            headers: headers,
            client: httpClient,
            providerID: .elastx
        )
        return try ProviderHTTP.decode(SummaryEnvelope.self, from: data, providerID: .elastx)
    }

    static var authURL: URL {
        var c = URLComponents()
        c.scheme = "https"
        c.host = "ops.elastx.cloud"
        c.port = 5000
        c.path = "/v3/auth/tokens"
        return c.url!
    }
    static let defaultRatingBase = "https://ops.elastx.cloud:8889"

    struct Auth: Sendable {
        var token: String
        var ratingBase: String
    }

    struct TokenEnvelope: Decodable, Sendable {
        var token: Token?
    }

    struct Token: Decodable, Sendable {
        var catalog: [Service]?
    }

    struct Service: Decodable, Sendable {
        var type: String?
        var endpoints: [Endpoint]?
    }

    struct Endpoint: Decodable, Sendable {
        var `interface`: String?
        var url: String?
    }

    struct SummaryEnvelope: Decodable, Sendable {
        var summary: [SummaryRow]?
        var results: [SummaryRow]?
        var total: FlexibleDecimal?
        var rate: FlexibleDecimal?

        func rows() -> [SummaryRow] {
            if let summary, !summary.isEmpty { return summary }
            if let results, !results.isEmpty { return results }
            if total != nil || rate != nil {
                return [SummaryRow(res_type: "ALL", service: nil, rate: rate ?? total, total: total)]
            }
            return []
        }
    }

    struct SummaryRow: Decodable, Sendable {
        var res_type: String?
        var service: String?
        var rate: FlexibleDecimal?
        var total: FlexibleDecimal?
    }
}

private extension String {
    var trimmed: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
