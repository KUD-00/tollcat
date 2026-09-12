import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct ShipmondoBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let user = "d8fb61fe-0a4f-4e11-81f8-6efd3513bd43"
    private let secret = "976ff6f2-3528-4f4f-9e7d-007e9a074037_MUST-NOT-LEAK"
    private let dkkRate = Decimal(string: "0.15")!

    @Test("本月 sales_document 负金额取绝对值 + currency_code；忽略充值正数")
    func sumsCharges() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let url = ShipmondoBillingProvider.entriesURL(
            from: current.start,
            to: current.endInclusive,
            page: 1
        )
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    [
                        "id": 1,
                        "created_at": "2026-08-10T10:00:00+02:00",
                        "amount": "-49.00",
                        "currency_code": "DKK",
                        "source_type": "sales_document",
                        "reference_type": "shipment",
                        "description": "Shipment #100",
                    ],
                    [
                        "id": 2,
                        "created_at": "2026-08-15T12:00:00+02:00",
                        "amount": "-21.50",
                        "currency_code": "DKK",
                        "source_type": "sales_document",
                        "reference_type": "subscription_period",
                        "description": "Subscription",
                    ],
                    [
                        "id": 3,
                        "created_at": "2026-08-12T10:00:00+02:00",
                        "amount": "100.00",
                        "currency_code": "DKK",
                        "source_type": "transaction",
                        "description": "Top-up",
                    ],
                    [
                        "id": 4,
                        "created_at": "2026-07-05T10:00:00+02:00",
                        "amount": "-80.00",
                        "currency_code": "DKK",
                        "source_type": "sales_document",
                        "description": "July",
                    ],
                ] as [Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        // (49.00 + 21.50) * 0.15 = 10.575 → 10.58
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "10.58")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.httpMethod == "GET")
        let expected = "Basic \(ProviderOAuth.basicValue(id: user, secret: secret))"
        #expect(request.value(forHTTPHeaderField: "Authorization") == expected)
        #expect(request.url?.absoluteString.contains("source_type=sales_document") == true)
    }

    @Test("401 / 403")
    func statusMapping() async {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let url = ShipmondoBillingProvider.entriesURL(
            from: current.start,
            to: current.endInclusive,
            page: 1
        )
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
                LiveProviderHarness.stub([
                    (url, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .shipmondo, fields: [
            .email: user,
            .apiKey: secret,
        ])
    }

    private func provider(_ client: any HTTPClient) -> ShipmondoBillingProvider {
        ShipmondoBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["DKK": dkkRate]))
        )
    }
}
