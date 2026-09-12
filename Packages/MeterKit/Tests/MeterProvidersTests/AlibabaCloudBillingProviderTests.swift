import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct AlibabaCloudBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let accessKey = "LTAI_MUST_NOT_LEAK_akid"
    private let secretKey = "Secret_MUST_NOT_LEAK_sk"
    private let cnyRate = Decimal(string: "0.14")!

    @Test("本月 QueryBillOverview PretaxAmount+Currency 合计；忽略零额")
    func sumsBillOverview() async throws {
        // StubHTTPClient 在精确 URL 未命中时回退到同 path；BSS 签名 query 随机 nonce，
        // 用 host 根 path `/` 匹配任何 QueryBillOverview。
        let stubURL = URL(string: "https://\(AlibabaCloudBillingProvider.intlHost)/")!
        let client = LiveProviderHarness.stub([
            (
                stubURL,
                LiveProviderHarness.json([
                    "Success": true,
                    "Code": "Success",
                    "Data": [
                        "BillingCycle": "2026-08",
                        "Items": [
                            "Item": [
                                [
                                    "Item": "PayAsYouGoBill",
                                    "Currency": "CNY",
                                    "SubscriptionType": "PayAsYouGo",
                                    "PretaxAmount": 100,
                                    "PaymentAmount": 100,
                                    "ProductName": "Elastic Compute Service",
                                    "ProductCode": "ecs",
                                ],
                                [
                                    "Item": "SubscriptionOrder",
                                    "Currency": "CNY",
                                    "SubscriptionType": "Subscription",
                                    "PretaxAmount": 50.5,
                                    "PaymentAmount": 50.5,
                                    "ProductName": "Object Storage Service",
                                    "ProductCode": "oss",
                                ],
                                [
                                    "Item": "PayAsYouGoBill",
                                    "Currency": "CNY",
                                    "PretaxAmount": 0,
                                    "PaymentAmount": 0,
                                    "ProductName": "zero",
                                ],
                            ] as [[String: Any]]
                        ],
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
        #expect(request.url?.host == AlibabaCloudBillingProvider.intlHost)
        #expect(request.url?.absoluteString.contains("Action=QueryBillOverview") == true)
        #expect(request.url?.absoluteString.contains("BillingCycle=2026-08") == true)
        #expect(request.url?.absoluteString.contains("Signature=") == true)
        #expect(!(request.url?.absoluteString.contains(secretKey) ?? true))
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test("accountID=cn 走国内 business.aliyuncs.com")
    func usesChinaHost() async throws {
        let stubURL = URL(string: "https://\(AlibabaCloudBillingProvider.cnHost)/")!
        let client = LiveProviderHarness.stub([
            (
                stubURL,
                LiveProviderHarness.json([
                    "Success": true,
                    "Data": ["Items": ["Item": [] as [Any]]],
                ] as [String: Any])
            ),
        ])
        _ = try await provider(client).fetch(
            credential: Credential(providerID: .alibabacloud, fields: [
                .accessKeyID: accessKey,
                .secretAccessKey: secretKey,
                .accountID: "cn",
            ])
        )
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.url?.host == AlibabaCloudBillingProvider.cnHost)
    }

    @Test("401 / 403")
    func statusMapping() async {
        let stubURL = URL(string: "https://\(AlibabaCloudBillingProvider.intlHost)/")!
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

    @Test("RPC 签名与官方 percentEncode / HMAC-SHA1 一致")
    func signatureMatchesReference() {
        let params: [String: String] = [
            "AccessKeyId": "testid",
            "Action": "QueryBillOverview",
            "BillingCycle": "2026-08",
            "Format": "JSON",
            "SignatureMethod": "HMAC-SHA1",
            "SignatureNonce": "nonce123",
            "SignatureVersion": "1.0",
            "Timestamp": "2026-08-16T12:00:00Z",
            "Version": "2017-12-14",
        ]
        let sig = AlibabaCloudBillingProvider.sign(params: params, secretKey: "testsecret")
        #expect(sig == "Fp6Pz7yG7GQAuIfgYYh/3kFxoU0=")
        #expect(AlibabaCloudBillingProvider.percentEncode("a b*") == "a%20b%2A")
        #expect(AlibabaCloudBillingProvider.host(for: nil) == AlibabaCloudBillingProvider.intlHost)
        #expect(AlibabaCloudBillingProvider.host(for: "cn") == AlibabaCloudBillingProvider.cnHost)
        #expect(AlibabaCloudBillingProvider.billCycle(now, calendar: calendar) == "2026-08")
    }

    private func provider(_ client: RecordingHTTPClient) -> AlibabaCloudBillingProvider {
        AlibabaCloudBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["CNY": cnyRate]))
        )
    }

    private func credential() -> Credential {
        Credential(providerID: .alibabacloud, fields: [
            .accessKeyID: accessKey,
            .secretAccessKey: secretKey,
        ])
    }
}
