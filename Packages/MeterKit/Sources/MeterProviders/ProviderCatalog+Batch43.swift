import Foundation
import MeterCore

extension ProviderCatalog {
    public static let tencentcloud = ProviderDescriptor(
        id: .tencentcloud,
        displayName: "Tencent Cloud",
        kind: .usage,
        category: .hosting,
        tier: .one,
        tierReason: "国内超大规模公有云龙头，与阿里云 / AWS / Azure 并列全球短名单；DescribeBillDetail 同资源 Component.RealCost+Currency。",
        colorKey: "tencentcloud",
        billingURL: URL(string: "https://console.cloud.tencent.com/expense/bill/overview")!,
        credentialSetupURL: URL(string: "https://console.cloud.tencent.com/cam/capi")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["tencent", "qcloud", "腾讯云", "billing", "describebilldetail", "tc3", "secretid"]
    )
}
