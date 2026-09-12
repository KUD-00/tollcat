import Foundation
import MeterCore

extension ProviderCatalog {
    public static let alibabacloud = ProviderDescriptor(
        id: .alibabacloud,
        displayName: "Alibaba Cloud",
        kind: .usage,
        category: .hosting,
        tier: .one,
        tierReason: "亚太超大规模云龙头，与 AWS / Azure / GCP 并列全球公有云短名单；BSS QueryBillOverview 同资源 PretaxAmount+Currency。",
        colorKey: "alibabacloud",
        billingURL: URL(string: "https://usercenter2.aliyun.com/finance/expense-report")!,
        credentialSetupURL: URL(string: "https://ram.console.aliyun.com/manage/ak")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["alibaba", "aliyun", "阿里云", "bss", "querybilloverview", "accesskey"]
    )
}
