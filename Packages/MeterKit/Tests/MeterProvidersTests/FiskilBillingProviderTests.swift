import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct FiskilBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let clientID = "fiskil-client"
    private let clientSecret = "fiskil-secret-MUST-NOT-LEAK"
    private let endUser = "end-user-uuid"
    private let bearer = "fiskil-access-token"
    private let audRate = Decimal(string: "0.65")!

    @Test("total_amount + currency AUD; token exchange")
    func sumsInvoices() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let date = String(
            format: "%04d-%02d-08",
            calendar.component(.year, from: current.start),
            calendar.component(.month, from: current.start)
        )
        let invoicesURL = ProviderURL.https(
            host: FiskilBillingProvider.apiHost,
            path: "/v1/energy/invoice",
            query: [
                URLQueryItem(name: "end_user_id", value: endUser),
                URLQueryItem(name: "page[size]", value: "100"),
            ]
        )
        let client = LiveProviderHarness.stub([
            (
                FiskilBillingProvider.tokenURL,
                LiveProviderHarness.json([
                    "token": bearer,
                    "token_type": "Bearer",
                    "expires_in": 900,
                ] as [String: Any])
            ),
            (
                invoicesURL,
                LiveProviderHarness.json([
                    "invoices": [
                        [
                            "id": "inv_1",
                            "invoice_number": "INV-1",
                            "issue_date": date,
                            "period_start": date,
                            "period_end": date,
                            "total_amount": 185.50,
                            "currency": "AUD",
                            "status": "PAID",
                        ],
                        [
                            "id": "inv_old",
                            "invoice_number": "INV-OLD",
                            "issue_date": "2020-01-05",
                            "total_amount": 99.00,
                            "currency": "AUD",
                            "status": "PAID",
                        ],
                    ]
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "120.58")!))
        #expect(snapshot.converted?.currency == "AUD")
        #expect(client.leakedSecrets([clientSecret, bearer]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("401 / 403")
    func statusMapping() async {
        await LiveProviderHarness.expectStatus(401, code: .unauthorized, key: .invalidCredentials) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (
                        FiskilBillingProvider.tokenURL,
                        LiveProviderHarness.emptyJSON(status: status)
                    ),
                ])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(
            providerID: .fiskil,
            fields: [
                .clientID: clientID,
                .clientSecret: clientSecret,
                .accountID: endUser,
            ]
        )
    }

    private func provider(_ client: any HTTPClient) -> FiskilBillingProvider {
        FiskilBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["AUD": audRate]))
        )
    }
}
