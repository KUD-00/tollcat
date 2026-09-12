import SwiftUI
import MeterCore
import MeterDesign

/// 月格拖选：一格一个月，点一格选一个月，按住横拖选一段。
///
/// 这是筛选面板「时间」那一节的**候选版式**，先放在组件画廊里看效果，
/// 没有接进正式页面。它和现在那两行 chip 是同一个问题的两种答案：
/// chip 把「哪个月」和「多长一段」拆成两行、各自一眼可数；月格把两者合成一个
/// 平面，代价是「拖」这件事在界面上没有可见的把手——第一次用的人多半只会点。
///
/// ## 三个必须自己解决的问题
///
/// 1. **命中判定不靠 preference。** 格子是等宽等高的规则网格，落点除以格距就是
///    行列号。用 `PreferenceKey` 把 12 个格子的 frame 收上来再逐个比对，是同一件事
///    的昂贵写法，而且拖动过程中每帧都要重跑一遍。
/// 2. **没数据的月份不能当端点。** 点一个空月份只会得到 $0，而 $0 和「没数据」
///    在这个 App 里是两件事。但它可以被**夹在**区间中间——那是真的，那个月确实
///    没花钱。所以是「不可当端点」，不是「不可选」。
/// 3. **拖动对 VoiceOver 不存在。** 每格额外挂两个自定义动作（设为起点 / 设为终点），
///    用两次动作表达一次拖动。只做手势等于把这个控件对一部分人关掉。
struct MonthRangeGrid: View {
    struct Month: Identifiable, Hashable {
        /// 0 = 本月。
        var monthsBack: Int
        /// 「八月」。
        var title: String
        /// 那个月有没有读数。没有的不能当区间端点。
        var hasData: Bool

        var id: Int { monthsBack }
    }

    /// **从老到新**。索引和 `monthsBack` 一一对应，中间不许缺月——
    /// 缺一个月，网格上的位置就会和它代表的月份错位。
    var months: [Month]
    @Binding var selection: MonthWindow
    var columns: Int = 4

    @State private var dragAnchor: Int?
    @State private var hovered: Int?

    private var spacing: CGFloat { MeterSpacing.xxs }
    private var cellHeight: CGFloat { MeterSpacing.minTap }

