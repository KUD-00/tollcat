import Foundation
import MeterCore

extension ProviderCatalog {
    public static let make = ProviderDescriptor(
        id: .make,
        displayName: "Make",
        kind: .usage,
        category: .automation,
        tier: .two,
        tierReason: "欧洲无代码自动化龙头（原 Integromat），Celonis 旗下与 Zapier 并列短名单；组织 payments 同资源 amount_total+currency_code。",
        colorKey: "make",
        billingURL: URL(string: "https://www.make.com/en/pricing")!,
        credentialSetupURL: URL(string: "https://developers.make.com/api-documentation/authentication/create-authentication-token")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["make", "integromat", "celonis", "payments", "amount_total", "automation"]
    )
}
