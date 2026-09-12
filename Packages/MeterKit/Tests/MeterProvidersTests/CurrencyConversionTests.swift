import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct CurrencyConversionTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let cny = ExchangeRates(usdPerUnit: ["CNY": Decimal(string: "0.1404")!])

    private func window() -> CalendarMonthWindow {
        CalendarMonthWindow.current(now: now, calendar: calendar)
    }

    private func accumulator(_ code: String?) throws -> CurrencyAccumulator {
        var currency = CurrencyAccumulator()
        try currency.observe(code, providerID: .deepseek)
        return currency
    }

    @Test("美元原样通过，不挂换算说明")
    func usdPassesThroughUntouched() throws {
        let base = Snapshot(
            providerID: .cloudflare,
            accountID: AccountID.fixture(for: .cloudflare),
            kind: .usage,
            fetchedAt: now,
            periodStart: window().start,
            periodEnd: window().endInclusive,
            currentSpendUSD: Money(usd: Decimal(string: "11.05")!)
        )
        for code in ["USD", "usd", nil, ""] {
            var currency = CurrencyAccumulator()
            try currency.observe(code, providerID: .cloudflare)
            let result = try base.convertedToUSD(using: currency, rates: cny)
            #expect(result == base, "\(code ?? "nil") 不该改动快照")
            #expect(!result.isCurrencyConverted)
        }
    }

    @Test("日线跟着同一个汇率缩放，加起来仍然等于合计")
    func dailyStaysConsistentWithTotal() throws {
        var daily: [Date: Money] = [:]
        daily[LiveProviderHarness.date(2026, 8, 1)] = Money(usd: 100)
        daily[LiveProviderHarness.date(2026, 8, 2)] = Money(usd: 200)
        let base = Snapshot(
            providerID: .deepseek,
            accountID: AccountID.fixture(for: .deepseek),
            kind: .usage,
            fetchedAt: now,
            periodStart: window().start,
            periodEnd: window().endInclusive,
            currentSpendUSD: Money(usd: 300),
            dailyUSD: daily
        )
        let result = try base.convertedToUSD(using: try accumulator("CNY"), rates: cny)

        // ¥300 × 0.1404 = $42.12
        #expect(result.currentSpendUSD == Money(usd: Decimal(string: "42.12")!))
        let converted = try #require(result.dailyUSD)
        #expect(converted[LiveProviderHarness.date(2026, 8, 1)] == Money(usd: Decimal(string: "14.04")!))
        #expect(converted[LiveProviderHarness.date(2026, 8, 2)] == Money(usd: Decimal(string: "28.08")!))
        // 图和总数不许互相打脸。
        #expect(converted.values.reduce(Money.zero, +) == result.currentSpendUSD)
    }

    @Test("明细跟着同一个汇率缩放，原价也一起换")
    func linesScaleWithTheSameRate() throws {
        let base = Snapshot(
            providerID: .twilio,
            accountID: AccountID.fixture(for: .twilio),
            kind: .usage,
            fetchedAt: now,
            periodStart: window().start,
            periodEnd: window().endInclusive,
            currentSpendUSD: Money(usd: 100),
            lines: [
                SpendLine(
                    category: "sms",
                    label: "Outbound SMS",
                    amountUSD: Money(usd: 60),
                    listUSD: Money(usd: 80)
                ),
                SpendLine(
                    category: "calls",
                    label: "Outbound Calls",
                    amountUSD: Money(usd: 40)
                ),
            ]
        )
        let result = try base.convertedToUSD(using: try accumulator("CNY"), rates: cny)
        let lines = try #require(result.lines)
        #expect(lines[0].amountUSD == Money(usd: Decimal(string: "8.42")!))
        #expect(lines[0].listUSD == Money(usd: Decimal(string: "11.23")!))
        #expect(lines[1].amountUSD == Money(usd: Decimal(string: "5.62")!))
        #expect(lines.map(\.amountUSD).reduce(.zero, +) == result.currentSpendUSD)
    }

    @Test("换算说明留着原币原值和汇率，详情页才对得上账")
    func keepsOriginalAmountForDisplay() throws {
        let base = Snapshot(
            providerID: .deepseek,
            accountID: AccountID.fixture(for: .deepseek),
            kind: .prepaid,
            fetchedAt: now,
            periodStart: window().start,
            periodEnd: window().endInclusive,
            balanceUSD: Money(usd: 120)
        )
        let result = try base.convertedToUSD(using: try accumulator("CNY"), rates: cny)
        let note = try #require(result.converted)
        #expect(note.currency == "CNY")
        #expect(note.amount == 120)
        #expect(note.usdPerUnit == Decimal(string: "0.1404"))
        // 预充值这一档的主角金额是余额，不是当月花费。
        #expect(result.balanceUSD == Money(usd: Decimal(string: "16.85")!))
    }

    @Test("一次取数里混两种币种直接拒——加不到一个总数里")
    func mixedCurrenciesAreRejected() throws {
        var currency = CurrencyAccumulator()
        try currency.observe("CNY", providerID: .deepseek)
        #expect(throws: ProviderError.unsupportedCurrency(providerID: .deepseek)) {
            try currency.observe("EUR", providerID: .deepseek)
        }
    }

    @Test("同一种币种报多次没问题，大小写和空格也认")
    func repeatedSameCurrencyIsFine() throws {
        var currency = CurrencyAccumulator()
        for code in ["cny", "CNY", " CNY "] {
            try currency.observe(code, providerID: .deepseek)
        }
        #expect(currency.code == "CNY")
        #expect(currency.needsConversionNote)
    }

    @Test("汇率是 0 或负数当没有，不拿它算账")
    func rejectsNonPositiveRates() {
        let broken = ExchangeRates(usdPerUnit: ["CNY": 0, "EUR": Decimal(-1)])
        #expect(broken.toUSD(100, from: "CNY") == nil)
        #expect(broken.toUSD(100, from: "EUR") == nil)
        #expect(!broken.supports("CNY"))
    }

    @Test("换算过的读数让 confidence 降为 estimated，并出现在「哪几家是估的」里")
    func convertedReadingDowngradesConfidence() throws {
        let base = Snapshot(
            providerID: .deepseek,
            accountID: AccountID.fixture(for: .deepseek),
            kind: .usage,
            fetchedAt: now,
            periodStart: window().start,
            periodEnd: window().endInclusive,
            dailyUSD: [LiveProviderHarness.date(2026, 8, 1): Money(usd: 100)]
        )
        let converted = try base.convertedToUSD(using: try accumulator("CNY"), rates: cny)
        #expect(converted.isCurrencyConverted)
        #expect(converted.converted?.amount == 100)
        #expect(converted.converted?.usd == Decimal(string: "14.04"))

        let monthToDate = MonthToDateCalculator.compute(
            snapshots: [converted],
            subscriptions: [],
            now: now,
            calendar: calendar
        )
        #expect(monthToDate.confidence == .estimated)
        #expect(monthToDate.estimatedAccounts.contains(AccountID.fixture(for: .deepseek)))
    }

    @Test("同一份读数是美元时总数仍然是精确的")
    func usdReadingStaysExact() {
        let base = Snapshot(
            providerID: .cloudflare,
            accountID: AccountID.fixture(for: .cloudflare),
            kind: .usage,
            fetchedAt: now,
            periodStart: window().start,
            periodEnd: window().endInclusive,
            dailyUSD: [LiveProviderHarness.date(2026, 8, 1): Money(usd: 100)]
        )
        let monthToDate = MonthToDateCalculator.compute(
            snapshots: [base],
            subscriptions: [],
            now: now,
            calendar: calendar
        )
        #expect(monthToDate.confidence == .exact)
    }
}
