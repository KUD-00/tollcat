import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct IDCloudHostBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let token = "idch-key-MUST-NOT-LEAK"
    private let account = "6"

    @Test("totals.total IDR; period_start")
    func sumsInvoices() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let periodStart = current.start.timeIntervalSince1970
        let url = ProviderURL.https(
            host: IDCloudHostBillingProvider.apiHost,
            path: "/v1/payment/invoice/list",
            query: [URLQueryItem(name: "billing_account_id", value: account)]
        )
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    [
                        "id": 1,
                        "padded_id": "001",
                        "period_start": Int(periodStart),
                        "totals": ["total": 121000, "subtotal": 110000, "vat_tax": 11000],
                        "status": 10,
                    ],
                    [
                        "id": 2,
                        "padded_id": "002",
                        "period_start": 1_577_836_800,
                        "totals": ["total": 99000],
                        "status": 10,
                    ],
                ] as [Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.converted != nil)
        #expect(client.leakedSecrets([token]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = ProviderURL.https(
            host: IDCloudHostBillingProvider.apiHost,
            path: "/v1/payment/invoice/list",
            query: [URLQueryItem(name: "billing_account_id", value: account)]
        )
        await LiveProviderHarness.expectStatus(401, code: .unauthorized, key: .invalidCredentials) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (url, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
        await LiveProviderHarness.expectStatus(403, code: .forbidden, key: .insufficientPermissions) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (url, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .idcloudhost, fields: [.apiKey: token, .accountID: account])
    }

    private func provider(_ client: any HTTPClient) -> IDCloudHostBillingProvider {
        IDCloudHostBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["IDR": Decimal(string: "0.000062")!]))
        )
    }
}
