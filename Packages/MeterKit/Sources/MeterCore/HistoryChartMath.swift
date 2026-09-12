import Foundation

/// 详情页历史图的**纯计算**：分桶、做差、推断段。单源在这里，
/// iOS `ProviderHistoryChartBuilder`（Features）和 Android JNI 出口都只做薄适配。
///
/// 缺失 ≠ 零。柱状图每根柱子是一个独立事实：那一段花了多少。缺了就是不知道，
/// 不能补 0（0 的意思是「这天没花钱」），也不能插值（等于凭空发明支出）。
/// 折线两点之间是同一个量的连续变化；隔了空档的段标成「推断」。
///
/// ## 这里的 `Double` 是刻意的
///
/// 房规「业务里不许裸 `Double`」（见 `ARCHITECTURE.zh.md` 的 Money 一段）在这个
/// 文件上有一个**明写的例外**：这里出的是**图表几何**，不是账本金额。
/// 柱高、折线取值、做差之后的段落都要直接喂给 Swift Charts，而 Charts 的
/// `Plottable` 只吃 `Double`；折算侧的钱一律是 `Money`（`Decimal`），
/// 到这一层才转一次，并且**只往这个方向转**——这里算出来的数不许回流进账本。
public enum HistoryChartRange: String, Sendable {
    case days7
    case days30
    case months12

    public var isMonthly: Bool { self == .months12 }

    /// 7 / 30 天翻一页的天数。12 个月不翻。
    public var pageStepDays: Int? {
        switch self {
        case .days7: 7
        case .days30: 30
        case .months12: nil
        }
    }
}

/// 7 / 30 天图能翻到哪些页。只含**有柱或点**的 offset，空窗不在里面。
/// `0` 是钉在今天的那一窗，即使它是空的也不会自动出现在这里——
/// 当前这一段没有读数仍停在今天，不要跳到有数的过去。
public struct HistoryChartPaging: Equatable, Sendable {
    public var occupiedOffsets: [Int]

    public init(occupiedOffsets: [Int]) {
        self.occupiedOffsets = occupiedOffsets
    }

    public func neighborTowardPast(from offset: Int) -> Int? {
        occupiedOffsets.first { $0 > offset }
    }

    public func neighborTowardNow(from offset: Int) -> Int? {
        occupiedOffsets.last { $0 < offset }
    }
}

public struct HistoryChartReading: Equatable, Sendable {
    public let date: Date
    public let amount: Double

    public init(date: Date, amount: Double) {
        self.date = date
        self.amount = amount
    }
}

public enum HistoryChartState: Equatable, Sendable {
    case spend(
        points: [HistoryChartReading],
        start: Date,
        end: Date,
        monthly: Bool,
        isIntervalSpend: Bool
    )
    case balance(
        points: [HistoryChartReading],
        start: Date,
        end: Date,
        monthly: Bool,
        /// 到下一个点的连线是推断段的那些起点。
        inferredSegmentStarts: [Date]
    )
    case none
}

public enum HistoryChartMath {
    public static func make(
        kind: ProviderKind,
        snapshots: [Snapshot],
        range: HistoryChartRange,
        now: Date,
        calendar: Calendar,
        offset: Int = 0,
        spanLookback: Bool = false
    ) -> HistoryChartState {
        switch kind {
        case .usage, .planAndUsage:
            return spend(
                snapshots: snapshots,
                range: range,
                now: now,
                calendar: calendar,
                offset: offset,
                spanLookback: spanLookback
            )
        case .prepaid:
            return balance(
                snapshots: snapshots,
                range: range,
                now: now,
                calendar: calendar,
                offset: offset,
                spanLookback: spanLookback
            )
        case .subscription, .freeTier:
            return .none
        }
    }

