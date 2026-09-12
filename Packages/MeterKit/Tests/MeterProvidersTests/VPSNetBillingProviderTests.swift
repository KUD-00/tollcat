import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct VPSNetBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let email = "dave@vps.net"
    private let secret = "vpsnet-key-MUST-NOT-LEAK"

    @Test("本月发票 amount + currency 合计")
    func sumsCurrentMonthInvoices() async throws {
        let url = VPSNetBillingProvider.invoicesURL
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    [
                        "invoice": [
                            "date_sent": "2026-08-10T07:09:19-04:00",
                            "amount": "15.00",
                            "currency": "USD",
                            "status": "paid",
                            "invoice_no": "9130",
                        ]
                    ],
                    [
                        "invoice": [
                            "date_sent": "2026-07-01T07:09:19-04:00",
                            "amount": "99.00",
                            "currency": "USD",
                            "status": "paid",
                            "invoice_no": "9001",
                        ]
                    ],
                ] as [[String: Any]])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "15.00")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = VPSNetBillingProvider.invoicesURL
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
        Credential(providerID: .vpsnet, fields: [.email: email, .apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> VPSNetBillingProvider {
        VPSNetBillingProvider(
            httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates()
        )
    }
}
