import Foundation
import MeterCore

/// 较上月同期详情里的一行。`previousUSD == nil` 是这家还不能比。
/// 无主订阅段 `accountID` 为 nil：挂厂商的走 `providerID` 进详情页，
/// 完全不归属的「手动订阅」两头都空，摆成普通行。
public struct ComparisonItem: Identifiable, Equatable, Hashable, Sendable {
    public var accountID: AccountID?
    public var providerID: ProviderID?
    public var displayName: String
    public var colorKey: String
    public var currentUSD: Money
    public var previousUSD: Money?
    public var changeRatio: Double?
    public var presentation: MoneyPresentation = .usd
    /// 详情页里挂在这一行下面的子服务小行（只有花了钱的）。模块卡不画它。
    public var sublines: [SpendSubline] = []

    public init(
        accountID: AccountID? = nil,
        providerID: ProviderID? = nil,
        displayName: String,
        colorKey: String,
        currentUSD: Money,
        previousUSD: Money? = nil,
        changeRatio: Double? = nil,
        presentation: MoneyPresentation = .usd,
        sublines: [SpendSubline] = []
    ) {
        self.accountID = accountID
        self.providerID = providerID
        self.displayName = displayName
        self.colorKey = colorKey
        self.currentUSD = currentUSD
        self.previousUSD = previousUSD
        self.changeRatio = changeRatio
        self.presentation = presentation
        self.sublines = sublines
    }

    public var id: String {
        accountID?.rawValue.uuidString ?? "unattached-\(providerID?.rawValue ?? "manual")"
    }

    public var isComparable: Bool { previousUSD != nil }

    public var tone: ComparisonModuleContent.Tone {
        guard isComparable else { return .unknown }
        guard let changeRatio else { return .flat }
        if changeRatio > 0 { return .up }
        if changeRatio < 0 { return .down }
        return .flat
    }

    /// 明细要两头都写：只写同期额，读者看不出「本月到底花了多少」。
    public func subtitle(previousMonthName: String) -> String {
        if let previousUSD {
            return String(
                localized: L("本月 \(currentUSD.formatted(using: presentation)) · \(previousMonthName)同期 \(previousUSD.formatted(using: presentation))")
            )
        }
        return String(localized: L("还不能对比"))
    }

    public var trailingText: String {
        if let changeRatio {
            return DashboardPercentFormat.signed(changeRatio)
        }
        if isComparable {
            return String(localized: L("持平"))
        }
        return currentUSD.formatted(using: presentation)
    }

    public func spokenLabel(previousMonthName: String) -> String {
        let amount = currentUSD.formatted(using: presentation)
        if let changeRatio {
            return String(
                localized: L(
                    "\(displayName) 较上月同期 \(DashboardPercentFormat.spokenSigned(changeRatio))，\(subtitle(previousMonthName: previousMonthName))"
                )
            )
        }
        if isComparable {
            return String(localized: L("\(displayName) 较上月同期持平，本月 \(amount)"))
        }
        return String(localized: L("\(displayName) 本月 \(amount)，还不能和上月同期对比"))
    }
}
