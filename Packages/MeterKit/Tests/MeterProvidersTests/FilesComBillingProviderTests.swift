import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct FilesComBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let key = "files_key_MUST-NOT-LEAK"

    @Test("amount + currency; skip payments")
    func sumsInvoices() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let iso = ISO8601DateFormatter().string(from: current.start.addingTimeInterval(86400 * 2))
        let url = ProviderURL.https(
            host: FilesComBillingProvider.apiHost,
            path: "/api/rest/v1/invoices.json",
            query: [URLQueryItem(name: "per_page", value: "100")]
        )
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    [
                        "id": 1,
                        "amount": "42.50",
                        "currency": "USD",
                        "created_at": iso,
                        "type": "invoice",
                    ],
                    [
                        "id": 2,
                        "amount": "99.00",
                        "currency": "USD",
                        "created_at": iso,
                        "type": "payment",
                    ],
                    [
                        "id": 3,
                        "amount": "10.00",
                        "currency": "USD",
                        "created_at": "2020-01-01T00:00:00Z",
                        "type": "invoice",
                    ],
                ] as [[String: Any]])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "42.50")!))
        #expect(client.leakedSecrets([key]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = ProviderURL.https(
            host: FilesComBillingProvider.apiHost,
            path: "/api/rest/v1/invoices.json",
            query: [URLQueryItem(name: "per_page", value: "100")]
        )
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
        Credential(providerID: .filescom, fields: [.apiKey: key])
    }

    private func provider(_ client: any HTTPClient) -> FilesComBillingProvider {
        FilesComBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates()
        )
    }
}
