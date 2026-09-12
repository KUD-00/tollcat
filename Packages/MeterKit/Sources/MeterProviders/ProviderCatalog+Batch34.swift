import Foundation
import MeterCore

extension ProviderCatalog {
    public static let sevalla = ProviderDescriptor(
        id: .sevalla,
        displayName: "Sevalla",
        kind: .usage,
        category: .hosting,
        tier: .four,
        tierReason: "新兴应用托管 PaaS（paas-usage cost USD），体量远小于 Railway / Render / Vercel。",
        colorKey: "sevalla",
        billingURL: URL(string: "https://sevalla.com/")!,
        credentialSetupURL: URL(string: "https://api-docs.sevalla.com/v2/company/get-usage")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 2,
        accessStatus: .pendingVerification,
        searchKeywords: ["sevalla", "paas-usage", "hosting", "kinsta"]
    )
}
