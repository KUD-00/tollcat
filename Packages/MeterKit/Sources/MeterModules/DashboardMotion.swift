import SwiftUI

/// 账单数字不需要炫技。时长写在这里，避免视图里散落 0.45。
public enum DashboardMotion {
    /// DESIGN-BAR：`.snappy`，不超过 0.5s。
    public static let number = Animation.snappy(duration: 0.45)

    /// 构成卡就地展开。用 smooth 不弹，数字滚动才用 snappy。
    public static let expand = Animation.smooth(duration: 0.45)

    /// 猫换落点。不弹，总时长仍低于 0.5s。
    public static let hop = Animation.smooth(duration: 0.42)
    public static let hopUp: TimeInterval = 0.16
    public static let hopDown: TimeInterval = 0.26
}
