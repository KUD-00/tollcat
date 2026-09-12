import Foundation
import MeterCore
import MeterFormat

public struct AnomalyItem: Identifiable, Equatable, Sendable {
    public var accountID: AccountID
    public var providerID: ProviderID
    public var displayName: String
    public var colorKey: String
    public var changeRatio: Double
    public var comparisonUSD: Money
    public var comparisonMonth: Int
    public var presentation: MoneyPresentation = .usd

    public init(
        accountID: AccountID,
        providerID: ProviderID,
        displayName: String,
        colorKey: String,
        changeRatio: Double,
        comparisonUSD: Money,
        comparisonMonth: Int,
        presentation: MoneyPresentation = .usd
    ) {
        self.accountID = accountID
        self.providerID = providerID
        self.displayName = displayName
        self.colorKey = colorKey
        self.changeRatio = changeRatio
        self.comparisonUSD = comparisonUSD
        self.comparisonMonth = comparisonMonth
        self.presentation = presentation
    }

    public var id: AccountID { accountID }

    public var signedPercent: String {
        DashboardPercentFormat.signed(changeRatio)
    }

    public var caption: String {
        String(localized: L("对比 \(comparisonMonthName)同期 \(comparisonUSD.formatted(using: presentation))"))
    }

    public var spokenCaption: String {
        String(localized: L("\(displayName) 较上月同期 \(DashboardPercentFormat.spokenSigned(changeRatio))，\(caption)"))
    }

    private var comparisonMonthName: String {
        MeterDateFormat.monthName(monthOfYear: comparisonMonth)
    }
}
