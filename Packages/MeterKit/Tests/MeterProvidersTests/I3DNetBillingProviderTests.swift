import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct I3DNetBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "i3dnet-token-MUST-NOT-LEAK"

    @Test("本月含税分金额按 currency 合计，跳过 credit")
    func sumsInclVatCents() async throws {
        let url = I3DNetBillingProvider.invoicesURL
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    [
                        "id": "1",
                        "invoiceNumber": "INV-1",
                        "creationDate": 1786320000,
                        "currency": "USD",
                        "amountIncVAT": "1210",
                        "amountExclVAT": "1000",
                        "isCredit": 0,
                    ],
                    [
                        "id": "2",
                        "invoiceNumber": "INV-2",
                        "creationDate": 1786752000,
                        "currency": "USD",
                        "amountIncVAT": "605",
                        "amountExclVAT": "500",
                        "isCredit": 0,
                    ],
                    [
                        "id": "credit",
                        "invoiceNumber": "CR-1",
                        "creationDate": 1786406400,
                        "currency": "USD",
                        "amountIncVAT": "500",
                        "amountExclVAT": "400",
                        "isCredit": 1,
                    ],
                    [
                        "id": "old",
                        "invoiceNumber": "INV-OLD",
                        "creationDate": 1782864000,
                        "currency": "USD",
                        "amountIncVAT": "99900",
                        "amountExclVAT": "80000",
                        "isCredit": 0,
                    ],
                ] as [[String: Any]])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "18.15")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "PRIVATE-TOKEN") == secret)
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = I3DNetBillingProvider.invoicesURL
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
        Credential(providerID: .i3dnet, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> I3DNetBillingProvider {
        I3DNetBillingProvider(httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates())
    }
}
