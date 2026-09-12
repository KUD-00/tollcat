import Foundation

/// 三档消耗型 IAP。ID 必须和 App Store Connect / `TollCat.storekit` 一致。
public enum TipProductID: String, CaseIterable, Sendable {
    case small = "com.zhechengqi.tollcat.tip.small"
    case medium = "com.zhechengqi.tollcat.tip.medium"
    case large = "com.zhechengqi.tollcat.tip.large"

    public static var allRawValues: [String] {
        allCases.map(\.rawValue)
    }

    /// 历史记录和拿不到 StoreKit 名称时的档位名。不是价格。
    public var listTitle: String {
        switch self {
        case .small: String(localized: L("糖果"))
        case .medium: String(localized: L("咖啡"))
        case .large: String(localized: L("披萨"))
        }
    }

    public var sortIndex: Int {
        switch self {
        case .small: 0
        case .medium: 1
        case .large: 2
        }
    }
}
