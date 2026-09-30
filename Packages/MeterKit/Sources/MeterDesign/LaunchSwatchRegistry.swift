import Observation
import SwiftUI

/// 冷启动过渡要知道构成图例里每颗色块在屏幕上的位置和颜色：口袋里的圆牌要飞过去落在上面。
///
/// 只在启动过渡那一两秒里注入；小组件、菜单栏、分享卡拿不到它，图例照常画。
@MainActor
@Observable
public final class LaunchSwatchRegistry {
    public struct Swatch: Equatable {
        public var frame: CGRect
        public var color: Color
    }

    /// 图例段 id → 色块（`.global` 坐标）。
    public private(set) var swatches: [String: Swatch] = [:]
    /// 圆牌还在路上的那几颗先藏起来，落地那一刻再露出来。
    public var hidden: Set<String> = []

    public init() {}

    func report(id: String, swatch: Swatch) {
        if swatches[id] != swatch {
            swatches[id] = swatch
        }
    }
}

private struct LaunchSwatchRegistryKey: EnvironmentKey {
    static let defaultValue: LaunchSwatchRegistry? = nil
}

extension EnvironmentValues {
    public var launchSwatchRegistry: LaunchSwatchRegistry? {
        get { self[LaunchSwatchRegistryKey.self] }
        set { self[LaunchSwatchRegistryKey.self] = newValue }
    }
}

/// 图例色块把自己报给启动过渡。没注入 registry 时什么都不做。
///
/// 放在 MeterDesign：量位置这件事不能出现在 MeterModules 里（模块不许自己量宽，
/// `ArchitectureGuardrailTests` 按源码扫），模块只调 `launchSwatch(id:color:)`。
struct LaunchSwatchReporter: ViewModifier {
    let id: String
    let color: Color
    @Environment(\.launchSwatchRegistry) private var registry
    @Environment(\.self) private var environment

    func body(content: Content) -> some View {
        if let registry {
            content
                .opacity(registry.hidden.contains(id) ? 0 : 1)
                .onGeometryChange(for: CGRect.self) { proxy in
                    proxy.frame(in: .global)
                } action: { frame in
                    // 按图例自己的深浅色取定：覆盖层按系统深浅色画，动态色到它那边会解析成另一种。
                    registry.report(id: id, swatch: .init(frame: frame, color: Color(color.resolve(in: environment))))
                }
        } else {
            content
        }
    }
}

extension View {
    public func launchSwatch(id: String, color: Color) -> some View {
        modifier(LaunchSwatchReporter(id: id, color: color))
    }
}
