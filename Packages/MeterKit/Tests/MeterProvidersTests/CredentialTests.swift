import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct CredentialTests {
    private let secret = "sk-proj-THIS_MUST_NOT_LEAK_aa11bb22"

    @Test("远程身份指纹只吃非密字段")
    func remoteIdentityTruthTable() {
        #expect(!CredentialField.apiToken.contributesToRemoteIdentity)
        #expect(!CredentialField.apiKey.contributesToRemoteIdentity)
        #expect(!CredentialField.secretAccessKey.contributesToRemoteIdentity)
        #expect(!CredentialField.personalAccessToken.contributesToRemoteIdentity)
        #expect(!CredentialField.clientSecret.contributesToRemoteIdentity)
        #expect(CredentialField.accountID.contributesToRemoteIdentity)
        #expect(CredentialField.accessKeyID.contributesToRemoteIdentity)
        #expect(CredentialField.email.contributesToRemoteIdentity)
        #expect(CredentialField.clientID.contributesToRemoteIdentity)
        #expect(CredentialField.tenantID.contributesToRemoteIdentity)
        #expect(CredentialField.projectID.contributesToRemoteIdentity)
        #expect(CredentialField.keyID.contributesToRemoteIdentity)
    }

    @Test("description 不出现密钥原文")
    func descriptionDoesNotLeakSecret() {
        let credential = Credential(
            providerID: .openai,
            fields: [.apiKey: secret]
        )

        #expect(!"\(credential)".contains(secret))
        #expect(!String(describing: credential).contains(secret))
        #expect(!String(reflecting: credential).contains(secret))
        #expect("\(credential)".contains("openai"))
        #expect("\(credential)".contains("apiKey"))
    }

    @Test("Codable 不把密钥编出去")
    func codableDoesNotEncodeSecret() throws {
        let credential = Credential(
            providerID: .aws,
            fields: [
                .accessKeyID: "AKIA_FAKE",
                .secretAccessKey: secret,
            ]
        )
        let data = try JSONEncoder().encode(credential)
        let json = String(data: data, encoding: .utf8)!

        #expect(!json.contains(secret))
        #expect(!json.contains("AKIA_FAKE"))
        #expect(json.contains("secretAccessKey") || json.contains("accessKeyID"))
    }

    @Test("取值方法能读到字段，打印仍然安全")
    func typedAccessDoesNotAffectRedaction() {
        let credential = Credential(
            providerID: .cloudflare,
            fields: [
                .apiToken: secret,
                .accountID: "acct_123456",
            ]
        )

        #expect(credential.value(for: .apiToken) == secret)
        #expect(credential.value(for: .accountID) == "acct_123456")
        #expect(!"\(credential)".contains(secret))
        #expect(!"\(credential)".contains("acct_123456"))
    }
}
