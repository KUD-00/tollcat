import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct QoveryBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "qovery-token-MUST-NOT-LEAK"
    private let orgID = "11111111-2222-3333-4444-555555555555"

    @Test("发票 total+currency_code 按 created_at 归入本月")
    func sumsCurrentMonthInvoices() async throws {
        let url = QoveryBillingProvider.invoicesURL(organizationID: orgID)
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "results": [
                        [
                            "id": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
                            "created_at": "2026-08-10T12:00:00Z",
                            "status": "PAID",
                            "total_in_cents": 3000,
                            "total": 30.0,
                            "currency_code": "USD",
                        ],
                        [
                            "id": "ffffffff-0000-1111-2222-333333333333",
                            "created_at": "2026-07-01T12:00:00Z",
                            "status": "PAID",
                            "total_in_cents": 9900,
                            "total": 99.0,
                            "currency_code": "USD",
                        ],
                    ]
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "30")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Token \(secret)")
    }

    @Test("空发票列表是本月 $0")
    func emptyInvoicesAreZero() async throws {
        let url = QoveryBillingProvider.invoicesURL(organizationID: orgID)
        let client = LiveProviderHarness.stub([
            (url, LiveProviderHarness.json(["results": [] as [Any]] as [String: Any])),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == .zero)
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = QoveryBillingProvider.invoicesURL(organizationID: orgID)
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
        Credential(providerID: .qovery, fields: [.apiToken: secret, .accountID: orgID])
    }

    private func provider(_ client: any HTTPClient) -> QoveryBillingProvider {
        QoveryBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates()
        )
    }
}
