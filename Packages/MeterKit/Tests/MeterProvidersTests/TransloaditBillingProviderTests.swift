import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct TransloaditBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let authKey = "transloadit-key-publicish"
    private let authSecret = "transloadit-secret-MUST-NOT-LEAK"

    @Test("total 是本月应付")
    func readsTotal() async throws {
        let client = LiveProviderHarness.stub([
            (billURL, LiveProviderHarness.body(LiveProviderHarness.fixture("transloadit-bill"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "115.45")!))
        #expect(client.leakedSecrets([authSecret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("签名认证走 params + sha384 signature，密钥不进 URL")
    func usesSignatureAuth() async throws {
        let client = LiveProviderHarness.stub([
            (billURL, LiveProviderHarness.body(LiveProviderHarness.fixture("transloadit-bill"))),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        let url = try #require(request.url)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let params = try #require(items.first(where: { $0.name == "params" })?.value)
        let signature = try #require(items.first(where: { $0.name == "signature" })?.value)
        #expect(params.contains(authKey))
        #expect(signature.hasPrefix("sha384:"))
        #expect(signature == TransloaditBillingProvider.signature(params: params, secret: authSecret))
        #expect(!(url.absoluteString.contains(authSecret)))
    }

    @Test("零 total 是 $0，不是没读到")
    func zeroTotalIsZero() async throws {
        let client = LiveProviderHarness.stub([
            (billURL, LiveProviderHarness.json(["ok": "BILL_FOUND", "total": 0] as [String: Any])),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == .zero)
    }

    @Test("缺 total 是畸形响应")
    func missingTotal() async {
        let client = LiveProviderHarness.stub([
            (billURL, LiveProviderHarness.json(["ok": "BILL_FOUND"] as [String: Any])),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .malformedResponse)
    }

    @Test("401 / 403")
    func statusMapping() async {
        await expectStatus(401, code: .unauthorized, key: .invalidCredentials)
        await expectStatus(403, code: .forbidden, key: .insufficientPermissions)
    }

    private func expectStatus(
        _ status: Int,
        code: ProviderError.Code,
        key: RemediationKey
    ) async {
        await LiveProviderHarness.expectStatus(status, code: code, key: key) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (billURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
    }

    private var billURL: URL {
        let params = TransloaditBillingProvider.paramsJSON(
            authKey: authKey,
            expires: now.addingTimeInterval(3600)
        )
        let signature = TransloaditBillingProvider.signature(params: params, secret: authSecret)
        return TransloaditBillingProvider.billURL(month: "2026-08", params: params, signature: signature)
    }

    private var credential: Credential {
        Credential(
            providerID: .transloadit,
            fields: [.clientID: authKey, .clientSecret: authSecret]
        )
    }

    private func provider(_ client: any HTTPClient) -> TransloaditBillingProvider {
        TransloaditBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
