import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct ZComCloudBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let username = "zcom-user-MUST-NOT-LEAK"
    private let password = "zcom-pass-MUST-NOT-LEAK"
    private let tenant = "tenant-MUST-NOT-LEAK"
    private let token = "zcom-token-MUST-NOT-LEAK"

    @Test("bill_plas_tax JPY from billing-invoices")
    func sumsInvoices() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let invoiceDate = String(
            format: "%04d-%02d-01T00:00:00",
            calendar.component(.year, from: current.start),
            calendar.component(.month, from: current.start)
        )
        let authURL = ZComCloudBillingProvider.identityURL(region: "tyo1", path: "/v2.0/tokens")
        let listURL = ProviderURL.https(
            host: "account.tyo1.cloud.z.com",
            path: "/v1/\(tenant)/billing-invoices",
            query: [URLQueryItem(name: "limit", value: "100")]
        )
        let client = LiveProviderHarness.stub([
            (
                authURL,
                LiveProviderHarness.json([
                    "access": ["token": ["id": token]]
                ] as [String: Any])
            ),
            (
                listURL,
                LiveProviderHarness.json([
                    "billing_invoices": [
                        [
                            "invoice_id": 1,
                            "invoice_date": invoiceDate,
                            "bill_plas_tax": 1100,
                            "payment_method_type": "Charge",
                        ],
                        [
                            "invoice_id": 2,
                            "invoice_date": invoiceDate,
                            "bill_plus_tax": 400,
                        ],
                        [
                            "invoice_id": 3,
                            "invoice_date": "2020-01-01T00:00:00",
                            "bill_plas_tax": 99999,
                        ],
                    ]
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "10.05")!))
        #expect(client.leakedSecrets([password, token]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let auth = try #require(client.requests.first)
        #expect(auth.httpMethod == "POST")
    }

    @Test("401 / 403")
    func statusMapping() async {
        let authURL = ZComCloudBillingProvider.identityURL(region: "tyo1", path: "/v2.0/tokens")
        await LiveProviderHarness.expectStatus(401, code: .unauthorized, key: .invalidCredentials) { status in
            try await provider(
                LiveProviderHarness.stub([(authURL, LiveProviderHarness.emptyJSON(status: status))])
            ).fetch(credential: credential)
        }
        await LiveProviderHarness.expectStatus(403, code: .forbidden, key: .insufficientPermissions) { status in
            try await provider(
                LiveProviderHarness.stub([(authURL, LiveProviderHarness.emptyJSON(status: status))])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(
            providerID: .zcomcloud,
            fields: [
                .clientID: username,
                .clientSecret: password,
                .tenantID: tenant,
                .accountID: "tyo1",
            ]
        )
    }

    private func provider(_ client: any HTTPClient) -> ZComCloudBillingProvider {
        ZComCloudBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["JPY": Decimal(string: "0.0067")!]))
        )
    }
}
