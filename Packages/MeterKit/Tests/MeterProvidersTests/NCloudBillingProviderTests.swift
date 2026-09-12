import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct NCloudBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let accessKey = "ncp-access-publicish"
    private let secret = "ncp-secret-MUST-NOT-LEAK"
    private let krwRate = Decimal(string: "0.00075")!

    @Test("totalDemandAmount + payCurrency KRW; signed GET")
    func readsDemandCost() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let ym = NCloudBillingProvider.yearMonth(current.start, calendar: calendar)
        let url = NCloudBillingProvider.demandCostURL(startMonth: ym, endMonth: ym)
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "getDemandCostListResponse": [
                        "totalRows": 1,
                        "demandCostList": [
                            [
                                "demandMonth": ym,
                                "demandNo": "9540000",
                                "totalDemandAmount": 39820,
                                "payCurrency": [
                                    "code": "KRW",
                                    "codeName": "South Korea Won",
                                ],
                            ],
                            [
                                "demandMonth": "202001",
                                "demandNo": "old",
                                "totalDemandAmount": 99999,
                                "payCurrency": ["code": "KRW"],
                            ],
                        ],
                        "returnCode": "0",
                        "returnMessage": "success",
                    ]
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        // 39820 KRW * 0.00075 = 29.865 → 分位四舍五入 29.87 USD
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "29.87")!))
        #expect(snapshot.converted?.currency == "KRW")
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "x-ncp-iam-access-key") == accessKey)
        #expect(request.value(forHTTPHeaderField: "x-ncp-apigw-signature-v2") != nil)
        #expect(request.value(forHTTPHeaderField: "x-ncp-apigw-timestamp") != nil)
        #expect(!(request.url?.absoluteString.contains(secret) ?? true))
    }

    @Test("401 / 403")
    func statusMapping() async {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let ym = NCloudBillingProvider.yearMonth(current.start, calendar: calendar)
        let url = NCloudBillingProvider.demandCostURL(startMonth: ym, endMonth: ym)
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
            providerID: .ncloud,
            fields: [
                .accessKeyID: accessKey,
                .secretAccessKey: secret,
            ]
        )
    }

    private func provider(_ client: any HTTPClient) -> NCloudBillingProvider {
        NCloudBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["KRW": krwRate]))
        )
    }
}
