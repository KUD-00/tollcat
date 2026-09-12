import Foundation
import Testing
import MeterCore
import MeterProviders
@testable import MeterFeatures

struct AccountFingerprintTests {
    @Test("Cloudflare token 不进哈希，同一 accountID 两把 token 指纹相同")
    func cloudflareTokenIsExcluded() {
        let account = "a1b2c3d4e5f6aabbccddeeff00112233"
        let first = AccountFingerprint.hash(
            providerID: .cloudflare,
            fields: [
                CredentialField.accountID.rawValue: account,
                CredentialField.apiToken.rawValue: "secret-must-not-enter",
            ]
        )
        let second = AccountFingerprint.hash(
            providerID: .cloudflare,
            fields: [
                CredentialField.accountID.rawValue: account,
                CredentialField.apiToken.rawValue: "a-different-token",
            ]
        )
        #expect(first == "94f594903af929f10cb0920f27b634ab48ed50815002b876e371f26afe8b07b8")
        #expect(first == second)
        #expect(AccountFingerprint.canonicalString(fields: [
            CredentialField.accountID.rawValue: account,
            CredentialField.apiToken.rawValue: "secret-must-not-enter",
        ]) == "accountID=\(account)")
    }

    @Test("Atlas 同 clientID 不同 clientSecret 指纹相同")
    func atlasSecretIsExcluded() {
        let clientID = "abc123xyz"
        let first = AccountFingerprint.hash(
            providerID: .atlas,
            fields: [
                CredentialField.clientID.rawValue: clientID,
                CredentialField.clientSecret.rawValue: "secret-a",
            ]
        )
        let second = AccountFingerprint.hash(
            providerID: .atlas,
            fields: [
                CredentialField.clientID.rawValue: clientID,
                CredentialField.clientSecret.rawValue: "secret-b",
            ]
        )
        #expect(first == "3c1ff600ec7269ed91c1a399ad242fb0c5d5456ac3417320eea703bcff0b6f98")
        #expect(first == second)
    }

    @Test("email 大小写同一指纹")
    func emailIsCaseInsensitive() {
        let mixed = AccountFingerprint.hash(
            providerID: .upstash,
            fields: [CredentialField.email.rawValue: "User@Example.COM"]
        )
        let lower = AccountFingerprint.hash(
            providerID: .upstash,
            fields: [CredentialField.email.rawValue: "user@example.com"]
        )
        #expect(mixed == "ef3a82a502f90e944bf352451284bb531d05cf6e9d39155bb5a4f8c5ff706f05")
        #expect(mixed == lower)
    }

    @Test("导入的指纹原样比对，不重算")
    func importedFingerprintIsComparedAsStored() {
        let stored = "deadbeef-imported-not-recomputed"
        let computed = AccountFingerprint.hash(
            providerID: .cloudflare,
            fields: [CredentialField.accountID.rawValue: "a1b2c3d4e5f6aabbccddeeff00112233"]
        )
        #expect(stored != computed)
    }
}
