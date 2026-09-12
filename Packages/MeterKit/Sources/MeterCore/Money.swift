import Foundation

/// 业务金额统一走这个类型，避免裸 `Double` 把分位和单位散落各处。
public struct Money: Hashable, Sendable, Codable, Comparable {
    public let usd: Decimal

    public static let zero = Money(usd: Decimal(0))

    public init(usd: Decimal) {
        self.usd = usd
    }

    public init(usd: Int) {
        self.usd = Decimal(usd)
    }

    /// **入口就按分四舍五入。**名字里带 `rounded` 是因为它真的会丢精度：
    /// `0.004` 进来就是 `0`。
    ///
    /// 取整本来是展示的事，不是构造的事——一个照着夹具写的适配器把日桶
    /// （$0.003/天）喂进来，每天变 $0、月合计也是 $0，而 `Money` 这个类型
    /// 本该正是防这个的。所以这条入口只给**夹具和比例**用：厂商适配器一律走
    /// `FlexibleDecimal` → `init(usd: Decimal)`，一分不丢。
    ///
    /// 叫 `usd` 的时候它长得和另外两条一模一样，谁都不会想到它会四舍五入。
    public init(roundedUSD: Double) {
        // 按分四舍五入后再进 Decimal，避开二进制浮点把 21.40 写成 21.3999…
        var value = Decimal(roundedUSD)
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, 2, .plain)
        self.usd = rounded
    }

    public static func + (lhs: Money, rhs: Money) -> Money {
        Money(usd: lhs.usd + rhs.usd)
    }

    public static func += (lhs: inout Money, rhs: Money) {
        lhs = lhs + rhs
    }

    public static func - (lhs: Money, rhs: Money) -> Money {
        Money(usd: lhs.usd - rhs.usd)
    }

    public static func * (lhs: Money, rhs: Decimal) -> Money {
        Money(usd: lhs.usd * rhs)
    }

    public static func / (lhs: Money, rhs: Decimal) -> Money {
        Money(usd: lhs.usd / rhs)
    }

    public static func < (lhs: Money, rhs: Money) -> Bool {
        lhs.usd < rhs.usd
    }

    public func roundedToCents() -> Money {
        var value = usd
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, 2, .plain)
        return Money(usd: rounded)
    }

    /// 金额写成字。默认按美元写，和账本一致。
    public func formatted() -> String {
        formatted(using: .usd)
    }

    public func formatted(using presentation: MoneyPresentation) -> String {
        presentation.string(from: self)
    }
}
