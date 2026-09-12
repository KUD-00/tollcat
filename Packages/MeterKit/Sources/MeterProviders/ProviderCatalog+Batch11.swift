import Foundation
import MeterCore

extension ProviderCatalog {
    public static let shippo = ProviderDescriptor(
        id: .shippo,
        displayName: "Shippo",
        kind: .usage,
        category: .other,
        tier: .two,
        tierReason: "开发者物流 API 的强挑战者，与 EasyPost 并列短名单。",
        colorKey: "shippo",
        billingURL: URL(string: "https://apps.goshippo.com/")!,
        credentialSetupURL: URL(string: "https://docs.goshippo.com/docs/guides_general/authentication/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["shippo", "shipping", "label", "goshippo"]
    )

    public static let printful = ProviderDescriptor(
        id: .printful,
        displayName: "Printful",
        kind: .usage,
        category: .other,
        tier: .one,
        tierReason: "按需印刷履约的龙头之一，品牌与卖家渗透率最高。",
        colorKey: "printful",
        billingURL: URL(string: "https://www.printful.com/dashboard")!,
        credentialSetupURL: URL(string: "https://developers.printful.com/docs/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["printful", "print on demand", "pod", "fulfillment"]
    )

    public static let gooten = ProviderDescriptor(
        id: .gooten,
        displayName: "Gooten",
        kind: .usage,
        category: .other,
        tier: .three,
        tierReason: "按需印刷聚合细分里的小型选手。",
        colorKey: "gooten",
        billingURL: URL(string: "https://www.gooten.com/")!,
        credentialSetupURL: URL(string: "https://www.gooten.com/api-documentation/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["gooten", "print on demand", "pod", "print.io"]
    )

    public static let easyship = ProviderDescriptor(
        id: .easyship,
        displayName: "Easyship",
        kind: .usage,
        category: .other,
        tier: .two,
        tierReason: "跨境电商物流软件的强挑战者。",
        colorKey: "easyship",
        billingURL: URL(string: "https://app.easyship.com/")!,
        credentialSetupURL: URL(string: "https://developers.easyship.com/reference/billing_documents_index")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["easyship", "shipping", "fulfillment"]
    )

    public static let huaweicloud = ProviderDescriptor(
        id: .huaweicloud,
        displayName: "Huawei Cloud",
        kind: .usage,
        category: .hosting,
        tier: .two,
        tierReason: "中国公有云第二梯队强挑战者，全球份额仍小于三巨头。",
        colorKey: "huaweicloud",
        billingURL: URL(string: "https://account-intl.myhuaweicloud.com/")!,
        credentialSetupURL: URL(string: "https://support.huaweicloud.com/intl/en-us/api-oce/mbc_00008.html")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["huawei", "huaweicloud", "华为云", "bss"]
    )
}
