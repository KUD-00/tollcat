import Foundation
import MeterCore

/// fact 在构成 / 对比里的归属段。两张图共用同一套规则，才说同一批「家」。
///
/// - 挂账号 → 该账号一段；
/// - 挂厂商的无主订阅：该厂商**恰有一个**已接账号时并进那个账号
///   （行能点进详情），否则单独一段，名字就写厂商——多账号时账号段
///   自带昵称后缀（AccountTitle），不会和光写厂商名的这段撞名；
/// - 完全不归属 → 合成「手动订阅」一段。
public enum SpendAttribution: Hashable {
    case account(AccountID)
    case vendor(ProviderID)
    case manual

    public static func attribute(
        _ fact: Fact,
        connections: [ProviderConnectionState]
    ) -> SpendAttribution {
        attribute(accountID: fact.accountID, providerID: fact.providerID, connections: connections)
    }

    /// 订阅走同一条规则：订阅 fact 就是拿订阅的 (accountID, providerID) 建的，
    /// 子行 builder 直接从订阅算归属时必须得出同一个段，否则钱挂错行。
    public static func attribute(
        accountID: AccountID?,
        providerID: ProviderID?,
        connections: [ProviderConnectionState]
    ) -> SpendAttribution {
        if let accountID { return .account(accountID) }
        guard let providerID else { return .manual }
        let accounts = connections.filter { $0.isEnabled && $0.providerID == providerID }
        if accounts.count == 1, let only = accounts.first {
            return .account(only.accountID)
        }
        return .vendor(providerID)
    }

    /// 金额并列时的稳定排序键。账号段沿用 uuid 字符串（旧行为），无主段用前缀串。
    public var sortKey: String {
        switch self {
        case .account(let id): id.rawValue.uuidString
        case .vendor(let providerID): "vendor-\(providerID.rawValue)"
        case .manual: "zz-manual"
        }
    }
}
