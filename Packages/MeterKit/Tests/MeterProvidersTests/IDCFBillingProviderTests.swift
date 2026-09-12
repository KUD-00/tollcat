import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct IDCFBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let apiKey = "idcf-key-publicish"
    private let secret = "idcf-secret-MUST-NOT-LEAK"

    @Test("meta.total JPY from monthly billings")
    func readsMonthlyTotal() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let ym = IDCFBillingProvider.yearMonth(current.start, calendar: calendar)
        let url = IDCFBillingProvider.billingURL(yearMonth: ym)
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "meta": [
                        "total": 1500,
                        "tax": 120,
                        "billing_period_start_at": String(
                            format: "%04d-%02d-01",
                            calendar.component(.year, from: current.start),
                            calendar.component(.month, from: current.start)
                        ),
                    ]
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "10.05")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "X-IDCF-APIKEY") == apiKey)
        #expect(request.value(forHTTPHeaderField: "X-IDCF-Signature") != nil)
        #expect(!(request.url?.absoluteString.contains(secret) ?? true))
    }

    @Test("401 / 403")
    func statusMapping() async {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let url = IDCFBillingProvider.billingURL(
            yearMonth: IDCFBillingProvider.yearMonth(current.start, calendar: calendar)
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
        Credential(
            providerID: .idcf,
            fields: [
                .apiKey: apiKey,
                .clientSecret: secret,
            ]
        )
    }

    private func provider(_ client: any HTTPClient) -> IDCFBillingProvider {
        IDCFBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["JPY": Decimal(string: "0.0067")!]))
        )
    }
}
