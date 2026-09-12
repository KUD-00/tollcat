import Foundation
import MeterCore

/// Upstash Redis Developer API。
///
/// 文档：`GET /v2/redis/databases` + `GET /v2/redis/stats/{id}`
/// 认证：HTTP Basic，用户名是注册邮箱，密码是 Developer API key。
/// `total_monthly_billing` 是本月美元。Vercel / Fly 一键账号打不通这条。
public struct UpstashBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.upstash }

    public var httpClient: any HTTPClient
    public var now: @Sendable () -> Date
    public var calendar: Calendar

    public init(httpClient: any HTTPClient, now: @escaping @Sendable () -> Date, calendar: Calendar) {
        self.httpClient = httpClient
        self.now = now
        self.calendar = calendar
    }

    public func fetch(credential: Credential) async throws -> Snapshot {
        let now = now()
        let email = try RequiredCredential.value(.email, in: credential, providerID: .upstash)
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .upstash)
        let headers = [
            "Authorization": Self.basicAuthorization(email: email, apiKey: apiKey),
        ]
        let listData = try await ProviderHTTP.get(
            url: Self.databasesURL,
            headers: headers,
            client: httpClient,
            providerID: .upstash
        )
        let databases = try ProviderHTTP.decode([Database].self, from: listData, providerID: .upstash)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        var daily = DailySpendAccumulator()
        var monthTotal = Decimal(0)

        for database in databases {
            guard let id = database.database_id, !id.isEmpty else { continue }
            let statsData = try await ProviderHTTP.get(
                url: Self.statsURL(id: id),
                headers: headers,
                client: httpClient,
                providerID: .upstash
            )
            let stats = try ProviderHTTP.decode(Stats.self, from: statsData, providerID: .upstash)
            if let billed = stats.total_monthly_billing?.value {
                monthTotal += billed
            }
            for point in stats.dailybilling ?? [] {
                let day = BillingDateParser.parse(point.x ?? "", calendar: calendar) ?? window.start
                if let amount = point.y?.value {
                    daily.add(day: day, amount: Money(usd: amount))
                }
            }
        }

        let spend = monthTotal > 0 ? Money(usd: monthTotal) : daily.total
        if spend == .zero {
            return Snapshot(
                providerID: .upstash,
                kind: .freeTier,
                fetchedAt: now,
                periodStart: window.start,
                periodEnd: window.endInclusive,
                currentSpendUSD: .zero,
                freeQuotaUsedRatio: 0,
                dailyUSD: daily.snapshotDaily
            )
        }

        return Snapshot(
            providerID: .upstash,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: spend,
            dailyUSD: daily.snapshotDaily ?? [:]
        )
    }

    static let databasesURL = URL(string: "https://api.upstash.com/v2/redis/databases")!

    static func statsURL(id: String) -> URL {
        URL(string: "https://api.upstash.com/v2/redis/stats/\(id)")!
    }

    static func basicAuthorization(email: String, apiKey: String) -> String {
        let raw = Data("\(email):\(apiKey)".utf8).base64EncodedString()
        return "Basic \(raw)"
    }

    struct Database: Decodable, Sendable {
        var database_id: String?
    }

    struct Stats: Decodable, Sendable {
        var total_monthly_billing: FlexibleDecimal?
        var dailybilling: [Point]?
    }

    struct Point: Decodable, Sendable {
        var x: String?
        var y: FlexibleDecimal?
    }
}
