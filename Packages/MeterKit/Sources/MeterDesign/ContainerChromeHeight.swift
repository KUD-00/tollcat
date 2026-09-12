import SwiftUI

/// 量导航栏 + Home Indicator，不含键盘。
///
/// 键盘也在 `safeAreaInsets.bottom` 里。把它加进 sheet 的 `.height`
/// detent，点输入框抽屉会跟着长一截。安全区会跟着抽屉高度抖几pt，
/// 不能原样写回 detent，否则 presentation preference 循环。
public struct ContainerChromeHeight: ViewModifier {
    @Binding var height: CGFloat

    public init(height: Binding<CGFloat>) {
        self._height = height
    }

    public func body(content: Content) -> some View {
        content
            .background {
                Color.clear
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
                    .ignoresSafeArea(.keyboard)
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
                    } action: { proposed in
                        height = SoftwareKeyboard.acceptedChromeHeight(
                            current: height,
                            proposed: proposed
                        )
                    }
            }
    }
}

public extension View {
    func meterContainerChromeHeight(_ height: Binding<CGFloat>) -> some View {
        modifier(ContainerChromeHeight(height: height))
    }
}
