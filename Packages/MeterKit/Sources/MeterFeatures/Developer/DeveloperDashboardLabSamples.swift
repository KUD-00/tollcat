#if DEBUG
import SwiftUI
import MeterCore
import MeterDesign
import MeterModules

/// 一块模块在各壳里的样子。尺寸全部是常数，不量窗口。
struct DeveloperDashboardLabSamples<Contents: DashboardModuleContents>: View {
    var id: DashboardModuleID
    var contents: Contents
    var presentation: MoneyPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.lg) {
            sampleSection(title: L("宽壳卡")) {
                ForEach(DashboardLabWidthSample.allCases, id: \.self) { sample in
                    labeled(
                        title: Text(verbatim: "\(String(localized: sample.title)) · \(Int(sample.contentWidth)) pt"),
                        caption: Text(sample.caption)
                    ) {
                        card(sample)
                    }
                }
            }
            sampleSection(title: L("手机列表")) {
                labeled(
                    title: Text(verbatim: "\(String(localized: L("基准"))) · \(Int(DashboardLabWidthSample.listContentWidth)) pt"),
                    caption: Text(L("高度不封顶。chevron 和行高由 List 补。"))
                ) {
                    listRow
                }
            }
            if !id.widgetSizes.isEmpty {
                sampleSection(title: L("小组件")) {
                    ForEach(id.widgetSizes, id: \.rawValue) { size in
                        let content = size.contentSize(.phone)
                        labeled(
                            title: Text(verbatim: size.rawValue),
                            caption: Text(
                                verbatim: "\(Int(content.width)) × \(Int(content.height))"
                            )
                        ) {
                            widget(size)
                        }
                    }
                }
            }
        }
        .environment(\.moneyPresentation, presentation)
        .environment(\.moduleLinkStyle, DashboardLabLinkStyle.inert())
        .buttonStyle(.plain)
    }

    private func sampleSection<Content: View>(
        title: LocalizedStringResource,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: MeterSpacing.sm) {
            Text(title)
                .font(MeterFont.caption)
                .foregroundStyle(Color.meterSecondaryLabel)
            content()
        }
    }

    private func labeled<Content: View>(
        title: Text,
        caption: Text,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
            title
                .font(MeterFont.subheadline)
                .foregroundStyle(Color.meterLabel)
            caption
                .font(MeterFont.caption)
                .foregroundStyle(Color.meterTertiaryLabel)
                .fixedSize(horizontal: false, vertical: true)
            ScrollView(.horizontal) {
                content()
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
        }
        .accessibilityElement(children: .contain)
    }

    /// 和 `DashboardModuleCard` 同一张脸：小标题、定高裁切、卡面圆角。
    private func card(_ sample: DashboardLabWidthSample) -> some View {
        let shape = RoundedRectangle(cornerRadius: MeterRadius.groupedCard, style: .continuous)
        return VStack(alignment: .leading, spacing: MeterSpacing.xs) {
            Text(id.title)
                .font(MeterFont.caption)
                .foregroundStyle(Color.meterSecondaryLabel)
            DashboardModuleFactory.view(id: id, contents: contents)
        }
        .padding(MeterSpacing.md)
        .frame(width: sample.outerWidth, height: sample.outerHeight, alignment: .topLeading)
        .background(Color.meterSecondaryGroupedBackground, in: shape)
        .clipShape(shape)
        .meterModuleStyle(width: sample.width, height: .regular, container: .card)
    }

    private var listRow: some View {
        let shape = RoundedRectangle(cornerRadius: MeterRadius.groupedCard, style: .continuous)
        return DashboardModuleFactory.view(id: id, contents: contents)
            .frame(width: DashboardLabWidthSample.listContentWidth, alignment: .topLeading)
            .padding(MeterSpacing.md)
            .background(Color.meterSecondaryGroupedBackground, in: shape)
            .meterModuleStyle(width: .regular, height: .unbounded, container: .listRow)
    }

    private func widget(_ size: ModuleWidgetSize) -> some View {
        let content = size.contentSize(.phone)
        let frame = size.frameSize(.phone)
        return WidgetModuleTile(
            module: id,
            contents: contents,
            presentation: presentation,
            isEmpty: false,
            contentSize: content,
            linkStyle: nil
        )
        .frame(width: content.width, height: content.height, alignment: .topLeading)
        .padding(ModuleWidgetSize.contentMargin)
        .frame(width: frame.width, height: frame.height)
        .background(
            Color.meterSecondaryGroupedBackground,
            in: RoundedRectangle(cornerRadius: ModuleWidgetSize.cornerRadius, style: .continuous)
        )
    }
}
#endif
