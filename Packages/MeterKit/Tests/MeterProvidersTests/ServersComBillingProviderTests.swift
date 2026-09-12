import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct ServersComBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "serverscom-jwt-MUST-NOT-LEAK"

    @Test("本月正金额发票按 currency 合计，跳过 credit_note")
    func sumsPositiveInvoices() async throws {
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let url = ServersComBillingProvider.invoicesURL(from: window.start, to: window.endInclusive, page: 1)
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    [
                        "id": "a1",
                        "number": 10,
                        "status": "paid",
                        "date": "2026-08-01",
                        "type": "invoice",
                        "total_due": 200,
                        "currency": "EUR",
                    ],
                    [
                        "id": "a2",
                        "number": 11,
                        "status": "pending",
                        "date": "2026-08-15",
                        "type": "invoice",
                        "total_due": 50.5,
                        "currency": "EUR",
                    ],
                    [
                        "id": "cn1",
                        "number": 12,
                        "status": "paid",
                        "date": "2026-08-20",
                        "type": "credit_note",
                        "total_due": -20,
                        "currency": "EUR",
                    ],
                    [
                        "id": "old",
                        "number": 9,
                        "status": "paid",
                        "date": "2026-07-01",
                        "type": "invoice",
                        "total_due": 999,
                        "currency": "EUR",
                    ],
                ] as [Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "250.5")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
    }

    @Test("401 / 403")
    func statusMapping() async {
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let url = ServersComBillingProvider.invoicesURL(from: window.start, to: window.endInclusive, page: 1)
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
                LiveProviderHarness.stub([
                    (url, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .serverscom, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> ServersComBillingProvider {
        ServersComBillingProvider(httpClient: client, now: { now }, calendar: calendar, rateSource: LiveProviderHarness.passthroughRates)
    }
}
