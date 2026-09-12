import SwiftUI
import MeterCore
import MeterDesign

/// 「日历热力图」：一个月一张格子图，横扫翻到有数据的月份，整块点进详情页看每个月。
public struct HeatmapModuleView: View {
    public let content: HeatmapModuleContent

    public init(content: HeatmapModuleContent) {
        self.content = content
    }
    /// 正在看第几个月。nil = 最新那个月。翻过之后固定在那一页，直到月份列表变了。
    @State private var selection: Date?
    @Environment(\.moduleWidth) private var width
    @Environment(\.moduleHeight) private var height
    /// 点不动的容器（分享卡、widget）不画 chevron、不做成链接，也不接横扫。
    @Environment(\.moduleContainer) private var container
    /// 壳注入了推法才做成链接。没注入（预览、组件库）照样把图画出来——
    /// 整块就是内容，外壳没了内容不能跟着没。
    @Environment(\.moduleLinkStyle) private var linkStyle

    private var isLinked: Bool { container.isInteractive && linkStyle != nil }

    private var current: HeatmapMonth? {
        if let selection, let month = content.months.first(where: { $0.monthStart == selection }) {
            return month
        }
        return content.months.last
    }

    private var index: Int {
        guard let current else { return 0 }
        return content.months.firstIndex(of: current) ?? 0
    }

    /// 整块是一个链接，右上角一颗 chevron——和「较上月同期」那张方卡同一套。
    /// 所以**翻月不能再靠按钮**：外层是链接时，里面的按钮收不到点按。
    /// 卡上翻月只剩横扫；键盘、读屏和 Mac 上翻月改走详情页，那一页每个月各一张。
    public var body: some View {
        if let month = current {
            if isLinked {
                ModuleInlineLink(route: .heatmap) {
                    card(month, showsChevron: true)
                }
                .accessibilityHint(L("查看每个月的日历"))
            } else {
                card(month, showsChevron: false)
            }
        }
    }

    private func card(_ month: HeatmapMonth, showsChevron: Bool) -> some View {
        HStack(alignment: .top, spacing: MeterSpacing.xs) {
            VStack(alignment: .leading, spacing: MeterSpacing.xs) {
                // 月份和格子图是一体的：左边是「哪个月」，右边是「这个月长什么样」。
                // 挤到 compact 就改上下叠：并排时格子图只剩不到 120pt，
                // 一周七格会压到看不出深浅，那这张图就白画了。
                if width > .compact {
                    HStack(alignment: .center, spacing: MeterSpacing.md) {
                        monthTitle(month)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        grid(month)
                    }
                } else {
                    VStack(alignment: .leading, spacing: MeterSpacing.xs) {
                        monthTitle(month)
                        grid(month)
                    }
                }
                // 注释是这一整块的脚注，不是月份那一行的第二行——它说的是图上
                // 哪一格最深，跟在图下面才对得上。
                if height > .tight, let peak = month.peakCaption {
                    Text(peak)
                        .font(MeterFont.footnote)
                        .foregroundStyle(Color.meterSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            // 贴右上角，不跟着整块居中：这一块高，居中的箭头会落在格子图的腰上。
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(MeterFont.footnote.weight(.semibold))
                    .foregroundStyle(Color.meterTertiaryLabel)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // 整块横扫翻月：手在图上就能翻，不占版面。
        .contentShape(Rectangle())
        .modifier(HeatmapSwipe(isActive: container.isInteractive, step: step))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L("\(month.title) 共 \(month.spokenTotal)"))
    }

    /// 只写月份、写大一点：翻月翻的是相邻几个月，年份看一眼就够了，
    /// 每次都跟着「2026年」反而看不清翻到哪了。
    private func monthTitle(_ month: HeatmapMonth) -> some View {
        // 只有一格高时（2×2 的 widget）月份收成小字：那一格里图才是主角，
        // 月份只是「这是哪个月」的注脚，占掉 title2 的高度就没地方画格子了。
        Text(month.monthTitle)
            .font(height > .tight ? MeterFont.title2.weight(.semibold) : MeterFont.caption)
            .foregroundStyle(Color.meterLabel)
            .lineLimit(1)
            .contentTransition(.numericText())
    }

    private func grid(_ month: HeatmapMonth) -> some View {
        SpendHeatmapGrid(
            values: month.values,
            leadingEmptyDays: month.leadingEmptyDays,
            maxValue: month.maxValue
        )
        .animation(DashboardMotion.number, value: month.id)
    }

    private func step(_ delta: Int) {
        let next = min(max(index + delta, 0), content.months.count - 1)
        guard next != index else { return }
        withAnimation(DashboardMotion.number) {
            selection = content.months[next].monthStart
        }
    }
}

/// 横扫翻月。和列表的竖向滚动同时识别，落手时才判方向——
/// 独占手势会把这一行的滚动吃掉，滚不动整页。
private struct HeatmapSwipe: ViewModifier {
    var isActive: Bool
    var step: (Int) -> Void

    /// 够长、且明显比竖向位移长才算横扫；顺手带出来的一点横向抖动不翻月。
    private static let minimumDistance: CGFloat = 44

    func body(content: Content) -> some View {
        if isActive {
            content.simultaneousGesture(
                DragGesture(minimumDistance: 12).onEnded { value in
                    let dx = value.translation.width
                    guard abs(dx) >= Self.minimumDistance,
                          abs(dx) > abs(value.translation.height) * 1.5
                    else { return }
                    // 往左扫 = 往后看（下一个月），和翻页同向。
                    step(dx < 0 ? 1 : -1)
                }
            )
        } else {
            content
        }
    }
}

#Preview("Light") {
    NavigationStack {
        List {
            Section {
                HeatmapModuleView(content: HeatmapPreviewData.sample)
            }
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        List {
            Section {
                HeatmapModuleView(content: HeatmapPreviewData.sample)
            }
        }
    }
    .preferredColorScheme(.dark)
}

public enum HeatmapPreviewData {
    public static let sample: HeatmapModuleContent = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let august = Date(timeIntervalSince1970: 1_785_542_400)
        let september = calendar.date(byAdding: .month, value: 1, to: august)!
        return HeatmapModuleContent(months: [
            HeatmapMonth(
                monthStart: august,
                title: "2026年8月",
                monthTitle: "8月",
                values: (1...31).map { Double(($0 * 7) % 11) },
                leadingEmptyDays: 6,
                totalText: "$44.05",
                spokenTotal: "44 美元 5 美分",
                peakCaption: "花得最多：8月19日，$3.20"
            ),
            HeatmapMonth(
                monthStart: september,
                title: "2026年9月",
                monthTitle: "9月",
                values: (1...30).map { $0 > 3 ? nil : Double($0) * 0.6 },
                leadingEmptyDays: 2,
                totalText: "$1.81",
                spokenTotal: "1 美元 81 美分",
                peakCaption: "花得最多：9月1日，$1.28"
            ),
        ])
    }()
}
