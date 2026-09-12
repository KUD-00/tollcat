import Foundation
import MeterCore

extension ProviderCatalog {
    public static let volcengine = ProviderDescriptor(
        id: .volcengine,
        displayName: "Volcengine",
        kind: .usage,
        category: .hosting,
        tier: .two,
        tierReason: "字节跳动旗下公有云，国内主流短名单常见，体量次于阿里云 / 华为云；ListBillDetail 同资源 PayableAmount+Currency。",
        colorKey: "volcengine",
        billingURL: URL(string: "https://console.volcengine.com/finance/bill/detail/")!,
        credentialSetupURL: URL(string: "https://console.volcengine.com/iam/keymanage/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["volcengine", "火山引擎", "bytedance", "billing", "listbilldetail", "accesskey"]
    )
}
