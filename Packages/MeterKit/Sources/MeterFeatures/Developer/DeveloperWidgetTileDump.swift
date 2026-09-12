#if DEBUG
import SwiftUI
import MeterCore
import MeterDesign
import MeterModules
import MeterPersistence

/// 把每一格小组件渲成 PNG 落到沙盒里，供商店宣传图的主屏 mock-up 用。
///
/// 为什么要有这一条路：主屏上的小组件**截不到**——`simctl` 不认识 widget，
/// 往模拟器主屏上加一格只能靠人手点。可宣传图上那几格又不能照着重画一版 HTML：
/// 那就是第二套小组件，迟早和用户装到主屏上的那一格漂开。
///
/// 所以图上那几格渲的是 `WidgetModuleTile`——widget 扩展用的同一份视图、
/// 同一份 `DashboardContents`（就是这台机器上仪表盘正在显示的那份，所以图上的
/// 数字和同一批截图里的仪表盘对得上）、`shared/widgets.json` 里的同一组尺寸。
/// 只渲**内容**那一块：底材（壁纸上的毛玻璃）和圆角在图那一层画，App 里画不出来。
@MainActor
enum DeveloperWidgetTileDump {
    /// 沙盒 Documents 下的落点。脚本用 `simctl get_app_container … data` 取。
    static let directoryName = "widget-tiles"

    /// 渲成几倍图。和截图同一档（@3x），图那一层就不用再缩放。
    static let renderScale: CGFloat = 3

    /// 这台机器上的一格有多大。**手机和 iPad 不是同一组数**（iPad 的 4×4 是正方的），
    /// 所以两边各跑一趟，出来的是两套素材。
    static var idiom: ModuleWidgetIdiom {
        #if canImport(UIKit)
        UIDevice.current.userInterfaceIdiom == .pad ? .pad : .phone
        #else
        .phone
        #endif
    }

    @discardableResult
    static func write(
        dashboard: DashboardModel,
        appearance: AppearancePreference
    ) async -> URL? {
        // 种子是启动时同步写的，但折算落到这些字段上要过一轮。等它有内容再渲——
        // 早一帧渲出来的是一叠「这一块暂时没有数据」，而且没人会发现。
        //
        // 判据不能只是「`availableModuleIDs` 非空」：仪表盘缓存会先铺一份**空的**
        // 首帧——本月合计 $0.00、钉选的几家也都是 $0.00，构成和热力图还是 nil。
        // 那一帧照样满足「有模块」，于是这个循环第一轮就退出，渲出来是一整页零
        // 加两块「这一块暂时没有数据」。得等真的有钱数落下来。
        for _ in 0..<80 where !hasContent(dashboard) {
            try? await Task.sleep(for: .milliseconds(100))
        }
        guard let root = try? destination() else { return nil }
        for module in DashboardModuleID.widgetModules {
            for size in module.widgetSizes {
                guard let image = render(
                    module: module,
                    size: size,
                    dashboard: dashboard,
                    appearance: appearance
                ),
                    let data = RasterImage.pngData(from: image)
                else {
                    continue
                }
                let file = root.appendingPathComponent(
                    "\(idiom.rawValue)-\(module.rawValue)-\(size.rawValue).png"
                )
                try? data.write(to: file, options: .atomic)
            }
        }
        return root
    }

    /// 「这一份仪表盘上真的有账单了」。空的首帧过不了第二个条件。
    private static func hasContent(_ dashboard: DashboardModel) -> Bool {
        guard !dashboard.availableModuleIDs.isEmpty else { return false }
        guard let total = dashboard.monthToDate?.totalUSD else { return false }
        return total > .zero
    }

    private static func destination() throws -> URL {
        let documents = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let root = documents.appendingPathComponent(directoryName, isDirectory: true)
        // 每次重来：模块少了一格时，上一轮的旧图不该留在目录里冒充新的。
        try? FileManager.default.removeItem(at: root)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    /// 背景透明：底材由图那一层画。语义色（`Color.meterLabel` 那些）解析的是
    /// **当前绘制环境**而不是 SwiftUI 的 `colorScheme`，所以明暗两套都得把 trait
    /// 压成对应那一档——不压的话，深色那一轮渲出来还是黑字。
    private static func render(
        module: DashboardModuleID,
        size: ModuleWidgetSize,
        dashboard: DashboardModel,
        appearance: AppearancePreference
    ) -> CGImage? {
        let scheme = appearance.preferredColorScheme ?? .light
        let content = size.contentSize(idiom)
        let tile = WidgetModuleTile(
            module: module,
            contents: dashboard,
            presentation: dashboard.moneyPresentation,
            isEmpty: false,
            contentSize: content,
            // 图上点不动：一行一个落点在这里只会渲成一堆蓝字。
            linkStyle: nil
        )
        .frame(width: content.width, height: content.height, alignment: .topLeading)
        .environment(\.colorScheme, scheme)
        .environment(\.dynamicTypeSize, .large)
        return withTrait(scheme) {
            let renderer = ImageRenderer(content: tile)
            renderer.scale = renderScale
            renderer.isOpaque = false
            renderer.proposedSize = ProposedViewSize(content)
            return renderer.cgImage
        }
    }

    private static func withTrait(_ scheme: ColorScheme, _ body: () -> CGImage?) -> CGImage? {
        #if canImport(UIKit)
        var image: CGImage?
        UITraitCollection(userInterfaceStyle: scheme == .dark ? .dark : .light)
            .performAsCurrent { image = body() }
        return image
        #else
        return body()
        #endif
    }
}
#endif
