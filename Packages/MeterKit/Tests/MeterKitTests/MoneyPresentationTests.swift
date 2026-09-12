import Foundation
import Testing
@testable import MeterCore

struct MoneyPresentationTests {
    private let rates = ExchangeRates(usdPerUnit: [
        "CNY": Decimal(string: "0.1404")!,
        "JPY": Decimal(string: "0.00655")!,
    ])

    @Test("人民币按目录汇率折回去")
    func convertsUSDToCNY() {
        let presentation = MoneyPresentation(currencyCode: "cny", rates: rates)
        #expect(presentation.currencyCode == "CNY")
        #expect(presentation.amount(from: Money(roundedUSD: 47.20)) == Decimal(string: "336.18"))
        #expect(presentation.string(from: Money(roundedUSD: 47.20)) == "¥336.18")
    }

    @Test("日元不写小数")
    func formatsYenWithoutFraction() {
        let presentation = MoneyPresentation(currencyCode: "JPY", rates: rates)
        #expect(presentation.string(from: Money(roundedUSD: 47.20)) == "¥7,206")
    }

    @Test("原币正好是展示币时用厂商原值，避免折来折去差一分")
    func prefersOriginalAmountWhenCurrencyMatches() {
        let presentation = MoneyPresentation(currencyCode: "CNY", rates: rates)
        let original = ConvertedAmount(
            currency: "CNY",
            amount: Decimal(string: "49.58894")!,
            usdPerUnit: Decimal(string: "0.1404")!,
            usd: Decimal(string: "6.96")!
        )
        #expect(presentation.string(from: Money(roundedUSD: 6.96), original: original) == "¥49.59")
        #expect(presentation.string(from: Money(roundedUSD: 6.96)) == "¥49.57")
    }

    @Test("表里没有的币种退回美元，不猜汇率")
    func unknownCurrencyFallsBackToUSD() {
        let presentation = MoneyPresentation(currencyCode: "XYZ", rates: rates)
        #expect(presentation.isUSD)
        #expect(presentation.string(from: Money(roundedUSD: 47.20)) == "$47.20")
    }

    @Test("美元展示和以前的 formatted 一样")
    func usdMatchesLegacyFormatter() {
        #expect(Money(roundedUSD: 47.20).formatted(using: .usd) == "$47.20")
        #expect(Money(roundedUSD: 47.20).formatted() == "$47.20")
        #expect(Money(roundedUSD: 1_234.56).formatted() == "$1,234.56")
    }

    @Test("1 单位原币折成展示币，原币就是展示币时不写")
    func unitRateFollowsDisplayCurrency() {
        let original = ConvertedAmount(
            currency: "CNY",
            amount: 15,
            usdPerUnit: Decimal(string: "0.1404")!,
            usd: Decimal(string: "2.11")!
        )

        let usd = MoneyPresentation(currencyCode: "USD", rates: rates)
        #expect(usd.unitRateString(from: original) == "$0.1404")

        let yen = MoneyPresentation(currencyCode: "JPY", rates: rates)
        #expect(yen.unitRateString(from: original) == "¥21")

        let yuan = MoneyPresentation(currencyCode: "CNY", rates: rates)
        #expect(yuan.unitRateString(from: original) == nil)

        let euroRates = ExchangeRates(usdPerUnit: [
            "CNY": Decimal(string: "0.1404")!,
            "EUR": Decimal(string: "1.0850")!,
        ])
        let euro = MoneyPresentation(currencyCode: "EUR", rates: euroRates)
        #expect(euro.unitRateString(from: original) == "€0.13")

        let dollars = ConvertedAmount(currency: "USD", amount: 10, usdPerUnit: 1, usd: 10)
        #expect(usd.unitRateString(from: dollars) == nil)
    }
}
