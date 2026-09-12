import Foundation
import MeterCore

struct InboxRefreshTarget: Sendable {
    var accountID: AccountID
    var providerID: ProviderID
    /// 配置缺失时 nil → 该行 failure。
    var ingestKeyID: String?
}
