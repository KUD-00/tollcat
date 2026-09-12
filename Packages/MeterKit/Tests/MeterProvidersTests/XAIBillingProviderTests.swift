import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct XAIBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "xai-mgmt-MUST-NOT-LEAK"
    private let team = "65c1e471-205f-4566-9c5a-07198bcdf4ce"

    @Test("后付费 preview 的 amountAfterVat 分转成美元")
    func previewCentsToUSD() async throws {
        let client = LiveProviderHarness.stub([
            (previewURL, LiveProviderHarness.json([
                "coreInvoice": [
                    "amountAfterVat": "1234",
                    "lines": [
                        ["description": "grok", "unitType": "token", "amount": "1234"],
                    ],
                ],
            ] as [String: Any])),
            (invoicesURL, LiveProviderHarness.json(["invoices": [] as [Any]])),
            (usageURL, LiveProviderHarness.json(["timeSeries": [] as [Any]])),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "12.34")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("缺 Team ID")
    func missingTeam() async {
        let error = await #expect(throws: ProviderError.self) {
            try await provider(LiveProviderHarness.stub([])).fetch(
                credential: Credential(providerID: .xai, fields: [.apiKey: secret])
            )
        }
        #expect(error?.code == .missingCredential)
    }

    private var credential: Credential {
        Credential(providerID: .xai, fields: [.apiKey: secret, .accountID: team])
    }

    private func provider(_ client: any HTTPClient) -> XAIBillingProvider {
        XAIBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates()
        )
    }

    private var previewURL: URL {
        ProviderURL.https(
            host: XAIBillingProvider.apiHost,
            path: "/v1/billing/teams/\(team)/postpaid/invoice/preview"
        )
    }

    private var invoicesURL: URL {
        ProviderURL.https(
            host: XAIBillingProvider.apiHost,
            path: "/v1/billing/teams/\(team)/invoices"
        )
    }

    private var usageURL: URL {
        ProviderURL.https(
            host: XAIBillingProvider.apiHost,
            path: "/v1/billing/teams/\(team)/usage"
        )
    }
}