    private static func spend(
        snapshots: [Snapshot],
        range: HistoryChartRange,
        now: Date,
        calendar: Calendar,
        offset: Int,
        spanLookback: Bool
    ) -> HistoryChartState {
        // 可平移的日线图要整段 12 个月的点，看得见的宽度由视图去裁。
        let window = spanLookback && !range.isMonthly
            ? Self.window(range: .months12, now: now, calendar: calendar)
            : Self.window(range: range, now: now, calendar: calendar, offset: offset)
        if range.isMonthly {
            let expected = periods(from: window.start, through: window.end, monthly: true, calendar: calendar)
            let history = MonthSpendHistoryCalculator.compute(
                snapshots: snapshots,
                subscriptions: [],
                now: now,
                calendar: calendar,
                monthCount: expected.count
            )
            let points = history.compactMap { point -> HistoryChartReading? in
                guard point.variableUSD > .zero else { return nil }
                return HistoryChartReading(
                    date: point.monthStart,
                    amount: NSDecimalNumber(decimal: point.variableUSD.usd).doubleValue
                )
            }
            return .spend(
                points: points,
                start: window.start,
                end: window.end,
                monthly: true,
                isIntervalSpend: false
            )
        }
        let fromDaily = mergedDailyAmounts(snapshots: snapshots, calendar: calendar)
        let inWindow = Dictionary(uniqueKeysWithValues: fromDaily.filter { day, _ in
            day >= window.start && day <= window.end
        })
        let interval = intervalSpendByDay(snapshots: snapshots, window: window, calendar: calendar)
        let expected = periods(from: window.start, through: window.end, monthly: false, calendar: calendar)
        if spanLookback {
            // 每一天自己决定：有日线用日线，没有再用两次读数的差。
            // 不能整段二选一——否则七月的日线会把八月的差量图顶掉，
            // 或反过来八月的空窗让七月的柱全部消失。
            var usedInterval = false
            let points = expected.compactMap { day -> HistoryChartReading? in
                if let amount = inWindow[day] {
                    return HistoryChartReading(date: day, amount: amount)
                }
                if let amount = interval[day] {
                    usedInterval = true
                    return HistoryChartReading(date: day, amount: amount)
                }
                return nil
            }
            return .spend(
                points: points,
                start: window.start,
                end: window.end,
                monthly: false,
                isIntervalSpend: usedInterval
            )
        }
        // 历史回填常把过去几个月的合计写在每月 1 号。那些点不在 7/30 天窗里，
        // 但不能因此让「窗内有日线」成立——否则本月至今的差量图会被整表日线顶掉。
        let usedInterval = inWindow.isEmpty
        let daily = usedInterval ? interval : inWindow
        let points = expected.compactMap { day -> HistoryChartReading? in
            guard let amount = daily[day] else { return nil }
            return HistoryChartReading(date: day, amount: amount)
        }
        return .spend(
            points: points,
            start: window.start,
            end: window.end,
            monthly: false,
            isIntervalSpend: usedInterval && !points.isEmpty
        )
    }

    private static func balance(
        snapshots: [Snapshot],
        range: HistoryChartRange,
        now: Date,
        calendar: Calendar,
        offset: Int,
        spanLookback: Bool
    ) -> HistoryChartState {
        let window = spanLookback && !range.isMonthly
            ? Self.window(range: .months12, now: now, calendar: calendar)
            : Self.window(range: range, now: now, calendar: calendar, offset: offset)
        let monthly = range.isMonthly
        let readings = latestBalanceByPeriod(
            snapshots: snapshots,
            window: window,
            monthly: monthly,
            calendar: calendar
        )
        let expected = periods(from: window.start, through: window.end, monthly: monthly, calendar: calendar)
        let points = expected.compactMap { period -> HistoryChartReading? in
            readings[period]
        }
        let inferred = inferredSegmentStarts(points: points, monthly: monthly, calendar: calendar)
        return .balance(
            points: points,
            start: window.start,
            end: window.end,
            monthly: monthly,
            inferredSegmentStarts: inferred
        )
    }

