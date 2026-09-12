import SwiftUI
import WidgetKit
import MeterModules

/// 一格 widget = 仪表盘上的一块模块。
///
/// 这里只做 WidgetKit 那一层：**这块地方有多大、整块点了去哪、行能不能点**。
/// 画什么一律交给 `WidgetModuleTile`（在 MeterModules 里，内部走
/// `DashboardModuleFactory`）——商店宣传图上的小组件渲的是同一份视图，
/// 主屏上那一格和图上那一格不会各走各的。
struct TollCatWidgetView: View {
    let entry: TollCatWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        // 量的是 widget 分给内容的那块地方，模块自己不许量（那是反馈环）。
        // 这一层是容器，量了只往下传，不回填自己的尺寸。
        GeometryReader { proxy in
            WidgetModuleTile(
                module: entry.module,
                contents: entry.contents,
                presentation: entry.presentation,
                isEmpty: entry.isEmpty,
                contentSize: proxy.size,
                linkStyle: linkStyle
            )
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
        .containerBackground(for: .widget) { Color.clear }
        // 整块的落点。系统在 systemSmall 上只认这一个，medium / large 上它是
        // 行与行之间空白处的兜底。
        .widgetURL(DashboardDeepLink.dashboardURL)
    }

    /// 一行一个落点：点哪家进哪家。systemSmall 上不给——整块只有一个 `widgetURL`，
    /// 再嵌 `Link` 只会让 146pt 见方里出现一堆抢焦点的小热区。
    private var linkStyle: ModuleLinkStyle? {
        guard family != .systemSmall else { return nil }
        return ModuleLinkStyle(
            row: { route, label in AnyView(Link(destination: route.deepLinkURL) { label }) },
            inline: { route, label in AnyView(Link(destination: route.deepLinkURL) { label }) }
        )
    }
}
