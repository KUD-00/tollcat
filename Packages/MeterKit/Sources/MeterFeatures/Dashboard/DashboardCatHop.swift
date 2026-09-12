import SwiftUI
import MeterDesign
import MeterModules

/// 换落点时跳一下，不要在卡面上滑过去。左右翻转不走这条动画——`scaleEffect`
/// 过 0 会把猫挤没。
struct DashboardCatHop: ViewModifier {
    var placement: DashboardCatPlacement
    var perch: DashboardCatPerch

    func body(content: Content) -> some View {
        content
            .scaleEffect(x: placement.isFlipped ? -1 : 1, y: 1)
            .transaction(value: placement.isFlipped) { $0.animation = nil }
            .rotationEffect(.degrees(placement.rotationDegrees))
            .offset(x: placement.x, y: placement.y)
            .modifier(Lift(trigger: perch))
            .animation(DashboardMotion.hop, value: perch)
            .animation(DashboardMotion.expand, value: placement.x)
            .animation(DashboardMotion.expand, value: placement.y)
            .animation(DashboardMotion.expand, value: placement.rotationDegrees)
    }

    private struct Lift: ViewModifier {
        var trigger: DashboardCatPerch

        func body(content: Content) -> some View {
            KeyframeAnimator(initialValue: CGFloat.zero, trigger: trigger) { lift in
                content.offset(y: lift)
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(-MeterSpacing.md, duration: DashboardMotion.hopUp)
                    CubicKeyframe(0, duration: DashboardMotion.hopDown)
                }
            }
        }
    }
}
