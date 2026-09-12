import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct ThreePLGuysBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "3pl_test_key_MUST-NOT-LEAK"

    @Test("本月正金额发票按分转元合计，跳过 cancelled/refunded")
    func sumsPositiveInvoicesInCents() async throws {
        let url = ThreePLGuysBillingProvider.invoicesURL(skip: 0)
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    [
                        "id": "5",
                        "status": "paid",
                        "name": "Outbound Shipment #22",
                        "dueDate": "2026-08-20T00:00:00.000Z",
                        "totalAmount": 1750,
                        "currency": "USD",
                        "createdAt": "2026-08-10T10:00:00.000Z",
                    ],
                    [
                        "id": "6",
                        "status": "unpaid",
                        "name": "Storage August",
                        "totalAmount": 500,
                        "currency": "USD",
                        "createdAt": "2026-08-12T10:00:00.000Z",
                    ],
                    [
                        "id": "7",
                        "status": "cancelled",
                        "name": "Voided",
                        "totalAmount": 9999,
                        "currency": "USD",
                        "createdAt": "2026-08-11T10:00:00.000Z",
                    ],
                    [
                        "id": "8",
                        "status": "paid",
                        "name": "July invoice",
                        "totalAmount": 12000,
                        "currency": "USD",
                        "createdAt": "2026-07-01T10:00:00.000Z",
                    ],
                    [
                        "id": "9",
                        "status": "refunded",
                        "name": "Refunded",
                        "totalAmount": 300,
                        "currency": "USD",
                        "createdAt": "2026-08-14T10:00:00.000Z",
                    ],
                ] as [Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        // 17.50 + 5.00 = 22.50
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "22.50")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = ThreePLGuysBillingProvider.invoicesURL(skip: 0)
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
        Credential(providerID: .threeplguys, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> ThreePLGuysBillingProvider {
        ThreePLGuysBillingProvider(
            httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates()
        )
    }
}
