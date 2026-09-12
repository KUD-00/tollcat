import Foundation
import MeterCore
import MeterFormat

public struct BalanceAlertItem: Identifiable, Equatable, Sendable {
    public var accountID: AccountID
    public var providerID: ProviderID
    public var displayName: String
    public var colorKey: String
    public var balanceUSD: Money
    public var daysRemaining: Int
    public var presentation: MoneyPresentation = .usd

    public init(
        accountID: AccountID,
        providerID: ProviderID,
        displayName: String,
        colorKey: String,
        balanceUSD: Money,
        daysRemaining: Int,
        presentation: MoneyPresentation = .usd
    ) {
        self.accountID = accountID
        self.providerID = providerID
        self.displayName = displayName
        self.colorKey = colorKey
        self.balanceUSD = balanceUSD
        self.daysRemaining = daysRemaining
        self.presentation = presentation
    }

    public var id: AccountID { accountID }

    public var caption: String {
        String(localized: L("\(displayName) 余额 \(balanceUSD.formatted(using: presentation)) · 按当前速度还能用 \(daysRemaining) 天"))
    }

    public var balanceCaption: String {
        String(localized: L("余额 \(balanceUSD.formatted(using: presentation))"))
    }

    public var trailingText: String {
        String(localized: L("\(daysRemaining) 天"))
    }

    public var spokenCaption: String {
        String(localized: L("\(displayName) 余额 \(SpokenMoney.label(for: balanceUSD, presentation: presentation))，按当前速度还能用 \(daysRemaining) 天"))
    }
}
