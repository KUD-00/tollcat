import Foundation
import MeterCore

/// 构成条上的一段。fraction 驱动宽度动画，percent 只给文案。
///
/// 无主订阅（挂厂商或完全不归属的手动订阅）也占一段，否则「含订阅」口径下
/// 饼图加不回大数字。它们的 `accountID` 是 nil：挂厂商的靠 `providerID`
/// 推进详情，完全不归属的两头都空。
public struct CompositionSegment: Identifiable, Equatable, Sendable {
    public var accountID: AccountID?
    public var providerID: ProviderID?
    public var displayName: String
    public var colorKey: String
    public var amount: Money
    public var fraction: Double
    public var percent: Int
    /// 详情页里挂在这一段下面的子服务小行（只有花了钱的）。模块卡不画它。
    public var sublines: [SpendSubline] = []

    public init(
        accountID: AccountID? = nil,
        providerID: ProviderID? = nil,
        displayName: String,
        colorKey: String,
        amount: Money,
        fraction: Double,
        percent: Int,
        sublines: [SpendSubline] = []
    ) {
        self.accountID = accountID
        self.providerID = providerID
        self.displayName = displayName
        self.colorKey = colorKey
        self.amount = amount
        self.fraction = fraction
        self.percent = percent
        self.sublines = sublines
    }

    public var id: String {
        accountID?.rawValue.uuidString ?? "unattached-\(providerID?.rawValue ?? "manual")"
    }
}
