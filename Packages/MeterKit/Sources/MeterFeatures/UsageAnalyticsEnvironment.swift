import SwiftUI
import MeterUsage

private struct UsageAnalyticsKey: EnvironmentKey {
    static let defaultValue: any UsageAnalyticsRecording = NoOpUsageAnalytics()
}

public extension EnvironmentValues {
    var usageAnalytics: any UsageAnalyticsRecording {
        get { self[UsageAnalyticsKey.self] }
        set { self[UsageAnalyticsKey.self] = newValue }
    }
}

private struct SelectedAppTabKey: EnvironmentKey {
    static let defaultValue: AppTab? = nil
}

extension EnvironmentValues {
    var selectedAppTab: AppTab? {
        get { self[SelectedAppTabKey.self] }
        set { self[SelectedAppTabKey.self] = newValue }
    }
}

extension View {
    func recordsUsageScreen(_ screen: UsageAnalyticsScreen, isActive: Bool = true) -> some View {
        modifier(UsageScreenProbe(screen: screen, isActive: isActive))
    }
}

/// 当前这一屏在前台才报。Tab 切走之后子页还在内存里，不能继续报。
private struct UsageScreenProbe: ViewModifier {
    var screen: UsageAnalyticsScreen
    var isActive: Bool
    @Environment(\.usageAnalytics) private var analytics

    func body(content: Content) -> some View {
        content
            .onAppear { report() }
            .onChange(of: screen) { _, _ in report() }
            .onChange(of: isActive) { _, _ in report() }
    }

    private func report() {
        guard isActive else { return }
        analytics.record(screen)
    }
}
