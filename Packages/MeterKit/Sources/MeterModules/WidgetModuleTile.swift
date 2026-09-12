import SwiftUI
import MeterCore
import MeterDesign
import MeterFormat

/// 一格 widget 里的那一块。**这里不画模块**，只声明「这块地方有多大、能不能点」，
/// 然后把 `DashboardModuleFactory` 出来的那一块摆进去。
///
/// 为什么它在 MeterModules 而不在 `Widget/`：主屏上那一格的样子不止 widget 扩展要，
/// 商店宣传图也要——那张图上的小组件必须是**同一份视图**渲出来的，不是照着它重画的
/// 一版 HTML。一旦重画，宣传图上的小组件和用户装到主屏上的那一格就会各走各的，
/// 而且没有任何编译期信号。
///
/// WidgetKit 那一层（`containerBackground`、`widgetURL`、`widgetFamily`）留在壳里：
/// 模块这一层不认识宿主框架。
public struct WidgetModuleTile<Contents: DashboardModuleContents>: View {
    private let module: DashboardModuleID
    private let contents: Contents
    private let presentation: MoneyPresentation
    private let isEmpty: Bool
    private let contentSize: CGSize
    private let linkStyle: ModuleLinkStyle?

    /// - Parameters:
    ///   - contentSize: widget 分给**内容**的那块地方（widget 已经扣好了内容边距）。
    ///     模块自己不许量——那是布局反馈环。
    ///   - linkStyle: 推得动页就传，推不动传 nil（`systemSmall`、渲图）。
    public init(
        module: DashboardModuleID,
        contents: Contents,
        presentation: MoneyPresentation,
        isEmpty: Bool,
        contentSize: CGSize,
        linkStyle: ModuleLinkStyle?
    ) {
        self.module = module
        self.contents = contents
        self.presentation = presentation
        self.isEmpty = isEmpty
        self.contentSize = contentSize
        self.linkStyle = linkStyle
    }

    public var body: some View {
        if isEmpty {
            emptyState
        } else if contents.has(module) {
            tile
        } else {
            caption(MeterFormatText.resource("这一块暂时没有数据"))
        }
    }

    private var tile: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xs) {
            // 模块名做小标题，和宽壳 bento 卡同一套：主屏上一堆数字，不写名字认不出是哪块。
            // 自己就是一张图的那几块（圆环、格子图）不写——那行字只是把图往下挤。
            if module.widgetShowsTitle {
                Text(module.title)
                    .font(MeterFont.caption)
                    .foregroundStyle(Color.meterSecondaryLabel)
            }
            DashboardModuleFactory.view(id: module, contents: contents)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .meterModuleStyle(
            width: ModuleWidth.bucket(forContentWidth: contentSize.width),
            height: ModuleHeight.bucket(forContentHeight: contentSize.height),
            container: .snapshot
        )
        .environment(\.moneyPresentation, presentation)
        .environment(\.moduleLinkStyle, linkStyle)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
            // 空态还是留一只猫：主屏上一块什么都没有的灰字，读起来像坏了。
            CatView(mood: .sleeping, size: MeterSpacing.catWidgetSmall, isAnimated: false)
                .accessibilityHidden(true)
            Text(MeterFormatText.resource("还没有账单"))
                .font(MeterFont.bodyEmphasized)
                .foregroundStyle(Color.meterLabel)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            if ModuleWidth.bucket(forContentWidth: contentSize.width) > .compact {
                Text(MeterFormatText.resource("打开 App 接入第一家服务"))
                    .font(MeterFont.caption)
                    .foregroundStyle(Color.meterSecondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(MeterFormatText.resource("还没有账单。打开 App 接入第一家服务"))
    }

    private func caption(_ text: LocalizedStringResource) -> some View {
        Text(text)
            .font(MeterFont.footnote)
            .foregroundStyle(Color.meterSecondaryLabel)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
