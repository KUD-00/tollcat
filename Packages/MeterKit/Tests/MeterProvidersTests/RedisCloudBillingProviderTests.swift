import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct RedisCloudBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let accountKey = "redis-acct-MUST-NOT-LEAK"
    private let userKey = "redis-user-MUST-NOT-LEAK"

    @Test("FOCUS BilledCost via cost-report task")
    func sumsCostReport() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let start = iso(current.start)
        let end = iso(current.endInclusive)
        let stamp = String(
            format: "%04d-%02d-05T00:00:00Z",
            calendar.component(.year, from: current.start),
            calendar.component(.month, from: current.start)
        )
        let createBodyMarker = "\"startDate\":\"\(start)\""
        let client = LiveProviderHarness.stub([
            (
                RedisCloudBillingProvider.costReportURL,
                LiveProviderHarness.json([
                    "taskId": "task-1",
                    "status": "received",
                ] as [String: Any])
            ),
            (
                RedisCloudBillingProvider.taskURL(id: "task-1"),
                LiveProviderHarness.json([
                    "taskId": "task-1",
                    "status": "processing-completed",
                    "response": [
                        "resource": ["costReportId": "report-1.json"]
                    ],
                ] as [String: Any])
            ),
            (
                RedisCloudBillingProvider.costReportDownloadURL(id: "report-1.json"),
                LiveProviderHarness.json([
                    [
                        "BilledCost": 42.5,
                        "BillingCurrency": "USD",
                        "ChargePeriodStart": stamp,
                        "ResourceName": "db-1",
                        "ServiceName": "Redis Cloud Pro",
                    ]
                ] as [Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "42.5")!))
        #expect(client.leakedSecrets([accountKey, userKey]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        _ = createBodyMarker
        _ = end
    }

    @Test("401 / 403")
    func statusMapping() async {
        await LiveProviderHarness.expectStatus(401, code: .unauthorized, key: .invalidCredentials) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (RedisCloudBillingProvider.costReportURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
        await LiveProviderHarness.expectStatus(403, code: .forbidden, key: .insufficientPermissions) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (RedisCloudBillingProvider.costReportURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(
            providerID: .rediscloud,
            fields: [.accessKeyID: accountKey, .secretAccessKey: userKey]
        )
    }

    private func provider(_ client: any HTTPClient) -> RedisCloudBillingProvider {
        RedisCloudBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(),
            sleepNanoseconds: { _ in }
        )
    }

    private func iso(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }
}
