import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct FriendliBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "flp_MUST-NOT-LEAK"

    @Test("本月 USD 日桶合计")
    func sumsCurrentMonthBuckets() async throws {
        let url = FriendliBillingProvider.costURL(
            startingAt: CalendarMonthWindow.current(now: now, calendar: calendar).start,
            endingAt: calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!,
            limit: 35,
            page: nil
        )
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "data": [
                        [
                            "start_time": "2026-08-05T00:00:00Z",
                            "end_time": "2026-08-06T00:00:00Z",
                            "results": [
                                ["total": "2.50", "line_item": "gpu time cost"],
                            ],
                        ],
                        [
                            "start_time": "2026-07-01T00:00:00Z",
                            "end_time": "2026-07-02T00:00:00Z",
                            "results": [
                                ["total": "99.00", "line_item": "old"],
                            ],
                        ],
                    ],
                    "has_more": false,
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "2.5")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = FriendliBillingProvider.costURL(
            startingAt: CalendarMonthWindow.current(now: now, calendar: calendar).start,
            endingAt: calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!,
            limit: 35,
            page: nil
        )
        await expectStatus(401, code: .unauthorized, key: .invalidCredentials, url: url)
        await expectStatus(403, code: .forbidden, key: .insufficientPermissions, url: url)
    }

    private func expectStatus(
        _ status: Int,
        code: ProviderError.Code,
        key: RemediationKey,
        url: URL
    ) async {
        await LiveProviderHarness.expectStatus(status, code: code, key: key) { status in
            try await provider(
                LiveProviderHarness.stub([(url, LiveProviderHarness.emptyJSON(status: status))])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .friendli, fields: [.apiToken: secret])
    }

    private func provider(_ client: any HTTPClient) -> FriendliBillingProvider {
        FriendliBillingProvider(
            httpClient: client, now: { now }, calendar: calendar,
            rateSource: SharedExchangeRates()
        )
    }
}
