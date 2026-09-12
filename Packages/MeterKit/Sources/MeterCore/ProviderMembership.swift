import Foundation

/// 这家加进了服务列表。可以还没有用量身份。
public struct ProviderMembership: Hashable, Sendable, Codable {
    public var providerID: ProviderID
    public var sortIndex: Int

    public init(providerID: ProviderID, sortIndex: Int) {
        self.providerID = providerID
        self.sortIndex = sortIndex
    }
}
