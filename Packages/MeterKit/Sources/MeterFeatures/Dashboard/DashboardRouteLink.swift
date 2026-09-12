import SwiftUI
import MeterDesign
import MeterModules

public extension View {
    /// 把「模块里点了链接怎么推页」注入给里面的模块视图。
    ///
    /// 模块（MeterModules）只发出路线，推法是壳的事：这里把它接到本 target 的
    /// `DashboardRouteLink` / `DashboardInlineRouteLink` 上。**不注入的壳链接就退化成
    /// 纯文字**——widget 和分享卡要的正是这个，所以别顺手在那两处也注入。
    func dashboardModuleLinks() -> some View {
        environment(
            \.moduleLinkStyle,
            ModuleLinkStyle(
                row: { route, label in
                    AnyView(DashboardRouteLink(route: route) { label })
                },
                inline: { route, label in
                    AnyView(DashboardInlineRouteLink(route: route) { label })
                }
            )
        )
    }
}

/// 仪表盘里推详情页的链接。iPhone / iPad 走系统栈（value 交给
/// `navigationDestination` 解析）；Mac 列里推手工栈——系统栈在 split 的
/// detail 里一 push 就接管整个主区，还会往窗口顶栏塞返回钮、长出一条工具栏。
/// 模块视图只知道路线，标题和目的地由 `DashboardView` 通过环境统一解析。
struct DashboardRouteLink<Label: View>: View {
    var route: DashboardRoute
    @ViewBuilder var label: () -> Label
    @Environment(\.dashboardRouteResolver) private var resolver
    @Environment(\.dashboardRouteOpener) private var opener

    var body: some View {
        if let opener {
            // 不在仪表盘那一列里（侧栏底部那张卡）：交给外面切到仪表盘再开。
            Button {
                opener(route)
            } label: {
                MacColumnLinkRow(label: label)
            }
            .buttonStyle(.plain)
        } else if let resolver {
            MeterColumnLink(
                value: route,
                title: resolver.title(route),
                destination: { resolver.destination(route) },
                label: label
            )
        } else {
            NavigationLink(value: route, label: label)
        }
    }
}

/// 卡里自己画箭头的那种链接（「查看更多 ›」）。和 `DashboardRouteLink` 的区别只在外壳：
/// 那个交给 List / Mac 列去补 chevron——系统 chevron 钉在行的右缘、颜色是三级灰，
/// 想让它跟着字走、和字同色，就只能自己画，所以这里一律渲成素按钮。
struct DashboardInlineRouteLink<Label: View>: View {
    var route: DashboardRoute
    @ViewBuilder var label: () -> Label
    /// 仪表盘那一列自己给的开页函数（Mac 推列内手工栈，其他平台推系统栈）。
    @Environment(\.dashboardInlineRouteOpener) private var inlineOpener
    /// 侧栏底部那张卡：先切到仪表盘再开。
    @Environment(\.dashboardRouteOpener) private var opener

    var body: some View {
        if let open = inlineOpener ?? opener {
            Button { open(route) } label: { label() }
                .buttonStyle(.plain)
        } else {
            // 预览和组件库里没人给开页函数，回落系统栈。
            NavigationLink(value: route, label: label)
                .buttonStyle(.plain)
        }
    }
}

/// Mac 列内推进时，路线怎么变成一页：标题给列头，目的地给手工栈。
struct DashboardRouteResolver {
    var title: (DashboardRoute) -> Text
    var destination: (DashboardRoute) -> AnyView
}

extension EnvironmentValues {
    /// 只在 Mac 的仪表盘列里有值；iPhone / iPad 为 nil，链接回落系统栈。
    @Entry var dashboardRouteResolver: DashboardRouteResolver?
    /// 仪表盘那一列之外（侧栏底部的卡）点了路线怎么办：切到仪表盘再开。
    @Entry var dashboardRouteOpener: ((DashboardRoute) -> Void)?
    /// 仪表盘这一列里，自己画箭头的链接怎么开页。四端都有值（Mac 推列内手工栈）。
    @Entry var dashboardInlineRouteOpener: ((DashboardRoute) -> Void)?
}
