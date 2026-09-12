import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct TencentCloudBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let accessKey = "AKID_MUST_NOT_LEAK_akid"
    private let secretKey = "Secret_MUST_NOT_LEAK_sk"
    private let cnyRate = Decimal(string: "0.14")!

    @Test("本月 DescribeBillDetail Component.RealCost+Currency 合计；忽略零额与缺币种")
    func sumsBillDetail() async throws {
        let stubURL = URL(string: "https://\(TencentCloudBillingProvider.cnHost)/")!
        let client = LiveProviderHarness.stub([
            (
                stubURL,
                LiveProviderHarness.json([
                    "Response": [
                        "RequestId": "req-1",
                        "Total": 3,
                        "DetailSet": [
                            [
                                "BusinessCode": "p_cvm",
                                "BusinessCodeName": "云服务器 CVM",
                                "ProductCode": "sp_cvm",
                                "ProductCodeName": "云服务器",
                                "ActionType": "prepay",
                                "ResourceId": "ins-1",
                                "Currency": "CNY",
                                "ComponentSet": [
                                    [
                                        "ComponentCodeName": "计算组件",
                                        "RealCost": "100",
                                        "CashPayAmount": "100",
                                    ],
                                ] as [[String: Any]],
                            ],
                            [
                                "BusinessCode": "p_cos",
                                "BusinessCodeName": "对象存储 COS",
                                "ProductCode": "sp_cos",
                                "Currency": "CNY",
                                "ComponentSet": [
                                    [
                                        "ComponentCodeName": "存储",
                                        "RealCost": "50.5",
                                    ],
                                    [
                                        "ComponentCodeName": "零额",
                                        "RealCost": "0",
                                    ],
                                ] as [[String: Any]],
                            ],
                            [
                                "BusinessCode": "p_zero",
                                "Currency": "CNY",
                                "ComponentSet": [
                                    ["RealCost": "0"] as [String: Any],
                                ],
                            ],
                            [
                                "BusinessCode": "p_no_currency",
                                "ComponentSet": [
                                    ["RealCost": "9"] as [String: Any],
                                ],
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
        #expect(request.url?.host == TencentCloudBillingProvider.cnHost)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "X-TC-Action") == "DescribeBillDetail")
        #expect(request.value(forHTTPHeaderField: "X-TC-Version") == TencentCloudBillingProvider.apiVersion)
        #expect(request.value(forHTTPHeaderField: "X-TC-Timestamp") != nil)
        #expect(request.value(forHTTPHeaderField: "Authorization")?.hasPrefix("TC3-HMAC-SHA256 Credential=") == true)
        #expect(!(request.value(forHTTPHeaderField: "Authorization")?.contains(secretKey) ?? true))
        let body = try #require(request.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["Month"] as? String == "2026-08")
        #expect(json["Limit"] as? Int == 300)
        #expect(json["Offset"] as? Int == 0)
        #expect(json["NeedRecordNum"] as? Int == 1)
    }

    @Test("401 / 403")
    func statusMapping() async {
        let stubURL = URL(string: "https://\(TencentCloudBillingProvider.cnHost)/")!
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

    @Test("TC3-HMAC-SHA256 与官方签名 DEMO 一致")
    func signatureMatchesOfficialDemo() {
        // 官方文档 Signature v3 示例（CVM DescribeInstances）。
        let payload =
            #"{"Limit": 1, "Filters": [{"Values": ["\u672a\u547d\u540d"], "Name": "instance-name"}]}"#
        let body = Data(payload.utf8)
        let demoNow = Date(timeIntervalSince1970: 1_551_113_065)
        let headers = TencentCloudBillingProvider.sign(
            host: "cvm.tencentcloudapi.com",
            action: "DescribeInstances",
            body: body,
            secretId: "AKIDz8krbsJ5yKBZQpn74WFkmLPx3EXAMPLE",
            secretKey: "Gu5t9xGARNpq86cd98joQYCN3EXAMPLE",
            now: demoNow,
            service: "cvm",
            version: "2017-03-12"
        )
        #expect(headers["X-TC-Timestamp"] == "1551113065")
        #expect(headers["X-TC-Action"] == "DescribeInstances")
        #expect(headers["X-TC-Version"] == "2017-03-12")
        #expect(
            headers["Authorization"]
                == "TC3-HMAC-SHA256 Credential=AKIDz8krbsJ5yKBZQpn74WFkmLPx3EXAMPLE/2019-02-25/cvm/tc3_request, "
                + "SignedHeaders=content-type;host, "
                + "Signature=72e494ea809ad7a8c8f7a4507b9bddcbaa8e581f516e8da2f66e2c5a96525168"
        )
        #expect(TencentCloudBillingProvider.billMonth(now, calendar: calendar) == "2026-08")
        #expect(TencentCloudBillingProvider.host(for: nil) == TencentCloudBillingProvider.cnHost)
        #expect(TencentCloudBillingProvider.host(for: "intl") == TencentCloudBillingProvider.intlHost)
    }

    private func provider(_ client: RecordingHTTPClient) -> TencentCloudBillingProvider {
        TencentCloudBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["CNY": cnyRate]))
        )
    }

    private func credential() -> Credential {
        Credential(providerID: .tencentcloud, fields: [
            .accessKeyID: accessKey,
            .secretAccessKey: secretKey,
        ])
    }
}
