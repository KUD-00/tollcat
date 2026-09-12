import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct TypebotBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "typebot-token-MUST-NOT-LEAK"
    private let workspace = "ws_demo"

    @Test("本月发票 subtotal 分转主单位")
    func readsInvoiceCents() async throws {
        let url = TypebotBillingProvider.invoicesURL(workspaceID: workspace)
        let paidAt = Int(now.timeIntervalSince1970)
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "invoices": [
                        [
                            "id": "INV-1001",
                            "url": "https://example.invalid/inv.pdf",
                            "amount": 3900,
                            "currency": "usd",
                            "date": paidAt,
                        ]
                    ]
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "39")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
        #expect(request.url?.absoluteString.contains("workspaceId=\(workspace)") == true)
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = TypebotBillingProvider.invoicesURL(workspaceID: workspace)
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
        Credential(providerID: .typebot, fields: [.apiToken: secret, .accountID: workspace])
    }

    private func provider(_ client: any HTTPClient) -> TypebotBillingProvider {
        TypebotBillingProvider(
            httpClient: client, now: { now }, calendar: calendar,
            rateSource: SharedExchangeRates()
        )
    }
}
