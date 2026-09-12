import Foundation
import MeterCore

public struct FreeQuotaItem: Identifiable, Equatable, Sendable {
    public var accountID: AccountID
    public var providerID: ProviderID
    public var displayName: String
    public var colorKey: String
    public var usedRatio: Double

    public init(
        accountID: AccountID,
        providerID: ProviderID,
        displayName: String,
        colorKey: String,
        usedRatio: Double
    ) {
        self.accountID = accountID
        self.providerID = providerID
        self.displayName = displayName
        self.colorKey = colorKey
        self.usedRatio = usedRatio
    }

    public var id: AccountID { accountID }

    public var caption: String {
        DashboardPercentFormat.used(usedRatio)
    }

    public var kindCaption: String {
        String(localized: L("免费额度"))
    }

    public var trailingText: String {
        "\(Int((usedRatio * 100).rounded()))%"
    }

    public var spokenCaption: String {
        String(localized: L("\(displayName) 免费额度，\(caption)"))
    }
}
