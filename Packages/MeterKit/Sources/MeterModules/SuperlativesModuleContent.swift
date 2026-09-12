import Foundation
import MeterCore

/// 「之最」：三句话，各指一家。节标题跟着期间走。
public struct SuperlativesModuleContent: Equatable, Sendable {
    public var items: [SuperlativeItem]

    public init(items: [SuperlativeItem]) {
        self.items = items
    }

    public var animationSignature: [String] { items.map(\.value) }
}

public struct SuperlativeItem: Identifiable, Equatable, Sendable {
    /// 三块是哪三块、按什么顺序排，在 `MeterCore/SuperlativeSelection`——
    /// Android 桥要同一份，而它链不了这个 target。
    public typealias Kind = SuperlativeKind

    public var kind: Kind
    public var displayName: String
    public var value: String
    public var colorKey: String
    public var accountID: AccountID?
    public var providerID: ProviderID?

    public init(
        kind: Kind,
        displayName: String,
        value: String,
        colorKey: String,
        accountID: AccountID? = nil,
        providerID: ProviderID? = nil
    ) {
        self.kind = kind
        self.displayName = displayName
        self.value = value
        self.colorKey = colorKey
        self.accountID = accountID
        self.providerID = providerID
    }

    public var id: Kind { kind }

    public var title: LocalizedStringResource {
        switch kind {
        case .biggestRise: L("涨得最多")
        case .biggestShare: L("占比最大")
        case .stalest: L("最久没刷新")
        }
    }

    public var spokenLabel: String {
        "\(String(localized: title))：\(displayName)，\(value)"
    }
}
