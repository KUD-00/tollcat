import Foundation

/// 取景框的时间那一维。**全部是整月，一个都不例外。**
///
/// 「按日看」故意不做。这个数据模型里，一个非整月的窗口必须编两处数：
/// 只有周期累计的那几家得按天摊（本来就已经 `.estimated`），固定订阅更糟——
/// 月费不是日费，切成半个月就得凭空造一个数。做成整月之后，多月区间只是
/// **把若干个单月结果加起来**，每一项都还是原来那个已经被测过的算法，
/// 于是「筛选永远不改 `Confidence`」这条老规矩一个字都不用动。
///
/// 想按日看的人有地方去：详情页的历史图有 7 天 / 30 天两档，那是按天读的
/// 原始读数，不是折算过的合计。
public enum DashboardPeriod: Hashable, Sendable {
    /// 往前最多翻 11 个月，和详情页「12 个月」那档对齐。
    ///
    /// 常量住在这里而不是取景框那个结构上：它约束的是**时间那一维**能有多深，
    /// 和排除名单、订阅口径没有关系。取景框上那个同名常量转发到这里。
    public static let maxMonthsBack = 11

    /// 从 `back` 那个月起往前数 `count` 个整月。
    ///
    /// `back` 是**窗口里最新的那个月**（0 = 本月），和旧的 `monthsBack` 同义；
    /// `count` = 1 就是原来的单月，整个 App 的默认视角 `.months(back: 0, count: 1)`。
    /// 「近 3 个月」是 `.months(back: 0, count: 3)`，「五月–七月」是
    /// `.months(back: 2, count: 3)`——预设和自定义走同一个 case，不必分两种。
    case months(back: Int, count: Int)
    /// 今年 1 月 1 日到此刻。**不能存成算好的 `count`**：那样元旦一过，
    /// 「今年至今」就变成了「去年 4 月到今年 1 月」。存意图，每次现算。
    case yearToDate
    /// 有读数以来的全部整月。上界由数据决定，所以要到 `window(earliestMonthsBack:)`
    /// 那一步才知道有多长。
    case allTime

    public static let currentMonth = DashboardPeriod.months(back: 0, count: 1)

    /// 规范化：钳边界，并且把 `count == 1` 之外没有意义的写法收敛掉。
    /// 构造点全部走这里，`.months(back: 0, count: 1)` 才是唯一的「本月」写法。
    public var normalized: DashboardPeriod {
        switch self {
        case let .months(back, count):
            let clampedBack = min(max(back, 0), DashboardPeriod.maxMonthsBack)
            let room = DashboardPeriod.maxMonthsBack - clampedBack + 1
            let clampedCount = min(max(count, 1), room)
            return .months(back: clampedBack, count: clampedCount)
        case .yearToDate, .allTime:
            return self
        }
    }

    /// 只有 `.months(back: 0, count: 1)` 是「本月」。
    ///
    /// 「今年至今」在 1 月份**解析出来**也只有本月一个月，但它不是本月——
    /// 用户选的是一个会自己长大的区间，标题、预计月底、分享卡都该按它的意图走。
    public var isCurrentMonth: Bool {
        self == .months(back: 0, count: 1)
    }

    /// 窗口里最新的那个月往前几个月。锚点只由它决定，和窗口多长无关。
    public var newestMonthsBack: Int {
        switch self {
        case let .months(back, _): min(max(back, 0), DashboardPeriod.maxMonthsBack)
        case .yearToDate, .allTime: 0
        }
    }

    /// 窗口是否压着「此刻」。余额告急、即将扣款、免费额度这类现在时模块看它——
    /// 看「近 3 个月」时它们仍然成立，看「七月」时不成立。
    public var containsNow: Bool { newestMonthsBack == 0 }

    /// 只有单个当月才谈得上「预计月底」。多月区间没有可推的东西，
    /// 过去的月份已经结束。
    public var allowsProjection: Bool { isCurrentMonth }

    // MARK: - 落盘 / 过桥

    /// 存三个标量而不是一整份 JSON：偏好那张表本来就是一行标量，
    /// 而 `filterMonthsBack` 那一列已经在旧库里了——加两列的迁移是「补默认值」，
    /// 把它改成 JSON 才是真的迁移。Android / Windows 的 JNI 桥也读同样三个字段。
    public var storageKind: String {
        switch self {
        case .months: "months"
        case .yearToDate: "yearToDate"
        case .allTime: "allTime"
        }
    }

