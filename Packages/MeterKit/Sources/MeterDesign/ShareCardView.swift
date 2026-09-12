import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// 分享卡本体。**只被 `ImageRenderer` 渲成图片**，不直接进导航层级。
///
/// 卡上的东西跟仪表盘同一套：月份、主角数字、构成环 + 图例、较上月同期、近几个月，
/// 再加上用户自己开着的那些模块（`modules` 槽，由 `MeterFeatures` 把仪表盘的模块视图
/// 原样传进来——分享卡不许另攒一套「精简版仪表盘」）。品牌标和二维码是卡作为一张
/// 独立图片才加的，仪表上看不到。
///
/// 三条约束和屏幕上的视图不一样：
///
/// 1. **宽度写死、高度跟内容长。** 按仪表的手机栏宽排，渲图再放大 2.5 倍；
///    模块少时至少 1080×1920（9:16，手机屏比例），模块多了卡就往下长，
///    不裁内容——裁下沿就是把二维码切掉一半。
/// 2. **配色锁成浅色。** 卡片会被转发到任何地方，跟着分享者的深色模式走会让收到的人
///    看到一张黑卡。卡自己那几个颜色写死（`ShareCardPalette`），嵌进来的模块视图走
///    系统语义色，靠 `rasterize` 把渲图时的 trait / appearance 也压成浅色。
/// 3. **不动画。** `meterStaticRender` 一路传下去：进场动画（圆环从空转起来）
///    在只渲一帧的 `ImageRenderer` 里永远停在第 0 帧，能点才有意义的 chevron 同理。
public struct ShareCardView: View {
    /// 1080×1920（9:16）是**下限**：卡片最后是在别人的手机上全屏看的，
    /// 4:5 那种方图摊在手机上就是一张矮胖的图。模块多了只往下长。
    public static let size = CGSize(width: 1080, height: 1920)
    /// 按仪表手机栏宽排。`size / layoutSize` 就是渲图像素倍率。
    public static let layoutSize = CGSize(width: 432, height: 768)
    public static var renderScale: CGFloat { size.width / layoutSize.width }

    /// 卡片自己的一套色。见 `ShareCardPalette`。
    private static let ink = ShareCardPalette.ink
    private static let secondaryInk = ShareCardPalette.secondaryInk
    private static let tertiaryInk = ShareCardPalette.tertiaryInk
    private static let cardBackground = ShareCardPalette.card
    private static let pageBackground = ShareCardPalette.page
    private static let brandFill = ShareCardPalette.brand

    private let content: ShareCardContent
    /// 用户开着的那些模块，由调用方（`MeterFeatures`）传进来。
    /// `MeterDesign` 不认识领域类型，只负责给它们一块位置和一套颜色。
    private let modules: AnyView?

    public init(content: ShareCardContent) {
        self.content = content
        self.modules = nil
    }

    public init<Modules: View>(
        content: ShareCardContent,
        @ViewBuilder modules: () -> Modules
    ) {
        self.content = content
        self.modules = AnyView(modules())
    }

