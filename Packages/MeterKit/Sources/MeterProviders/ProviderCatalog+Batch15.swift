import Foundation
import MeterCore

extension ProviderCatalog {
    public static let websupport = ProviderDescriptor(
        id: .websupport,
        displayName: "Websupport",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "中东欧主机与域名的区域选手。",
        colorKey: "websupport",
        billingURL: URL(string: "https://admin.websupport.sk/")!,
        credentialSetupURL: URL(string: "https://rest.websupport.se/docs/v1.intro")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["websupport", "websupport.sk", "websupport.se", "slovakia"]
    )
}