    var body: some View {
        // 宽度量在容器上，格宽由它反推。让每个格子自己量宽再回填，会把
        // 「格子加起来比容器宽」这件事变成一个自激的布局环。
        GeometryReader { proxy in
            let cellWidth = cellWidth(in: proxy.size.width)
            grid(cellWidth: cellWidth)
                .contentShape(Rectangle())
                .gesture(dragGesture(cellWidth: cellWidth))
        }
        .frame(height: totalHeight)
        .sensoryFeedback(.selection, trigger: selection)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L("按月选择区间"))
    }

    // MARK: - 版式

    private var rowCount: Int {
        max(1, Int(ceil(Double(months.count) / Double(max(columns, 1)))))
    }

    private var totalHeight: CGFloat {
        CGFloat(rowCount) * cellHeight + CGFloat(max(rowCount - 1, 0)) * spacing
    }

    private func cellWidth(in width: CGFloat) -> CGFloat {
        let count = CGFloat(max(columns, 1))
        return max((width - spacing * (count - 1)) / count, 1)
    }

    private func grid(cellWidth: CGFloat) -> some View {
        VStack(spacing: spacing) {
            ForEach(0..<rowCount, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<columns, id: \.self) { column in
                        let index = row * columns + column
                        if index < months.count {
                            cell(months[index])
                                .frame(width: cellWidth, height: cellHeight)
                        } else {
                            Color.clear.frame(width: cellWidth, height: cellHeight)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 格子

    /// 格子里**只有月份名**。年份不进来：12 个格子最多跨两年，塞第二行字会把
    /// 44pt 挤扁，带年份那几格的月份名当场比同行矮一截、基线也对不齐（第一版
    /// 就是这样）。跨了哪两年由网格上方那行区间说明交代。
    @ViewBuilder
    private func cell(_ month: Month) -> some View {
        let selected = isSelected(month)
        ZStack {
            background(month, isSelected: selected)
            Text(month.title)
                .font(MeterFont.subheadline)
                .fontWeight(selected ? .semibold : .regular)
                .foregroundStyle(labelColor(month, isSelected: selected))
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(month.title)
        .accessibilityValue(accessibilityValue(month, isSelected: selected))
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction(named: Text(L("设为起点"))) {
            setEndpoint(month.monthsBack, keeping: selection.newestBack)
        }
        .accessibilityAction(named: Text(L("设为终点"))) {
            setEndpoint(selection.oldestBack, keeping: month.monthsBack)
        }
    }

    /// 区间在一行里连成一条，行首行尾切平——和系统日历选一段日期是同一套观感。
    /// 每格各画一个独立胶囊的话，选中 6 个月看起来像选了 6 次。
    @ViewBuilder
    private func background(_ month: Month, isSelected: Bool) -> some View {
        if isSelected {
            let radius = MeterSpacing.sm
            UnevenRoundedRectangle(
                topLeadingRadius: isRangeLeadingEdge(month) ? radius : 0,
                bottomLeadingRadius: isRangeLeadingEdge(month) ? radius : 0,
                bottomTrailingRadius: isRangeTrailingEdge(month) ? radius : 0,
                topTrailingRadius: isRangeTrailingEdge(month) ? radius : 0
            )
            .fill(Color.accentColor)
        } else {
            // 没读数的那几个月压到四成——和热力图里「那天没数」用的是同一档淡度。
            // 只把字调淡不够：一排格子扫过去，底色才是先被看见的那一层。
            RoundedRectangle(cornerRadius: MeterSpacing.sm)
                .fill(Color.meterTertiarySystemFill.opacity(month.hasData ? 1 : 0.4))
        }
    }

    private func labelColor(_ month: Month, isSelected: Bool) -> Color {
        if isSelected { return .white }
        return month.hasData ? Color.meterLabel : Color.meterTertiaryLabel
    }

    private func accessibilityValue(_ month: Month, isSelected: Bool) -> LocalizedStringResource {
        if !month.hasData { return L("没有读数") }
        return isSelected ? L("已选中") : L("未选中")
    }

    // MARK: - 选中判定

    private func isSelected(_ month: Month) -> Bool {
        month.monthsBack >= selection.newestBack && month.monthsBack <= selection.oldestBack
    }

    /// 「视觉上的行首」：区间的最老一端，或者刚好排在这一行第一格。
    private func isRangeLeadingEdge(_ month: Month) -> Bool {
        guard let index = index(of: month) else { return true }
        return month.monthsBack == selection.oldestBack || index % columns == 0
    }

    private func isRangeTrailingEdge(_ month: Month) -> Bool {
        guard let index = index(of: month) else { return true }
        return month.monthsBack == selection.newestBack
            || index % columns == columns - 1
            || index == months.count - 1
    }

    private func index(of month: Month) -> Int? {
        months.firstIndex(of: month)
    }

    // MARK: - 手势

    private func dragGesture(cellWidth: CGFloat) -> some Gesture {
        // `minimumDistance: 0` 让「点一下」也走这条路：点和拖是同一件事的两端，
        // 拆成 TapGesture + DragGesture 会在两者之间留一段既不算点也不算拖的死区。
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard let index = index(at: value.location, cellWidth: cellWidth) else { return }
                guard let anchor = dragAnchor else {
                    // 落点是空月份就什么都不做：区间的端点必须是有数的月份。
                    guard months[index].hasData else { return }
                    dragAnchor = index
                    select(from: index, to: index)
                    return
                }
                select(from: anchor, to: index)
            }
            .onEnded { _ in dragAnchor = nil }
    }

    private func index(at point: CGPoint, cellWidth: CGFloat) -> Int? {
        let column = Int(floor(point.x / (cellWidth + spacing)))
        let row = Int(floor(point.y / (cellHeight + spacing)))
        guard column >= 0, column < columns, row >= 0, row < rowCount else { return nil }
        let index = row * columns + column
        return index < months.count ? index : nil
    }

    /// 拖到空月份上时不把端点落在那里，停在上一个有数的月份——
    /// 手指可以扫过去，区间不会以一个 $0 的月份收尾。
    private func select(from anchor: Int, to target: Int) {
        let clamped = nearestWithData(from: anchor, towards: target) ?? anchor
        let lower = min(months[anchor].monthsBack, months[clamped].monthsBack)
        let upper = max(months[anchor].monthsBack, months[clamped].monthsBack)
        selection = MonthWindow(newestBack: lower, oldestBack: upper)
    }

    private func nearestWithData(from anchor: Int, towards target: Int) -> Int? {
        guard anchor != target else { return months[anchor].hasData ? anchor : nil }
        let step = target > anchor ? 1 : -1
        var candidate: Int?
        var cursor = anchor
        while cursor != target + step {
            if months[cursor].hasData { candidate = cursor }
            cursor += step
        }
        return candidate
    }

    private func setEndpoint(_ oldestBack: Int, keeping newestBack: Int) {
        let lower = min(oldestBack, newestBack)
        let upper = max(oldestBack, newestBack)
        selection = MonthWindow(newestBack: lower, oldestBack: upper)
    }
}
