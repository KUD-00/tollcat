import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct OpenproviderBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let username = "op-user-MUST-NOT-LEAK"
    private let password = "op-pass-MUST-NOT-LEAK"
    private let token = "op-token-MUST-NOT-LEAK"

    @Test("reseller price from invoices after login")
    func sumsResellerPrices() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let created = String(
            format: "%04d-%02d-10 12:00:00",
            calendar.component(.year, from: current.start),
            calendar.component(.month, from: current.start)
        )
        let loginURL = OpenproviderBillingProvider.loginURL
        let listURL = ProviderURL.https(
            host: OpenproviderBillingProvider.apiHost,
            path: "/v1beta/invoices",
            query: [
                URLQueryItem(name: "limit", value: "100"),
                URLQueryItem(name: "offset", value: "0"),
                URLQueryItem(name: "order_by", value: "creation_date"),
                URLQueryItem(name: "order", value: "desc"),
                URLQueryItem(name: "start_creation_date", value: OpenproviderBillingProvider.dateOnly(current.start)),
                URLQueryItem(name: "end_creation_date", value: OpenproviderBillingProvider.dateOnly(current.nextStart)),
            ]
        )
        let client = LiveProviderHarness.stub([
            (
                loginURL,
                LiveProviderHarness.json(["data": ["token": token, "reseller_id": 1]] as [String: Any])
            ),
            (
                listURL,
                LiveProviderHarness.json([
                    "data": [
                        "results": [
                            [
                                "id": 1,
                                "invoice_number": "XX1",
                                "creation_date": created,
                                "amount": [
                                    "reseller": ["currency": "EUR", "price": 12.5],
                                    "product": ["currency": "EUR", "price": 10],
                                ],
                            ],
                            [
                                "id": 2,
                                "invoice_number": "XX2",
                                "creation_date": created,
                                "amount": [
                                    "reseller": ["currency": "EUR", "price": 7.5],
                                ],
                            ],
                        ],
                        "total": 2,
                    ]
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "22.00")!))
        #expect(client.leakedSecrets([password, token]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("401 / 403")
    func statusMapping() async {
        let loginURL = OpenproviderBillingProvider.loginURL
        await LiveProviderHarness.expectStatus(401, code: .unauthorized, key: .invalidCredentials) { status in
            try await provider(
                LiveProviderHarness.stub([(loginURL, LiveProviderHarness.emptyJSON(status: status))])
            ).fetch(credential: credential)
        }
        await LiveProviderHarness.expectStatus(403, code: .forbidden, key: .insufficientPermissions) { status in
            try await provider(
                LiveProviderHarness.stub([(loginURL, LiveProviderHarness.emptyJSON(status: status))])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .openprovider, fields: [.email: username, .clientSecret: password])
    }

    private func provider(_ client: any HTTPClient) -> OpenproviderBillingProvider {
        OpenproviderBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["EUR": Decimal(string: "1.10")!]))
        )
    }
}