    public static func window(
        range: HistoryChartRange,
        now: Date,
        calendar: Calendar,
        offset: Int = 0
    ) -> (start: Date, end: Date) {
        let end = calendar.startOfDay(for: now)
        switch range {
        case .days7, .days30:
            let length = range.pageStepDays ?? 7
            let homeStart = calendar.date(byAdding: .day, value: -(length - 1), to: end) ?? end
            let page = max(0, offset)
            guard page > 0 else { return (homeStart, end) }
            let shift = length * page
            let shiftedEnd = calendar.date(byAdding: .day, value: -shift, to: end) ?? end
            let shiftedStart = calendar.date(byAdding: .day, value: -shift, to: homeStart) ?? homeStart
            return (shiftedStart, shiftedEnd)
        case .months12:
            let monthStart = startOfMonth(now, calendar: calendar)
            let start = calendar.date(byAdding: .month, value: -11, to: monthStart) ?? monthStart
            return (start, end)
        }
    }

    /// 哪些页有柱或点。**一次扫完全部读数**，不要按页去 `make`——
    /// 详情页第一次横滑才问这件事，打开这一页的默认路径不许付这份钱。
    public static func paging(
        kind: ProviderKind,
        snapshots: [Snapshot],
        range: HistoryChartRange,
        now: Date,
        calendar: Calendar
    ) -> HistoryChartPaging {
        guard let step = range.pageStepDays else {
            return HistoryChartPaging(occupiedOffsets: [0])
        }
        switch kind {
        case .subscription, .freeTier:
            return HistoryChartPaging(occupiedOffsets: [])
        case .usage, .planAndUsage, .prepaid:
            break
        }

        let home = window(range: range, now: now, calendar: calendar)
        let lookbackStart = window(range: .months12, now: now, calendar: calendar).start
        let span = calendar.dateComponents([.day], from: lookbackStart, to: home.start).day ?? 0
        let maxOffset = max(0, span / step)

        let occupiedDates: Set<Date>
        switch kind {
        case .prepaid:
            occupiedDates = Set(
                latestBalanceByPeriod(
                    snapshots: snapshots,
                    window: (lookbackStart, home.end),
                    monthly: false,
                    calendar: calendar
                ).keys
            )
        case .usage, .planAndUsage:
            let daily = mergedDailyAmounts(snapshots: snapshots, calendar: calendar)
            let interval = intervalSpendByDay(
                snapshots: snapshots,
                window: (lookbackStart, home.end),
                calendar: calendar
            )
            occupiedDates = Set(daily.keys).union(interval.keys)
        case .subscription, .freeTier:
            occupiedDates = []
        }

        var occupied: [Int] = []
        occupied.reserveCapacity(min(maxOffset + 1, occupiedDates.count + 1))
        for page in 0...maxOffset {
            let pageWindow = window(range: range, now: now, calendar: calendar, offset: page)
            if occupiedDates.contains(where: { $0 >= pageWindow.start && $0 <= pageWindow.end }) {
                occupied.append(page)
            }
        }
        return HistoryChartPaging(occupiedOffsets: occupied)
    }

    /// 横轴的完整桶序列（当天/当月零点）——缺读数的桶留空位，不补 0。
    public static func periods(
        from start: Date,
        through end: Date,
        monthly: Bool,
        calendar: Calendar
    ) -> [Date] {
        let first = periodStart(start, monthly: monthly, calendar: calendar)
        let last = periodStart(end, monthly: monthly, calendar: calendar)
        var cursor = first
        var result: [Date] = []
        let component: Calendar.Component = monthly ? .month : .day
        while cursor <= last {
            result.append(cursor)
            guard let next = calendar.date(byAdding: component, value: 1, to: cursor) else { break }
            cursor = next
        }
        return result
    }

    static func inferredSegmentStarts(
        points: [HistoryChartReading],
        monthly: Bool,
        calendar: Calendar
    ) -> [Date] {
        guard points.count >= 2 else { return [] }
        let sorted = points.sorted { $0.date < $1.date }
        return zip(sorted, sorted.dropFirst()).compactMap { start, end in
            isAdjacent(start.date, end.date, monthly: monthly, calendar: calendar) ? nil : start.date
        }
    }

