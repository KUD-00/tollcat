import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct VolcengineBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let accessKey = "AKLT_MUST_NOT_LEAK_akid"
    private let secretKey = "Secret_MUST_NOT_LEAK_sk"
    private let cnyRate = Decimal(string: "0.14")!

    @Test("本月 ListBillDetail PayableAmount+Currency 合计；忽略零额与缺币种")
    func sumsBillDetail() async throws {
        let stubURL = URL(string: "https://\(VolcengineBillingProvider.apiHost)/")!
        let client = LiveProviderHarness.stub([
            (
                stubURL,
                LiveProviderHarness.json([
                    "ResponseMetadata": ["Action": "ListBillDetail", "RequestId": "req-1"],
                    "Result": [
                        "Total": 3,
                        "Limit": 300,
                        "Offset": 0,
                        "List": [
                            [
                                "BillID": "Bill-1",
                                "BillPeriod": "2026-08",
                                "Product": "ECS",
                                "ProductZh": "云服务器",
                                "BillingMode": "按量计费",
                                "Currency": "CNY",
                                "PayableAmount": "100",
                                "PaidAmount": "100",
                            ],
                            [
                                "BillID": "Bill-2",
                                "BillPeriod": "2026-08",
                                "Product": "TOS",
                                "ProductZh": "对象存储",
                                "BillingMode": "按量计费",
                                "Currency": "CNY",
                                "PayableAmount": "50.5",
                                "PaidAmount": "50.5",
                            ],
                            [
                                "BillID": "Bill-3",
                                "BillPeriod": "2026-08",
                                "Product": "zero",
                                "Currency": "CNY",
                                "PayableAmount": "0",
                            ],
                            [
                                "BillID": "Bill-4",
                                "Product": "no-currency",
                                "PayableAmount": "9",
                            ],
                        ] as [[String: Any]],
                    ],
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential())
        #expect(snapshot.kind == .usage)
        // (100 + 50.5) * 0.14 = 21.07
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "21.07")!))
        #expect(snapshot.converted?.currency == "CNY")
        #expect(client.leakedSecrets([secretKey]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.url?.host == VolcengineBillingProvider.apiHost)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString.contains("Action=ListBillDetail") == true)
        #expect(request.url?.absoluteString.contains("BillPeriod=2026-08") == true)
        #expect(request.url?.absoluteString.contains("GroupTerm=2") == true)
        #expect(request.value(forHTTPHeaderField: "Authorization")?.hasPrefix("HMAC-SHA256 Credential=") == true)
        #expect(request.value(forHTTPHeaderField: "X-Date") != nil)
        #expect(request.value(forHTTPHeaderField: "X-Content-Sha256") != nil)
        #expect(!(request.value(forHTTPHeaderField: "Authorization")?.contains(secretKey) ?? true))
    }

    @Test("401 / 403")
    func statusMapping() async {
        let stubURL = URL(string: "https://\(VolcengineBillingProvider.apiHost)/")!
        await LiveProviderHarness.expectStatus(401, code: .unauthorized, key: .invalidCredentials) { status in
            try await provider(
                LiveProviderHarness.stub([(stubURL, LiveProviderHarness.emptyJSON(status: status))])
            ).fetch(credential: credential())
        }
        await LiveProviderHarness.expectStatus(403, code: .forbidden, key: .insufficientPermissions) { status in
            try await provider(
                LiveProviderHarness.stub([(stubURL, LiveProviderHarness.emptyJSON(status: status))])
            ).fetch(credential: credential())
        }
    }

    @Test("Volc HMAC-SHA256 与官方签名示例算法一致")
    func signatureMatchesReference() {
        let query: [String: String] = [
            "Action": "ListBillDetail",
            "Version": "2022-01-01",
            "BillPeriod": "2026-08",
            "Limit": "300",
            "Offset": "0",
            "GroupTerm": "2",
            "GroupPeriod": "0",
            "IgnoreZero": "1",
            "NeedRecordNum": "1",
        ]
        let headers = VolcengineBillingProvider.sign(
            method: "POST",
            host: VolcengineBillingProvider.apiHost,
            path: "/",
            query: query,
            body: Data(),
            accessKey: "AKLT_test_ak",
            secretKey: "test_secret_sk",
            now: now
        )
        #expect(headers["X-Date"] == "20260816T120000Z")
        #expect(
            headers["X-Content-Sha256"]
                == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        )
        #expect(
            headers["Authorization"]
                == "HMAC-SHA256 Credential=AKLT_test_ak/20260816/cn-north-1/billing/request, "
                + "SignedHeaders=content-type;host;x-content-sha256;x-date, "
                + "Signature=bba416ade3f9499f4df7c6bd164987e7129b67512f59d0357767bace58b2ad33"
        )
        #expect(VolcengineBillingProvider.billPeriod(now, calendar: calendar) == "2026-08")
        #expect(VolcengineBillingProvider.percentEncode("a b*") == "a%20b%2A")
    }

    private func provider(_ client: RecordingHTTPClient) -> VolcengineBillingProvider {
        VolcengineBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["CNY": cnyRate]))
        )
    }

    private func credential() -> Credential {
        Credential(providerID: .volcengine, fields: [
            .accessKeyID: accessKey,
            .secretAccessKey: secretKey,
        ])
    }
}
