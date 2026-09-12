import Foundation
import MeterCore

extension ProviderCatalog {
    public static let idcloudhost = ProviderDescriptor(
        id: .idcloudhost,
        displayName: "IDCloudHost",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "印尼/SEA 区域云，period invoice totals 清晰，份额远小于阿里云 / AWS 亚太。",
        colorKey: "idcloudhost",
        billingURL: URL(string: "https://idcloudhost.com/")!,
        credentialSetupURL: URL(string: "https://api.idcloudhost.com/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["idcloudhost", "indonesia", "SEA", "invoice", "IDR", "jkt", "sgp"]
    )
}