    private static func mergedDailyAmounts(snapshots: [Snapshot], calendar: Calendar) -> [Date: Double] {
        SnapshotDailyMap.merged(from: snapshots, calendar: calendar).mapValues { money in
            NSDecimalNumber(decimal: money.usd).doubleValue
        }
    }

    /// 没有按日拆开的账单时：同一账期里两次本月至今的差，就是这段新花的钱。
    /// 记在后一次读到的那天。缺的日子仍是不知道，不补 0。跨月从 0 再起。
    private static func intervalSpendByDay(
        snapshots: [Snapshot],
        window: (start: Date, end: Date),
        calendar: Calendar
    ) -> [Date: Double] {
        let rows = snapshots.filter { $0.kind.contributesUsageComparison && $0.currentSpendUSD != nil }
        let grouped = Dictionary(grouping: rows) { $0.accountID }
        var result: [Date: Double] = [:]
        for (_, accountRows) in grouped {
            var byDay: [Date: (fetchedAt: Date, month: Date, amount: Double)] = [:]
            for snapshot in accountRows {
                guard let spend = snapshot.currentSpendUSD else { continue }
                // 事后补填的过去月份是整月合计，不是「读到那天」的观测。
                if snapshot.source == .manual,
                   !calendar.isDate(snapshot.fetchedAt, equalTo: snapshot.periodStart, toGranularity: .month) {
                    continue
                }
                let day = calendar.startOfDay(for: snapshot.fetchedAt)
                let month = startOfMonth(snapshot.periodStart, calendar: calendar)
                if let existing = byDay[day], existing.fetchedAt > snapshot.fetchedAt { continue }
                byDay[day] = (
                    snapshot.fetchedAt,
                    month,
                    NSDecimalNumber(decimal: spend.usd).doubleValue
                )
            }
            var previous: (month: Date, amount: Double)?
            for day in byDay.keys.sorted() {
                let reading = byDay[day]!
                let delta: Double
                if let previous, calendar.isDate(previous.month, equalTo: reading.month, toGranularity: .month) {
                    delta = reading.amount - previous.amount
                } else {
                    delta = reading.amount
                }
                previous = (reading.month, reading.amount)
                guard day >= window.start, day <= window.end, delta > 0 else { continue }
                result[day, default: 0] += delta
            }
        }
        return result
    }

    private static func latestBalanceByPeriod(
        snapshots: [Snapshot],
        window: (start: Date, end: Date),
        monthly: Bool,
        calendar: Calendar
    ) -> [Date: HistoryChartReading] {
        var result: [Date: (fetchedAt: Date, point: HistoryChartReading)] = [:]
        for snapshot in snapshots {
            guard let balance = snapshot.balanceUSD else { continue }
            let bucket = periodStart(snapshot.fetchedAt, monthly: monthly, calendar: calendar)
            let windowEndBucket = periodStart(window.end, monthly: monthly, calendar: calendar)
            guard bucket >= window.start, bucket <= windowEndBucket else { continue }
            if let existing = result[bucket], existing.fetchedAt > snapshot.fetchedAt {
                continue
            }
            result[bucket] = (
                snapshot.fetchedAt,
                HistoryChartReading(
                    date: bucket,
                    amount: NSDecimalNumber(decimal: balance.usd).doubleValue
                )
            )
        }
        return result.mapValues(\.point)
    }

    private static func isAdjacent(
        _ lhs: Date,
        _ rhs: Date,
        monthly: Bool,
        calendar: Calendar
    ) -> Bool {
        let start = periodStart(lhs, monthly: monthly, calendar: calendar)
        let end = periodStart(rhs, monthly: monthly, calendar: calendar)
        if monthly {
            return calendar.dateComponents([.month], from: start, to: end).month == 1
        }
        return calendar.dateComponents([.day], from: start, to: end).day == 1
    }

    private static func periodStart(_ date: Date, monthly: Bool, calendar: Calendar) -> Date {
        monthly ? startOfMonth(date, calendar: calendar) : calendar.startOfDay(for: date)
    }

    private static func startOfMonth(_ date: Date, calendar: Calendar) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date))
            ?? calendar.startOfDay(for: date)
    }
}
