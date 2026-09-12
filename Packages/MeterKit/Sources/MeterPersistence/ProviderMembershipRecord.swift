import Foundation
import SwiftData
import MeterCore

/// 厂商门口。服务列表一行对应这里一行，不是用量账号。
@Model
public final class ProviderMembershipRecord {
    @Attribute(.unique)
    public var providerIDRaw: String
    public var sortIndex: Int

    public init(providerID: ProviderID, sortIndex: Int) {
        self.providerIDRaw = providerID.rawValue
        self.sortIndex = sortIndex
    }

    public var providerID: ProviderID {
        ProviderID(providerIDRaw)
    }

    public var membership: ProviderMembership {
        ProviderMembership(providerID: providerID, sortIndex: sortIndex)
    }
}
