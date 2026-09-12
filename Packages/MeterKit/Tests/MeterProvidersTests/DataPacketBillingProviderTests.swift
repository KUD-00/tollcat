import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct DataPacketBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "datapacket-token-MUST-NOT-LEAK"

    @Test("本月发票按 currency 合计，跳过 DRAFT")
    func sumsInvoices() async throws {
        let url = DataPacketBillingProvider.graphqlURL
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "data": [
                        "invoices": [
                            "isLastPage": true,
                            "nextPageIndex": nil,
                            "entries": [
                                [
                                    "invoiceNumber": "DP1",
                                    "total": 100.5,
                                    "currency": "USD",
                                    "createdAt": "2026-08-10T12:00:00Z",
                                    "invoiceType": "INVOICE",
                                ],
                                [
                                    "invoiceNumber": "DP2",
                                    "total": 9.5,
                                    "currency": "USD",
                                    "createdAt": "2026-08-15T12:00:00Z",
                                    "invoiceType": "INVOICE",
                                ],
                                [
                                    "invoiceNumber": "DRAFT1",
                                    "total": 50,
                                    "currency": "USD",
                                    "createdAt": "2026-08-12T12:00:00Z",
                                    "invoiceType": "DRAFT",
                                ],
                                [
                                    "invoiceNumber": "OLD",
                                    "total": 999,
                                    "currency": "USD",
                                    "createdAt": "2026-07-01T12:00:00Z",
                                    "invoiceType": "INVOICE",
                                ],
                            ] as [[String: Any]],
                        ] as [String: Any]
                    ] as [String: Any]
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "110")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
        #expect(request.httpMethod == "POST")
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = DataPacketBillingProvider.graphqlURL
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
        Credential(providerID: .datapacket, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> DataPacketBillingProvider {
        DataPacketBillingProvider(httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates())
    }
}
