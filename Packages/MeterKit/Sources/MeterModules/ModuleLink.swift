import SwiftUI

/// 模块里「点进去看详情」的链接。
///
/// 模块自己**不知道**怎么推页：iPhone 推系统栈、Mac 推列内手工栈、iPad 侧栏要先切回
/// 仪表盘那一列，而 widget 和分享卡根本推不动。这些都是壳的事。
/// 所以模块只说「用户想去哪」（`DashboardRoute`），怎么去由壳注入。
///
/// 没人注入时链接**退化成纯 label**：widget 和分享卡拿到的正是这个——
/// 不是一个点了没反应的按钮，而是压根没有按钮。
public struct ModuleLinkStyle {
    /// 整行可点：外面那层负责补 chevron 和热区，并声明 `moduleRowChromeFromLink`。
    public var row: (DashboardRoute, AnyView) -> AnyView
    /// 行内那种自己画箭头的链接（「查看更多 ›」）。
    public var inline: (DashboardRoute, AnyView) -> AnyView

    public init(
        row: @escaping (DashboardRoute, AnyView) -> AnyView,
        inline: @escaping (DashboardRoute, AnyView) -> AnyView
    ) {
        self.row = row
        self.inline = inline
    }
}

public extension EnvironmentValues {
    /// 壳注入的推页方式。nil = 这个壳推不动页（widget、分享卡）。
    @Entry var moduleLinkStyle: ModuleLinkStyle?
}

/// 整行可点的链接。壳没注入就只画 label。
public struct ModuleLink<Label: View>: View {
    public var route: DashboardRoute
    @ViewBuilder public var label: () -> Label
    @Environment(\.moduleLinkStyle) private var style

    public init(route: DashboardRoute, @ViewBuilder label: @escaping () -> Label) {
        self.route = route
        self.label = label
    }

    public var body: some View {
        if let style {
            style.row(route, AnyView(label()))
        } else {
            label()
        }
    }
}

/// 自己画箭头的行内链接（「查看更多 ›」）。壳没注入就整个不画：
/// 一张图上的「查看更多」是假线索。
public struct ModuleInlineLink<Label: View>: View {
    public var route: DashboardRoute
    @ViewBuilder public var label: () -> Label
    @Environment(\.moduleLinkStyle) private var style

    public init(route: DashboardRoute, @ViewBuilder label: @escaping () -> Label) {
        self.route = route
        self.label = label
    }

    @ViewBuilder
    public var body: some View {
        if let style {
            style.inline(route, AnyView(label()))
        }
    }
}
