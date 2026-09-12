import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct ArmadaBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let apiKey = "main_armada-MUST-NOT-LEAK"
    private let secret = "armada-secret-MUST-NOT-LEAK"

    @Test("REGULAR invoice amount; skip TOPUP_WALLET")
    func readsRegularInvoices() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let begin = String(format: "%04d-%02d-01",
                           calendar.component(.year, from: current.start),
                           calendar.component(.month, from: current.start))
        let end = String(format: "%04d-%02d-28",
                         calendar.component(.year, from: current.start),
                         calendar.component(.month, from: current.start))
        let url = ProviderURL.https(
            host: ArmadaBillingProvider.apiHost,
            path: "/v2/invoices",
            query: [
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "perPage", value: "100"),
                URLQueryItem(name: "status", value: "all"),
            ]
        )
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "page": 1,
                    "perPage": 100,
                    "total": 2,
                    "invoices": [
                        [
                            "id": "670abc",
                            "invoiceNo": "INV-1",
                            "type": "REGULAR",
                            "status": "PAID",
                            "amount": 142.5,
                            "currency": "KWD",
                            "periodBegin": begin,
                            "periodEnd": end,
                        ],
                        [
                            "id": "670def",
                            "invoiceNo": "TOP-1",
                            "type": "TOPUP_WALLET",
                            "status": "PAID",
                            "amount": 500,
                            "currency": "KWD",
                            "periodBegin": begin,
                            "periodEnd": end,
                        ],
                    ],
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "142.5")!))
        #expect(client.leakedSecrets([apiKey, secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Key \(apiKey)")
        #expect(request.value(forHTTPHeaderField: "x-armada-timestamp") != nil)
        #expect(request.value(forHTTPHeaderField: "x-armada-signature") != nil)
    }

    @Test("HMAC signature payload")
    func signatureMatchesDocsShape() {
        let sig = ArmadaBillingProvider.signForTests(
            method: "GET",
            path: "/v2/invoices?status=paid&page=1",
            body: "",
            secret: "00000000-0000-0000-0000-000000000000",
            timestampMillis: "1776182400000"
        )
        #expect(sig.count == 64)
        #expect(sig == ArmadaBillingProvider.signForTests(
            method: "GET",
            path: "/v2/invoices?status=paid&page=1",
            body: "",
            secret: "00000000-0000-0000-0000-000000000000",
            timestampMillis: "1776182400000"
        ))
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = ProviderURL.https(
            host: ArmadaBillingProvider.apiHost,
            path: "/v2/invoices",
            query: [
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "perPage", value: "100"),
                URLQueryItem(name: "status", value: "all"),
            ]
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
        Credential(providerID: .armada, fields: [
            .apiKey: apiKey,
            .clientSecret: secret,
        ])
    }

    private func provider(_ client: any HTTPClient) -> ArmadaBillingProvider {
        ArmadaBillingProvider(
            httpClient: client, now: { now }, calendar: calendar, rateSource: LiveProviderHarness.passthroughRates
        )
    }
}
