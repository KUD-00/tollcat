import Foundation
import MeterCore

/// 「固定订阅」：折算每月多少，几笔，下一笔什么时候扣。
public struct SubscriptionsModuleContent: Equatable, Sendable {
    public var monthlyTotalText: String
    public var monthlyTotalValue: Double
    public var spokenTotal: String
    public var countCaption: String
    public var nextChargeCaption: String?
    public var items: [SubscriptionRowItem]

    public init(
        monthlyTotalText: String,
        monthlyTotalValue: Double,
        spokenTotal: String,
        countCaption: String,
        nextChargeCaption: String? = nil,
        items: [SubscriptionRowItem]
    ) {
        self.monthlyTotalText = monthlyTotalText
        self.monthlyTotalValue = monthlyTotalValue
        self.spokenTotal = spokenTotal
        self.countCaption = countCaption
        self.nextChargeCaption = nextChargeCaption
        self.items = items
    }

    public var animationSignature: [Double] { [monthlyTotalValue] + items.map(\.amountValue) }
}

public struct SubscriptionRowItem: Identifiable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var amountText: String
    public var amountValue: Double
    public var periodCaption: String
    public var accountID: AccountID?
    public var providerID: ProviderID?
    public var colorKey: String?
    public var spokenLabel: String

    public init(
        id: String,
        name: String,
        amountText: String,
        amountValue: Double,
        periodCaption: String,
        accountID: AccountID? = nil,
        providerID: ProviderID? = nil,
        colorKey: String? = nil,
        spokenLabel: String
    ) {
        self.id = id
        self.name = name
        self.amountText = amountText
        self.amountValue = amountValue
        self.periodCaption = periodCaption
        self.accountID = accountID
        self.providerID = providerID
        self.colorKey = colorKey
        self.spokenLabel = spokenLabel
    }
}
