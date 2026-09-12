import Foundation
import Testing
import MeterCore
@testable import MeterFeatures

struct OnboardingDemoContentTests {
    @Test("按新用户默认口径（仅从量）：大数字 43.20，订阅那行不出现，构成里没有订阅段")
    func heroFollowsDefaultUsageOnlyScope() throws {
        let presentation = MoneyPresentation.usd
        let month = OnboardingDemoContent.monthToDateModule(presentation: presentation)
        #expect(month.amountText == "$43.20")
        #expect(month.subscriptionCaption == nil)
        #expect(!month.includesSubscriptions)
        #expect(month.showsSubscriptionScope)

        let composition = try #require(OnboardingDemoContent.composition(presentation: presentation))
        #expect(composition.totalText == "$43.20")
        #expect(composition.segments.map(\.providerID) == [.aws, .cloudflare, .openai, .neon])
    }

    @Test("显示货币变了，预览金额跟着改写")
    func currencyRewritesThePreview() throws {
        let rates = ExchangeRates(usdPerUnit: ["CNY": Decimal(string: "0.14") ?? 0.14])
        let cny = MoneyPresentation(currencyCode: "CNY", rates: rates)
        let month = OnboardingDemoContent.monthToDateModule(presentation: cny)
        #expect(month.amountText != "$43.20")
        #expect(!month.amountText.contains("$"))

        let composition = try #require(OnboardingDemoContent.composition(presentation: cny))
        #expect(composition.totalText == month.amountText)
    }

    @Test("添加预览是设计稿里那四家")
    func addPreviewProviders() {
        #expect(OnboardingDemoContent.addPreviewIDs == [.aws, .cloudflare, .openai, .github])
    }
}
