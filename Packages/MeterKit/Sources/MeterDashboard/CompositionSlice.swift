import Foundation
import MeterCore

/// 构成图例上的一段：前 `CompositionSliceBuilder.namedLimit` 名各占一段，其余并成「其他」。
///
/// 金额已经按显示币种写好。跟随端（Android / Windows / CLI）直接画它，
/// **不要把几段的 `amountText` 解析回数字再相加**——那是已经换算过的钱，
/// 再当美元换一遍就会放大几倍到几百倍。
public struct CompositionSlice: Identifiable, Equatable, Sendable {
    public var id: String
    public var accountID: AccountID?
    public var providerID: ProviderID?
    public var displayName: String
    public var colorKey: String
    public var amount: Money
    public var amountText: String
    public var spokenAmount: String
    public var fraction: Double
    /// 各段按最大余数法取整，加起来正好 100；「其他」是并进来那几段之和。
    public var percent: Int
    public var isOther: Bool
    /// 只有「其他」有：并进来的那几家，读屏要念出来。
    public var mergedNames: [String]

    public init(
        id: String,
        accountID: AccountID? = nil,
        providerID: ProviderID? = nil,
        displayName: String,
        colorKey: String,
        amount: Money,
        amountText: String,
        spokenAmount: String,
        fraction: Double,
        percent: Int,
        isOther: Bool = false,
        mergedNames: [String] = []
    ) {
        self.id = id
        self.accountID = accountID
        self.providerID = providerID
        self.displayName = displayName
        self.colorKey = colorKey
        self.amount = amount
        self.amountText = amountText
        self.spokenAmount = spokenAmount
        self.fraction = fraction
        self.percent = percent
        self.isOther = isOther
        self.mergedNames = mergedNames
    }
}
