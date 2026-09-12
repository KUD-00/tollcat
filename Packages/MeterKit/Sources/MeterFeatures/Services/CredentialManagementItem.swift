import Foundation
import MeterCore

/// 「管理凭据」页里的一行。标题是昵称，不是厂商名——已经在这家详情里了。
struct CredentialManagementItem: Identifiable, Equatable, Sendable {
    var accountID: AccountID
    var title: String
    var caption: String
    var canRotate: Bool

    var id: AccountID { accountID }
}
