import Foundation
import MeterCore

extension ProviderCatalog {
    public static let kingsoftcloud = ProviderDescriptor(
        id: .kingsoftcloud,
        displayName: "Kingsoft Cloud",
        kind: .usage,
        category: .hosting,
        tier: .two,
        tierReason: "国内主流公有云短名单常见（金山云），体量次于阿里云 / 华为云 / 腾讯云；DescribeBillSummaryByProduct 同资源 RealTotalCost+Currency。",
        colorKey: "kingsoftcloud",
        billingURL: URL(string: "https://bill.console.ksyun.com/")!,
        credentialSetupURL: URL(string: "https://ucenter.console.ksyun.com/#/api")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["ksyun", "kingsoft", "金山云", "bill-union", "describebillsummarybyproduct", "accesskey"]
    )
}