    /// 内容按仪表盘的节奏从上往下排，唯一会伸缩的留白在落款前。
    ///
    /// 主角数字和构成环是同一段叙事，中间不许被撑开——留白只许沉到内容区
    /// 和落款的交界处。落款前的 `Spacer` 是 `minLength: 0`：模块少的时候它把落款
    /// 压到 9:16 那条下沿，模块多了它收到 0、卡自己往下长。**高度不封顶、不裁**：
    /// 封顶就等于把二维码从下沿切掉半个。
    public var body: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.md) {
            header
            hero
            if !content.segments.isEmpty {
                composition
            }
            if showsBento {
                bento
            }
            if let modules {
                modules
            }
            Spacer(minLength: 0)
            footer
        }
        .padding(MeterSpacing.lg)
        .frame(width: Self.layoutSize.width, alignment: .topLeading)
        .frame(minHeight: Self.layoutSize.height, alignment: .topLeading)
        .background(Self.pageBackground)
        .environment(\.colorScheme, .light)
        .environment(\.dynamicTypeSize, .large)
        // 嵌进来的模块视图是给人点的界面：进场动画和 chevron 在一张图上都要收掉。
        .environment(\.meterStaticRender, true)
        .tint(Self.brandFill)
        .transaction { $0.animation = nil }
    }

    /// 1080 宽的位图，高度按内容（至少 1920）。`scale` 跟 `layoutSize` 配套，
    /// 不要在调用方另设。
    public static func rasterize(_ content: ShareCardContent) -> CGImage? {
        raster(ShareCardView(content: content))
    }

    /// 带模块的那一份。`MeterFeatures` 把仪表盘的模块视图传进来。
    public static func rasterize<Modules: View>(
        _ content: ShareCardContent,
        @ViewBuilder modules: () -> Modules
    ) -> CGImage? {
        raster(ShareCardView(content: content, modules: modules))
    }

    /// 高度提议给 `nil`：视图按内容报高，`minHeight` 兜住 9:16 那个下限。
    ///
    /// 渲图时把 trait / appearance 也压成浅色：嵌进来的模块视图走系统语义色
    /// （`Color(.label)` 那些），它们解析的是**当前绘制环境**，不是 SwiftUI 的
    /// `colorScheme` 环境值——分享者开着深色时不压这一层，卡上的字会是浅灰压白卡。
    private static func raster<V: View>(_ view: V) -> CGImage? {
        lightAppearance {
            let renderer = ImageRenderer(content: view)
            renderer.scale = renderScale
            renderer.isOpaque = true
            renderer.proposedSize = ProposedViewSize(width: layoutSize.width, height: nil)
            return renderer.cgImage
        }
    }

    private static func lightAppearance(_ body: () -> CGImage?) -> CGImage? {
        #if canImport(UIKit)
        var image: CGImage?
        UITraitCollection(userInterfaceStyle: .light).performAsCurrent {
            image = body()
        }
        return image
        #elseif canImport(AppKit)
        guard let aqua = NSAppearance(named: .aqua) else { return body() }
        var image: CGImage?
        aqua.performAsCurrentDrawingAppearance {
            image = body()
        }
        return image
        #else
        return body()
        #endif
    }

    private var showsBento: Bool {
        content.comparison != nil || content.trend != nil
    }

    private var header: some View {
        HStack(spacing: MeterSpacing.sm) {
            BrandMark()
            Text(verbatim: "TollCat")
                .font(MeterFont.title2.weight(.semibold))
                .foregroundStyle(Self.ink)
            Spacer(minLength: 0)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
            // 仪表上月份是大标题。卡上看不到导航栏，这一行承担同一档——
            // caption 灰会把它收成金额的脚注，收件人在图上就看不清是哪个月。
            Text(content.periodTitle)
                .font(MeterFont.largeTitle.weight(.bold))
                .foregroundStyle(Self.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(content.totalText)
                .meterAmountStyle()
                .foregroundStyle(Self.ink)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)
                // 仪表大标题底下垫 xs，数字才不贴「八月」。卡上同一档。
                .padding(.top, MeterSpacing.xs)
            if let subscription = content.subscriptionText {
                Text(subscription)
                    .font(MeterFont.subheadline)
                    .foregroundStyle(Self.secondaryInk)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let projection = content.projectionText {
                Text(projection)
                    .font(MeterFont.subheadline)
                    .foregroundStyle(Self.secondaryInk)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let currencyNote = content.currencyNote {
                Text(currencyNote)
                    .font(MeterFont.footnote)
                    .foregroundStyle(Self.tertiaryInk)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let filterNote = content.filterNote {
                HStack(alignment: .firstTextBaseline, spacing: MeterSpacing.xxs) {
                    Image(systemName: "line.3.horizontal.decrease")
                    Text(filterNote)
                }
                .font(MeterFont.footnote)
                .foregroundStyle(Self.brandFill)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, MeterSpacing.xxs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var composition: some View {
        HStack(alignment: .center, spacing: MeterSpacing.md) {
            CompositionDonut(
                slices: donutSlices,
                showsLegend: false,
                size: MeterSpacing.shareCardDonut,
                isAnimated: false
            )
            compositionLegend
        }
        .padding(.horizontal, MeterSpacing.md)
        .padding(.vertical, MeterSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Self.cardBackground, in: cardShape)
    }

    private var compositionLegend: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xs) {
            ForEach(Array(content.segments.enumerated()), id: \.element.id) { index, segment in
                HStack(alignment: .firstTextBaseline, spacing: MeterSpacing.xs) {
                    Circle()
                        .fill(segmentColor(index: index, isOther: segment.isOther))
                        .frame(width: MeterSpacing.compositionSwatch, height: MeterSpacing.compositionSwatch)
                    Text(segment.name)
                        .font(MeterFont.subheadline)
                        .foregroundStyle(Self.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: MeterSpacing.xs)
                    Text(segment.amountText)
                        .font(MeterFont.subheadline)
                        .foregroundStyle(Self.secondaryInk)
                        .monospacedDigit()
                        .lineLimit(1)
                }
            }
        }
    }

    private var bento: some View {
        HStack(alignment: .top, spacing: MeterSpacing.md) {
            if let comparison = content.comparison {
                comparisonTile(comparison)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            if let trend = content.trend {
                trendTile(trend)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func comparisonTile(_ comparison: ShareCardContent.Comparison) -> some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xs) {
            Text(comparison.title)
                .font(MeterFont.caption)
                .foregroundStyle(Self.secondaryInk)
            Text(comparison.percentText)
                .font(MeterFont.title2.weight(.semibold))
                .foregroundStyle(percentColor(comparison.tone))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            if let caption = comparison.caption {
                Text(caption)
                    .font(MeterFont.caption)
                    .foregroundStyle(Self.tertiaryInk)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            if comparison.showsBars {
                CompactComparisonBars(
                    current: comparison.current,
                    previous: comparison.previous,
                    currentLabel: comparison.currentLabel,
                    previousLabel: comparison.previousLabel,
                    plotHeight: MeterSpacing.shareCardChart,
                    accent: Self.brandFill
                )
            }
        }
        .frame(maxWidth: .infinity, minHeight: 0, alignment: .topLeading)
        .padding(MeterSpacing.sm)
        .background(Self.cardBackground, in: cardShape)
    }

    private func trendTile(_ trend: ShareCardContent.Trend) -> some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xs) {
            Text(trend.title)
                .font(MeterFont.caption)
                .foregroundStyle(Self.secondaryInk)
            Spacer(minLength: 0)
            CompactMonthBarChart(
                points: trend.points,
                xStart: trend.xStart,
                xEnd: trend.xEnd,
                highlight: trend.highlight,
                plotHeight: MeterSpacing.shareCardChart,
                accent: Self.brandFill
            )
        }
        .frame(maxWidth: .infinity, minHeight: 0, alignment: .topLeading)
        .padding(MeterSpacing.sm)
        .background(Self.cardBackground, in: cardShape)
    }

    private var footer: some View {
        HStack(alignment: .center, spacing: MeterSpacing.md) {
            VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                Text(content.qrCaption)
                    .font(MeterFont.subheadline)
                    .foregroundStyle(Self.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(content.footnote)
                    .font(MeterFont.caption)
                    .foregroundStyle(Self.secondaryInk)
                    .lineLimit(1)
            }
            Spacer(minLength: MeterSpacing.xs)
            QRCodeView(payload: content.qrPayload, side: MeterSpacing.shareCardQR)
        }
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: MeterRadius.groupedCard, style: .continuous)
    }

    private var donutSlices: [CompositionDonut.Slice] {
        content.segments.enumerated().map { index, segment in
            CompositionDonut.Slice(
                id: segment.id,
                color: segmentColor(index: index, isOther: segment.isOther),
                fraction: segment.fraction,
                name: segment.name,
                amountText: segment.amountText
            )
        }
    }

    private func segmentColor(index: Int, isOther: Bool) -> Color {
        isOther ? MeterColor.compositionOther : MeterColor.composition(index: index)
    }

    private func percentColor(_ tone: ShareCardContent.Comparison.Tone) -> Color {
        switch tone {
        case .up: MeterColor.warn
        case .down: MeterColor.good
        case .flat, .unknown: Self.ink
        }
    }
}

extension ShareCardContent {
    /// Preview 和验收用的一份。数字取 SPEC 第 04 节那组。
    public static var preview: ShareCardContent {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let lastMonth = Date(timeIntervalSince1970: 1_787_616_000)
        let start = calendar.date(byAdding: .month, value: -5, to: lastMonth) ?? lastMonth
        let points: [PlotPoint] = [12, 18, 9, 22, 15, 21].enumerated().compactMap { index, amount in
            calendar.date(byAdding: .month, value: index, to: start).map {
                PlotPoint(date: $0, amount: Double(amount))
            }
        }
        return ShareCardContent(
            periodTitle: "八月",
            totalText: "$47.20",
            projectionText: "预计月底 $87.70 · 8/1–8/17",
            segments: [
                .init(name: "AWS", amountText: "$21.40", fraction: 0.45),
                .init(name: "Cloudflare", amountText: "$11.05", fraction: 0.23),
                .init(name: "OpenAI", amountText: "$7.62", fraction: 0.16),
                .init(name: "GitHub", amountText: "$4.00", fraction: 0.09),
                .init(name: "Neon", amountText: "$3.13", fraction: 0.07),
            ],
            comparison: Comparison(
                title: "较上月同期",
                percentText: "+62%",
                caption: "对比 7 月同期 $29.10",
                current: 47.2,
                previous: 29.1,
                currentLabel: "本月",
                previousLabel: "上月",
                tone: .up,
                showsBars: true
            ),
            trend: Trend(
                title: "近几个月",
                points: points,
                xStart: start,
                xEnd: CompactMonthBarChart.domainEnd(afterLastMonthStart: lastMonth, calendar: calendar),
                highlight: lastMonth
            ),
            qrPayload: "https://tollcat.app",
            qrCaption: "把各家云账单，装进口袋。",
            footnote: "tollcat.app"
        )
    }

    /// 内容最满的一份：六段图例、订阅和折算都在、带限定语。
    /// 卡不许被这一份顶穿——`ShareCardTests` 拿它守着。
    public static var previewCrowded: ShareCardContent {
        var content = preview
        content.segments += [
            .init(name: "其他", amountText: "$2.90", fraction: 0.06, isOther: true)
        ]
        content.subscriptionText = "（订阅 $19.99）"
        content.currencyNote = "按 1 USD = 7.12 CNY 折算显示"
        content.filterNote = "七月 · 不含订阅 · 排除 AWS、Cloudflare"
        return content
    }
}

#Preview("卡片") {
    ShareCardView(content: .preview)
}

#Preview("内容最满") {
    ShareCardView(content: .previewCrowded)
}
