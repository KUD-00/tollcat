import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct MakeBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let token = "make_token_MUST_NOT_LEAK"
    private let orgID = "4242"
    private let eurRate = Decimal(string: "1.08")!

    @Test("本月 payments amount_total+currency_code 合计；跨月忽略")
    func sumsPayments() async throws {
        let url = MakeBillingProvider.paymentsURL(
            host: MakeBillingProvider.host(for: "eu1"),
            organizationID: orgID,
            offset: 0
        )
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "payments": [
                        [
                            "id": "pay_1",
                            "invoice_number": 1001,
                            "created": "2026-08-10T12:00:00.000Z",
                            "type_name": "subscription",
                            "status_name": "paid",
                            "amount_total": 29.0,
                            "currency_code": "EUR",
                            "period_from": "2026-08-01",
                            "period_to": "2026-08-31",
                        ],
                        [
                            "id": "pay_2",
                            "invoice_number": 1002,
                            "created": "2026-08-15T12:00:00.000Z",
                            "type_name": "credits",
                            "status_name": "paid",
                            "amount_total": 10.5,
                            "currency_code": "EUR",
                            "period_from": "2026-08-15",
                            "period_to": "2026-08-15",
                        ],
                        [
                            "id": "pay_zero",
                            "amount_total": 0,
                            "currency_code": "EUR",
                            "period_from": "2026-08-01",
                        ],
                        [
                            "id": "pay_july",
                            "amount_total": 99,
                            "currency_code": "EUR",
                            "period_from": "2026-07-01",
                            "created": "2026-07-05T12:00:00.000Z",
                        ],
                    ] as [[String: Any]]
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential())
        #expect(snapshot.kind == .usage)
        // (29 + 10.5) * 1.08 = 42.66
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "42.66")!))
        #expect(snapshot.converted?.currency == "EUR")
        #expect(client.leakedSecrets([token]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.url?.host == "eu1.make.com")
        #expect(request.url?.path.contains("/organizations/4242/payments") == true)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Token \(token)")
    }

    @Test("tenantID=us1 走 us1.make.com")
    func usesUSZone() async throws {
        let url = MakeBillingProvider.paymentsURL(
            host: "us1.make.com",
            organizationID: orgID,
            offset: 0
        )
        let client = LiveProviderHarness.stub([
            (url, LiveProviderHarness.json(["payments": [] as [Any]] as [String: Any])),
        ])
        _ = try await provider(client).fetch(credential: Credential(
            providerID: .make,
            fields: [.apiToken: token, .accountID: orgID, .tenantID: "us1"]
        ))
        #expect(client.requests.first?.url?.host == "us1.make.com")
        #expect(MakeBillingProvider.zone(for: nil) == "eu1")
        #expect(MakeBillingProvider.zone(for: "US2") == "us2")
        #expect(MakeBillingProvider.host(for: "eu2") == "eu2.make.com")
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = MakeBillingProvider.paymentsURL(
            host: "eu1.make.com",
            organizationID: orgID,
            offset: 0
        )
        await LiveProviderHarness.expectStatus(401, code: .unauthorized, key: .invalidCredentials) { status in
            try await provider(
                LiveProviderHarness.stub([(url, LiveProviderHarness.emptyJSON(status: status))])
            ).fetch(credential: credential())
        }
        await LiveProviderHarness.expectStatus(403, code: .forbidden, key: .insufficientPermissions) { status in
            try await provider(
                LiveProviderHarness.stub([(url, LiveProviderHarness.emptyJSON(status: status))])
            ).fetch(credential: credential())
        }
    }

    private func provider(_ client: RecordingHTTPClient) -> MakeBillingProvider {
        MakeBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["EUR": eurRate]))
        )
    }

    private func credential() -> Credential {
        Credential(providerID: .make, fields: [
            .apiToken: token,
            .accountID: orgID,
        ])
    }
}
