import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct IwinvBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let accessKey = "iwinv-access"
    private let secret = "iwinv-secret-MUST-NOT-LEAK"
    private let krwRate = Decimal(string: "0.00075")!

    @Test("payment_price KRW; skip prepaid")
    func sumsRegularBills() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let date = String(
            format: "%04d-%02d-05",
            calendar.component(.year, from: current.start),
            calendar.component(.month, from: current.start)
        )
        let url = ProviderURL.https(
            host: IwinvBillingProvider.apiHost,
            path: IwinvBillingProvider.billPath,
            query: [
                URLQueryItem(name: "page_no", value: "1"),
                URLQueryItem(name: "page_size", value: "100"),
            ]
        )
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "code": "0x00",
                    "result": [
                        [
                            "bill_id": "BILL-1",
                            "usage_start": date,
                            "bill_date": date,
                            "type": "regular",
                            "payment_price": 39820,
                            "currency": "KRW",
                        ],
                        [
                            "bill_id": "BILL-PRE",
                            "usage_start": date,
                            "type": "prepaid",
                            "payment_price": 50000,
                            "currency": "KRW",
                        ],
                        [
                            "bill_id": "BILL-OLD",
                            "usage_start": "2020-01-01",
                            "type": "regular",
                            "payment_price": 1000,
                            "currency": "KRW",
                        ],
                    ],
                    "count": 3,
                    "page_no": "1",
                    "page_size": "100",
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "29.87")!))
        #expect(snapshot.converted?.currency == "KRW")
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "X-iwinv-Credential") == accessKey)
        #expect(request.value(forHTTPHeaderField: "X-iwinv-Signature") != nil)
        #expect(request.value(forHTTPHeaderField: "X-iwinv-Timestamp") != nil)
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = ProviderURL.https(
            host: IwinvBillingProvider.apiHost,
            path: IwinvBillingProvider.billPath,
            query: [
                URLQueryItem(name: "page_no", value: "1"),
                URLQueryItem(name: "page_size", value: "100"),
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
        Credential(
            providerID: .iwinv,
            fields: [.accessKeyID: accessKey, .secretAccessKey: secret]
        )
    }

    private func provider(_ client: any HTTPClient) -> IwinvBillingProvider {
        IwinvBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["KRW": krwRate]))
        )
    }
}
