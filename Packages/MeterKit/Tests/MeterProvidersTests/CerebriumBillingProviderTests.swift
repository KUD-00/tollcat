import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct CerebriumBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "sat_test_token_MUST-NOT-LEAK"
    private let projectID = "proj-cerebrium-test"

    @Test("本月 amountDue 分/100 + currency；跳过 void")
    func sumsInvoices() async throws {
        let url = CerebriumBillingProvider.invoicesURL(projectID: projectID)
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    [
                        "id": "inv-1",
                        "amountDue": 9900,
                        "currency": "USD",
                        "createdAt": "2026-08-10T10:00:00Z",
                        "paymentStatus": "paid",
                    ],
                    [
                        "id": "inv-2",
                        "amountDue": 2500,
                        "currency": "USD",
                        "createdAt": "2026-08-15T12:00:00Z",
                        "paymentStatus": "open",
                    ],
                    [
                        "id": "inv-void",
                        "amountDue": 5000,
                        "currency": "USD",
                        "createdAt": "2026-08-12T10:00:00Z",
                        "paymentStatus": "void",
                    ],
                    [
                        "id": "inv-july",
                        "amountDue": 8000,
                        "currency": "USD",
                        "createdAt": "2026-07-05T10:00:00Z",
                        "paymentStatus": "paid",
                    ],
                ] as [Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        // 99.00 + 25.00 = 124.00
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "124")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = CerebriumBillingProvider.invoicesURL(projectID: projectID)
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
        Credential(providerID: .cerebrium, fields: [
            .apiKey: secret,
            .projectID: projectID,
        ])
    }

    private func provider(_ client: any HTTPClient) -> CerebriumBillingProvider {
        CerebriumBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates()
        )
    }
}
