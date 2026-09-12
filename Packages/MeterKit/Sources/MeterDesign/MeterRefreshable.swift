import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// 下拉刷新。系统转圈是 loading，刷新时不许出现：旧数据留着，完成靠数字滚动和触觉。
/// Mac 没有下拉刷新：走工具栏和 ⌘R。
public struct MeterRefreshable: ViewModifier {
    var action: () async -> Void

    public func body(content: Content) -> some View {
        #if os(macOS)
        content
        #else
        content
            .refreshable { await action() }
            .background {
                RefreshControlHider()
                    .frame(width: 0, height: 0)
                    .accessibilityHidden(true)
            }
        #endif
    }
}

public extension View {
    func meterRefreshable(_ action: @escaping () async -> Void) -> some View {
        modifier(MeterRefreshable(action: action))
    }
}

#if os(iOS)
private struct RefreshControlHider: UIViewRepresentable {
    func makeUIView(context: Context) -> RefreshControlProbe {
        UIRefreshControl.appearance().tintColor = .clear
        return RefreshControlProbe()
    }

    func updateUIView(_ uiView: RefreshControlProbe, context: Context) {
        uiView.hide()
    }
}

private final class RefreshControlProbe: UIView {
    override func didMoveToWindow() {
        super.didMoveToWindow()
        hide()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        hide()
    }

    func hide() {
        guard let window else { return }
        hide(in: window)
    }

    private func hide(in view: UIView) {
        if let scroll = view as? UIScrollView {
            apply(to: scroll.refreshControl)
        }
        for subview in view.subviews {
            hide(in: subview)
        }
    }

    private func apply(to refresh: UIRefreshControl?) {
        guard let refresh else { return }
        refresh.tintColor = .clear
        for subview in refresh.subviews {
            subview.alpha = 0
        }
    }
}
#endif
