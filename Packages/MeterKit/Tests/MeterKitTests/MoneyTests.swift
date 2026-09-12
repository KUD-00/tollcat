import Foundation
import Testing
@testable import MeterCore

struct MoneyTests {
    @Test("精确金额格式化为 $47.20")
    func formatsExactDollars() {
        let money = Money(roundedUSD: 47.20)
        #expect(money.formatted() == "$47.20")
    }

    @Test("SPEC 第 04 节那组分项加总得 $47.20")
    func specFixtureCentsAddUp() {
        let total = Money(roundedUSD: 21.40)
            + Money(roundedUSD: 11.05)
            + Money(roundedUSD: 7.62)
            + Money(roundedUSD: 4.00)
            + Money(roundedUSD: 3.13)
        #expect(total.roundedToCents() == Money(roundedUSD: 47.20))
        #expect(total.formatted() == "$47.20")
    }

    @Test("千分位固定 $ 前缀，不跟随系统 locale")
    func formatsThousandsWithoutLocaleCurrencyPrefix() {
        #expect(Money(roundedUSD: 999.99).formatted() == "$999.99")
        #expect(Money(usd: 1000).formatted() == "$1,000.00")
        #expect(Money(usd: Decimal(string: "1234567.89")!).formatted() == "$1,234,567.89")
        #expect(Money(roundedUSD: -1234.56).formatted() == "-$1,234.56")
    }
}
