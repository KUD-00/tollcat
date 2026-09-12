import Foundation

/// 一次取数可能用到的字段名。值在 `Credential` 里，这里只有键。
public enum CredentialField: String, Hashable, Sendable, Codable, CaseIterable {
    case apiToken
    case accountID
    case accessKeyID
    case secretAccessKey
    case apiKey
    case personalAccessToken
    /// Upstash Developer API 的 Basic 用户名。
    case email
    /// OAuth2 client_credentials 的一对。Atlas 服务账号、Azure 服务主体都要。
    case clientID
    case clientSecret
    /// Azure Entra 租户。换 token 的 URL 里带它，不是请求体字段。
    case tenantID
    /// RevenueCat 的 project id：一把 secret key 下可能有多个项目。
    case projectID
    /// Exa 的用量按单把 key 统计，光有 admin key 还定位不到人。
    case keyID

    /// 进远程身份指纹的字段。secret 永远 false，禁止哈希进 SwiftData。
    public var contributesToRemoteIdentity: Bool {
        switch self {
        case .apiToken, .apiKey, .secretAccessKey, .personalAccessToken, .clientSecret:
            return false
        case .accountID, .accessKeyID, .email, .clientID, .tenantID, .projectID, .keyID:
            return true
        }
    }
}
