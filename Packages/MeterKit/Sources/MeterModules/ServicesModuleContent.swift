import Foundation
import MeterCore

/// 「特别关心」：用户钉出来的几家，每家一行 / 一张卡。\n/// 类型名仍叫 Services*：`DashboardModuleID.services` 的 rawValue 落在偏好里（版式顺序），\n/// 改它等于让老用户的版式失效——名字换了，键没换。
public struct ServicesModuleContent: Equatable, Sendable {
    public var items: [ServiceCardItem]

    public init(items: [ServiceCardItem]) {
        self.items = items
    }

    public var animationSignature: [Double] { items.map(\.amountValue) }
}

public struct ServiceCardItem: Identifiable, Equatable, Sendable {
    public var accountID: AccountID
    public var providerID: ProviderID
    public var displayName: String
    public var colorKey: String
    public var amountText: String
    public var amountValue: Double
    public var spokenAmount: String
    /// 较上月同期。比不了（上月没数）就 nil。
    public var changeText: String?
    public var changeIsUp: Bool
    /// 近 30 天按量，旧到新，缺的天记 0。只表示走势方向，不标数。
    /// 拿不到按日粒度的家是空数组——行上就不画线。
    public var spark: [Double]

    public init(
        accountID: AccountID,
        providerID: ProviderID,
        displayName: String,
        colorKey: String,
        amountText: String,
        amountValue: Double,
        spokenAmount: String,
        changeText: String? = nil,
        changeIsUp: Bool,
        spark: [Double]
    ) {
        self.accountID = accountID
        self.providerID = providerID
        self.displayName = displayName
        self.colorKey = colorKey
        self.amountText = amountText
        self.amountValue = amountValue
        self.spokenAmount = spokenAmount
        self.changeText = changeText
        self.changeIsUp = changeIsUp
        self.spark = spark
    }

    public var id: AccountID { accountID }

    public var spokenLabel: String {
        var parts = [displayName, spokenAmount]
        if let changeText { parts.append(changeText) }
        return parts.joined(separator: "，")
    }
}
