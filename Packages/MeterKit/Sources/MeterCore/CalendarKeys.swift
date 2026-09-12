import Foundation

/// 日历上的**某一天**——年、月、日三个分量，不带时区，不是一个瞬间。
///
/// ## 为什么要有它
///
/// 这个 App 里「哪一天」出现在三处：厂商日粒度桶的键、账本行的月份、订阅的锚点。
/// 三处说的都是**日历上的位置**，可前两处一直被存成 `Date`（某个时区的零点那一刻）。
/// 零点那一刻是随时区变的：东京的 8 月 15 日零点，在纽约日历上是 8 月 14 日。于是
/// 换过时区之后，落盘时按东京记下的一整张日表在纽约读出来整体错一天；同一个厂商日
/// 在两地各刷一次，还会变成两个键、被算两遍。`SubscriptionRecord` 早就为这件事改成了
/// 存年/月/日三分量（见它的注释），这个类型是把同一条教训推到剩下两处。
///
/// ## 规矩
///
/// - **落盘只存分量**（`storageString` 是 `yyyy-MM-dd`），绝不存 `TimeInterval`。
/// - 域层仍然拿 `Date` 当键（零点那一刻），但那个 `Date` 只是「此刻这本日历上
///   这一天的零点」——它是从分量**算出来**的，不是存下来的。换日历再算一次即可。
/// - 分量按调用方给的日历解释。厂商的日桶是 UTC 日，本机的展示是本地日，
///   谁负责翻译在 `BillingDateParser` 里写着；这里只装数字。
public struct DayKey: Hashable, Sendable, Codable, Comparable {
    public var year: Int
    public var month: Int
    public var day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// 某一刻在这本日历上是哪一天。
    public init(_ date: Date, calendar: Calendar) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        self.year = parts.year ?? 0
        self.month = parts.month ?? 0
        self.day = parts.day ?? 0
    }

    /// 这一天在这本日历上的零点。分量不合法（比如 2 月 30 日）返回 nil，不猜。
    public func date(in calendar: Calendar) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        guard
            let date = calendar.date(from: components),
            calendar.dateComponents([.year, .month, .day], from: date) == components
        else {
            return nil
        }
        return calendar.startOfDay(for: date)
    }

    /// `yyyy-MM-dd`。落盘用这个，不用时间戳。
    public var storageString: String {
        Self.pad(year, 4) + "-" + Self.pad(month, 2) + "-" + Self.pad(day, 2)
    }

    public init?(storageString raw: String) {
        let parts = raw.split(separator: "-", omittingEmptySubsequences: false)
        guard
            parts.count == 3,
            let year = Int(parts[0]),
            let month = Int(parts[1]),
            let day = Int(parts[2]),
            (1...12).contains(month),
            (1...31).contains(day)
        else {
            return nil
        }
        self.init(year: year, month: month, day: day)
    }

    public static func < (lhs: DayKey, rhs: DayKey) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    private static func pad(_ value: Int, _ width: Int) -> String {
        let digits = String(value)
        return digits.count >= width ? digits : String(repeating: "0", count: width - digits.count) + digits
    }
}

/// 日历上的**某个月**。账本行的主键之一：一行说的是「这个账号、这个月」，
/// 不是「从某一刻到某一刻」。理由同 `DayKey`。
public struct MonthKey: Hashable, Sendable, Codable, Comparable {
    public var year: Int
    public var month: Int

    public init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }

    public init(_ date: Date, calendar: Calendar) {
        let parts = calendar.dateComponents([.year, .month], from: date)
        self.year = parts.year ?? 0
        self.month = parts.month ?? 0
    }

    /// 这个月 1 号在这本日历上的零点。
    public func monthStart(in calendar: Calendar) -> Date? {
        guard (1...12).contains(month) else { return nil }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        return calendar.date(from: components).map { calendar.startOfDay(for: $0) }
    }

    public static func < (lhs: MonthKey, rhs: MonthKey) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }
}
