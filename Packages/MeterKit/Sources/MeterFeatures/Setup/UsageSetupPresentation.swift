import SwiftUI
import MeterDesign

/// 连接参考抽屉：手机按正文收高度，可拉开；iPad 双栏，走 page sheet。
struct UsageSetupPresentation: ViewModifier {
    var usesPadChrome: Bool
    var height: CGFloat

    func body(content: Content) -> some View {
        content.meterDrawerChrome(
            usesPadChrome ? .page : .expandable(height),
            usesPadChrome: usesPadChrome
        )
    }
}
