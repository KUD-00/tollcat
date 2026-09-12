import Foundation
import MeterCore
import MeterFormat

public struct UpcomingChargeItem: Identifiable, Equatable, Sendable {
    public var id: String
    public var accountID: AccountID?
    public var providerID: ProviderID?
    public var displayName: String
    public var colorKey: String?
    public var amount: Money
    public var chargeDate: Date
    public var dateCaption: String
    public var presentation: MoneyPresentation = .usd

    public init(
        id: String,
        accountID: AccountID? = nil,
        providerID: ProviderID? = nil,
        displayName: String,
        colorKey: String? = nil,
        amount: Money,
        chargeDate: Date,
        dateCaption: String,
        presentation: MoneyPresentation = .usd
    ) {
        self.id = id
        self.accountID = accountID
        self.providerID = providerID
        self.displayName = displayName
        self.colorKey = colorKey
        self.amount = amount
        self.chargeDate = chargeDate
        self.dateCaption = dateCaption
        self.presentation = presentation
    }

    public var caption: String {
        "\(displayName) · \(amount.formatted(using: presentation)) · \(dateCaption)"
    }

    public var spokenCaption: String {
        String(localized: L("\(displayName) \(SpokenMoney.label(for: amount, presentation: presentation))，\(dateCaption)扣款"))
    }
}
