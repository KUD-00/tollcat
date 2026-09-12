import Foundation
import MeterCore

extension ProviderCatalog {
    public static let simply = ProviderDescriptor(
        id: .simply,
        displayName: "Simply.com",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "北欧域名/主机的区域选手。",
        colorKey: "simply",
        billingURL: URL(string: "https://www.simply.com/en/controlpanel/")!,
        credentialSetupURL: URL(string: "https://www.simply.com/en/docs/api/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["simply.com", "simply", "unoeuro", "dk host"]
    )

    public static let domeneshop = ProviderDescriptor(
        id: .domeneshop,
        displayName: "Domeneshop",
        kind: .usage,
        category: .other,
        tier: .three,
        tierReason: "挪威域名注册的区域选手。",
        colorKey: "domeneshop",
        billingURL: URL(string: "https://www.domeneshop.no/")!,
        credentialSetupURL: URL(string: "https://www.domeneshop.no/admin?view=api")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 36,
        accessStatus: .pendingVerification,
        searchKeywords: ["domeneshop", "domainshop", "hyp.net", "norway"]
    )
}
