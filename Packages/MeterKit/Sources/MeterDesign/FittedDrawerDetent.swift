import os
import SwiftUI

/// 抽屉按内容收高度。身份稳定，数字高度不进 presentation preference。
///
/// `.height(629)` / `.height(634.3)` 每次量到的值都是新档位。抽屉高度
/// 又反过来影响测量，系统会报 cyclic layout 并丢掉新值。
public struct FittedDrawerDetent: CustomPresentationDetent {
    private static let storage = OSAllocatedUnfairLock(initialState: CGFloat(0))

    public static var measuredHeight: CGFloat {
        get { storage.withLock { $0 } }
        set { storage.withLock { $0 = newValue } }
    }

    public static func height(in context: Context) -> CGFloat? {
        let fallback = MeterSpacing.catDashboard * 4
            + MeterSpacing.primaryActionBarHeight
            + MeterSpacing.xxl
        let proposed = measuredHeight > 0 ? measuredHeight : fallback
        guard proposed.isFinite, proposed > 0 else { return fallback }
        return min(proposed, context.maxDetentValue)
    }

    public static func adopt(_ proposed: CGFloat) {
        guard proposed.isFinite, proposed > 0 else { return }
        let snapped = proposed.rounded()
        storage.withLock { current in
            if current <= 0 || snapped > current + MeterSpacing.xs {
                current = snapped
            }
        }
    }
}
