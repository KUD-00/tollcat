import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct KingsoftCloudBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let accessKey = "AKLT_MUST_NOT_LEAK_akid"
    private let secretKey = "Secret_MUST_NOT_LEAK_sk"
    private let cnyRate = Decimal(string: "0.14")!

    @Test("本月 DescribeBillSummaryByProduct RealTotalCost+Currency 合计；忽略零额")
    func sumsBillSummary() async throws {
        let stubURL = URL(string: "https://\(KingsoftCloudBillingProvider.apiHost)/")!
        let client = LiveProviderHarness.stub([
            (
                stubURL,
                LiveProviderHarness.json([
                    "RequestId": "req-1",
                    "Currency": "CNY",
                    "RealTotalCost": "150.5",
                    "Cash": "150.5",
                    "SummaryOverview": [
                        [
                            "ProductCode": "KEC",
                            "ProductName": "云服务器",
                            "RealTotalCost": "100",
                            "Cash": "100",
                            "BillMonth": "2026-08",
                        ],
                        [
                            "ProductCode": "KS3",
                            "ProductName": "对象存储",
                            "RealTotalCost": "50.5",
                            "Cash": "50.5",
                            "BillMonth": "2026-08",
                        ],
                        [
                            "ProductCode": "EIP",
                            "ProductName": "弹性IP",
                            "RealTotalCost": "0",
                            "BillMonth": "2026-08",
                        ],
                    ] as [[String: Any]],
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
        #expect(request.url?.host == KingsoftCloudBillingProvider.apiHost)
        #expect(request.url?.absoluteString.contains("Action=DescribeBillSummaryByProduct") == true)
        #expect(request.url?.absoluteString.contains("BillBeginMonth=2026-08") == true)
        #expect(request.url?.absoluteString.contains("BillEndMonth=2026-08") == true)
        #expect(request.url?.absoluteString.contains("Service=bill-union") == true)
        #expect(request.url?.absoluteString.contains("Signature=") == true)
        #expect(request.url?.absoluteString.contains("Accesskey=") == true)
        #expect(!(request.url?.absoluteString.contains(secretKey) ?? true))
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test("401 / 403")
    func statusMapping() async {
        let stubURL = URL(string: "https://\(KingsoftCloudBillingProvider.apiHost)/")!
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

    @Test("简化版 HMAC-SHA256 与官方签名 DEMO 一致")
    func signatureMatchesOfficialDemo() {
        let params: [String: String] = [
            "Accesskey": "AKLTXQVF0pOmS6aahIrD5r0B3Q",
            "Service": "iam",
            "Action": "CreateUser",
            "Version": "2015-11-01",
            "Timestamp": "2021-08-12T02:47:36Z",
            "SignatureVersion": "1.0",
            "SignatureMethod": "HMAC-SHA256",
            "UserName": "Ttest",
            "RealName": "周四测试",
            "Email": "zsce@kkingsoft.com",
            "Remark": "~ce shi*%#|+",
        ]
        let sig = KingsoftCloudBillingProvider.sign(
            params: params,
            secretKey: "OMovU5PTLh6y9E9Ioe3K411jt99VqyQSBXgAcDYlo49R3lvUIzb6e/efZCFDmtFlzw=="
        )
        #expect(sig == "fc9088ab845949dac4040be9b7ce7859068b5c21d4c400fec8ee0cefb777f659")
        #expect(KingsoftCloudBillingProvider.percentEncode("a b*") == "a%20b%2A")
        #expect(KingsoftCloudBillingProvider.billMonth(now, calendar: calendar) == "2026-08")
    }

    private func provider(_ client: RecordingHTTPClient) -> KingsoftCloudBillingProvider {
        KingsoftCloudBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["CNY": cnyRate]))
        )
    }

    private func credential() -> Credential {
        Credential(providerID: .kingsoftcloud, fields: [
            .accessKeyID: accessKey,
            .secretAccessKey: secretKey,
        ])
    }
}
