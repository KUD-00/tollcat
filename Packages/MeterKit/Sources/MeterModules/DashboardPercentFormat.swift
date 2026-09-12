import Foundation

public enum DashboardPercentFormat {
    public static func signed(_ ratio: Double) -> String {
        let percent = Int((ratio * 100).rounded())
        if percent > 0 { return "+\(percent)%" }
        if percent < 0 { return "\(percent)%" }
        return String(localized: L("持平"))
    }

    public static func spokenSigned(_ ratio: Double) -> String {
        let percent = Int((ratio * 100).rounded())
        if percent > 0 { return String(localized: L("上升百分之 \(percent)")) }
        if percent < 0 { return String(localized: L("下降百分之 \(-percent)")) }
        return String(localized: L("持平"))
    }

    public static func used(_ ratio: Double) -> String {
        let percent = Int((ratio * 100).rounded())
        return String(localized: L("用了 \(percent)%"))
    }
}
