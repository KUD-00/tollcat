import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct BitLaunchBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let token = "bl-token-MUST-NOT-LEAK"

    @Test("totalUsd thousandths → USD; ignore account balance")
    func sumsUsage() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let period = String(
            format: "%04d-%02d",
            calendar.component(.year, from: current.start),
            calendar.component(.month, from: current.start)
        )
        var components = URLComponents()
        components.scheme = "https"
        components.host = BitLaunchBillingProvider.apiHost
        components.path = "/api/usage"
        components.queryItems = [URLQueryItem(name: "period", value: period)]
        let url = components.url!
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "totalUsd": 1950,
                    "thisMonth": period,
                    "serverUsage": [
                        [
                            "description": "srv-1",
                            "start": String(format: "%@-05T13:00:00Z", period),
                            "end": String(format: "%@-05T18:00:00Z", period),
                            "cost": 1350,
                            "hours": 5,
                            "type": "server",
                        ],
                        [
                            "description": "prot-1",
                            "start": String(format: "%@-05T16:00:00Z", period),
                            "end": String(format: "%@-05T18:00:00Z", period),
                            "cost": 600,
                            "hours": 2,
                            "type": "protection",
                        ],
                    ],
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "1.95")!))
        #expect(client.leakedSecrets([token]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("401 / 403")
    func statusMapping() async {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let period = String(
            format: "%04d-%02d",
            calendar.component(.year, from: current.start),
            calendar.component(.month, from: current.start)
        )
        var components = URLComponents()
        components.scheme = "https"
        components.host = BitLaunchBillingProvider.apiHost
        components.path = "/api/usage"
        components.queryItems = [URLQueryItem(name: "period", value: period)]
        let url = components.url!
        await LiveProviderHarness.expectStatus(401, code: .unauthorized, key: .invalidCredentials) { status in
            try await provider(
                LiveProviderHarness.stub([(url, LiveProviderHarness.emptyJSON(status: status))])
            ).fetch(credential: credential)
        }
        await LiveProviderHarness.expectStatus(403, code: .forbidden, key: .insufficientPermissions) { status in
            try await provider(
                LiveProviderHarness.stub([(url, LiveProviderHarness.emptyJSON(status: status))])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .bitlaunch, fields: [.apiToken: token])
    }

    private func provider(_ client: any HTTPClient) -> BitLaunchBillingProvider {
        BitLaunchBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates()
        )
    }
}
