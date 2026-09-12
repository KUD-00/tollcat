import Foundation
import MeterCore

extension ProviderCatalog {
    public static let cloudheed = ProviderDescriptor(
        id: .cloudheed,
        displayName: "Cloudheed",
        kind: .usage,
        category: .database,
        tier: .four,
        tierReason: "新兴托管数据库 usage total+currency，体量远小于 Neon / PlanetScale / Cockroach。",
        colorKey: "cloudheed",
        billingURL: URL(string: "https://cloudheed.com/")!,
        credentialSetupURL: URL(string: "https://docs.cloudheed.com/billing")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 1,
        accessStatus: .pendingVerification,
        searchKeywords: ["cloudheed", "billing/usage", "database", "postgres"]
    )
}