    public var storageMonthCount: Int {
        switch normalized {
        case let .months(_, count): count
        case .yearToDate, .allTime: 1
        }
    }

    /// 认不出来的 kind 一律回落到单月。旧库（没有这两列）读出来是
    /// `kind = "months"` / `count = 1`，也就是原来的行为，一个字节都没变。
    public static func fromStorage(kind: String, monthsBack: Int, monthCount: Int) -> DashboardPeriod {
        switch kind {
        case "yearToDate": .yearToDate
        case "allTime": .allTime
        default: DashboardPeriod.months(back: monthsBack, count: monthCount).normalized
        }
    }

    /// 折算时当作「此刻」的那个时间点，也就是**窗口的最后一瞬**。
    ///
    /// 往前翻时取目标月的最后一瞬，这一手同时解决三件事：
    /// 1. `monthStart` 由它反推，正好是目标月 1 号；
    /// 2. 日粒度求和的上界 `day < now` 覆盖整月；
    /// 3. 「已过天数」= 当月天数，于是外推系数为 1，
    ///    「预计月底」自然等于总数——月份结束了，没有可推的东西。
    ///
    /// 区间多长不影响这里：锚点只认最新的那个月。
    public func anchor(now: Date, calendar: Calendar) -> Date {
        let back = newestMonthsBack
        guard back > 0 else { return now }
        guard
            let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
            let targetStart = calendar.date(byAdding: .month, value: -back, to: thisMonthStart),
            let nextStart = calendar.date(byAdding: .month, value: 1, to: targetStart)
        else {
            return now
        }
        return nextStart.addingTimeInterval(-1)
    }

    /// 把意图解析成一段具体的整月窗口。
    ///
    /// - Parameter earliestMonthsBack: 手上最老的那笔数据在几个月前。只有
    ///   `.allTime` 用得到；给 nil 就铺满能回看的全部月份。
    public func window(
        now: Date,
        calendar: Calendar,
        earliestMonthsBack: Int? = nil
    ) -> MonthWindow {
        switch normalized {
        case let .months(back, count):
            return MonthWindow(newestBack: back, oldestBack: back + count - 1)
        case .yearToDate:
            let month = calendar.component(.month, from: now)
            return MonthWindow(newestBack: 0, oldestBack: max(month - 1, 0))
        case .allTime:
            let oldest = earliestMonthsBack ?? DashboardPeriod.maxMonthsBack
            return MonthWindow(newestBack: 0, oldestBack: max(oldest, 0))
        }
    }
}

/// 解析之后的整月窗口，两端都是「往前几个月」。闭区间。
///
/// 用整数而不是日期对，是因为下游每一步（折算、月份标题、趋势柱）本来就按
/// 「往前第几个月」寻址；换成日期只会让每一处再算一遍月首月末。
public struct MonthWindow: Hashable, Sendable {
    /// 0 = 本月。
    public var newestBack: Int
    /// 永远 >= `newestBack`。
    public var oldestBack: Int

    public init(newestBack: Int, oldestBack: Int) {
        let newest = min(max(newestBack, 0), DashboardPeriod.maxMonthsBack)
        let oldest = min(max(oldestBack, newest), DashboardPeriod.maxMonthsBack)
        self.newestBack = newest
        self.oldestBack = oldest
    }

    public static let currentMonth = MonthWindow(newestBack: 0, oldestBack: 0)

    public var monthCount: Int { oldestBack - newestBack + 1 }

    public var isSingleMonth: Bool { monthCount == 1 }

    /// 从新到旧。折算按这个顺序跑，`facts` 的合并顺序才是稳定的。
    public var monthsBackNewestFirst: [Int] {
        Array(newestBack...oldestBack)
    }

    /// 窗口第一天的零点。
    public func start(now: Date, calendar: Calendar) -> Date {
        guard
            let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
            let start = calendar.date(byAdding: .month, value: -oldestBack, to: thisMonthStart)
        else {
            return now
        }
        return start
    }

    /// 窗口的最后一瞬。含当月时就是「此刻」。
    public func end(now: Date, calendar: Calendar) -> Date {
        DashboardPeriod.months(back: newestBack, count: 1).anchor(now: now, calendar: calendar)
    }
}
