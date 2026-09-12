import Foundation
import Testing
import MeterCore

struct SpendLineTests {
    private func line(
        amount: Decimal,
        list: Decimal? = nil,
        quantity: Decimal? = nil,
        unit: String? = nil
    ) -> SpendLine {
        SpendLine(
            category: "actions",
            label: "Actions Linux",
            scope: "RelayOS",
            amountUSD: Money(usd: amount),
            listUSD: list.map(Money.init(usd:)),
            quantity: quantity,
            unit: unit
        )
    }

    @Test("合并同一格：金额和用量相加")
    func mergingSumsAmountAndQuantity() {
        let merged = line(amount: 1, list: 2, quantity: 10, unit: "Minutes")
            .merging(line(amount: 3, list: 4, quantity: 5, unit: "Minutes"))
        #expect(merged.amountUSD == Money(usd: 4))
        #expect(merged.listUSD == Money(usd: 6))
        #expect(merged.quantity == 15)
        #expect(merged.unit == "Minutes")
    }

    @Test("单位不一致就不给用量：加起来的数没有意义")
    func mergingDropsQuantityWhenUnitsDiffer() {
        let merged = line(amount: 1, quantity: 10, unit: "Minutes")
            .merging(line(amount: 1, quantity: 5, unit: "GigabyteHours"))
        #expect(merged.amountUSD == Money(usd: 2))
        #expect(merged.quantity == nil)
        #expect(merged.unit == nil)
    }

    @Test("只有一边有原价时按那一边算，不当成 0")
    func mergingKeepsSingleSidedListPrice() {
        #expect(line(amount: 1).merging(line(amount: 1, list: 5)).listUSD == Money(usd: 5))
        #expect(line(amount: 1, list: 5).merging(line(amount: 1)).listUSD == Money(usd: 5))
    }

    @Test("原价不高于实收就没有抵扣，不编一个负数")
    func discountNeedsHigherListPrice() {
        #expect(line(amount: 1, list: 3).discountUSD == Money(usd: 2))
        #expect(line(amount: 1, list: 1).discountUSD == nil)
        #expect(line(amount: 3, list: 1).discountUSD == nil)
        #expect(line(amount: 1).discountUSD == nil)
    }

    @Test("全被额度吃掉：实收 0，抵扣等于原价")
    func fullyDiscountedLine() {
        let free = line(amount: 0, list: Decimal(string: "10.19")!)
        #expect(free.amountUSD == .zero)
        #expect(free.discountUSD == Money(usd: Decimal(string: "10.19")!))
    }
}
