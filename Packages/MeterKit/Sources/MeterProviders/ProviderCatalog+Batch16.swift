import Foundation
import MeterCore

extension ProviderCatalog {
    public static let active24 = ProviderDescriptor(
        id: .active24,
        displayName: "Active24",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "中东欧主机与域名的区域选手。",
        colorKey: "active24",
        billingURL: URL(string: "https://client.active24.com/")!,
        credentialSetupURL: URL(string: "https://api.active24.com/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["active24", "active 24", "a24", "czech hosting"]
    )
}
