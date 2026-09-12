import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct ProviderOAuthTests {
    private let tokenURL = AtlasBillingProvider.tokenURL

    @Test("表单按 key 排序编码，+ 和 / 都要转义")
    func encodesFormDeterministically() {
        let encoded = ProviderOAuth.encode([
            "scope": "https://management.azure.com/.default",
            "grant_type": "client_credentials",
            "client_secret": "a+b/c=d",
        ])
        #expect(encoded == [
            "client_secret=a%2Bb%2Fc%3Dd",
            "grant_type=client_credentials",
            "scope=https%3A%2F%2Fmanagement.azure.com%2F.default",
        ].joined(separator: "&"))
    }

    @Test("Basic 头是 base64(id:secret)")
    func basicIsBase64Pair() {
        #expect(ProviderOAuth.basicValue(id: "user", secret: "pass") == "dXNlcjpwYXNz")
    }

    @Test("响应里没有 access_token 就当未授权，不往下打业务接口")
    func missingTokenIsUnauthorized() async {
        let client = LiveProviderHarness.stub([
            (tokenURL, LiveProviderHarness.json(["error": "invalid_client"])),
        ])
        await #expect(throws: ProviderError.unauthorized(providerID: .atlas)) {
            _ = try await ProviderOAuth.clientCredentialsToken(
                url: tokenURL,
                basic: ("id", "secret"),
                form: ["grant_type": "client_credentials"],
                client: client,
                providerID: .atlas
            )
        }
    }

    @Test("空 token 也算未授权")
    func blankTokenIsUnauthorized() async {
        let client = LiveProviderHarness.stub([
            (tokenURL, LiveProviderHarness.json(["access_token": "   "])),
        ])
        await #expect(throws: ProviderError.unauthorized(providerID: .atlas)) {
            _ = try await ProviderOAuth.clientCredentialsToken(
                url: tokenURL,
                basic: nil,
                form: [:],
                client: client,
                providerID: .atlas
            )
        }
    }

    @Test("token 不落在 URL 上")
    func tokenNeverAppearsInURL() async throws {
        let client = LiveProviderHarness.stub([
            (tokenURL, LiveProviderHarness.json(["access_token": "secret-token"])),
        ])
        let token = try await ProviderOAuth.clientCredentialsToken(
            url: tokenURL,
            basic: ("id", "secret"),
            form: ["grant_type": "client_credentials"],
            client: client,
            providerID: .atlas
        )
        #expect(token == "secret-token")
        #expect(client.leakedSecrets(["secret-token", "secret"]).isEmpty)
    }
}
