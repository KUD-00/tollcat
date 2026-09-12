import Foundation
import MeterCore

extension ProviderCatalog {
    public static let clevercloud = ProviderDescriptor(
        id: .clevercloud,
        displayName: "Clever Cloud",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "法国 PaaS/欧洲主权云的细分选手，体量小于 Scaleway / OVHcloud 主流短名单。",
        colorKey: "clevercloud",
        billingURL: URL(string: "https://console.clever-cloud.com/")!,
        credentialSetupURL: URL(string: "https://www.clever.cloud/developers/api/v4/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["clever cloud", "clevercloud", "invoices", "EUR", "PaaS"]
    )

    public static let utilityapi = ProviderDescriptor(
        id: .utilityapi,
        displayName: "UtilityAPI",
        kind: .usage,
        category: .other,
        tier: .three,
        tierReason: "美国公用事业账单聚合的细分选手，与 VoltView 同属能源账单 API 短名单。",
        colorKey: "utilityapi",
        billingURL: URL(string: "https://utilityapi.com/")!,
        credentialSetupURL: URL(string: "https://utilityapi.com/docs/api/bills")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["utilityapi", "utility", "bills", "bill_total_cost", "energy"]
    )

    public static let dnsimple = ProviderDescriptor(
        id: .dnsimple,
        displayName: "DNSimple",
        kind: .usage,
        category: .networkEdge,
        tier: .three,
        tierReason: "开发者向 DNS/域名托管的细分选手，体量小于 Cloudflare Registrar / Route 53 主流短名单。",
        colorKey: "dnsimple",
        billingURL: URL(string: "https://dnsimple.com/")!,
        credentialSetupURL: URL(string: "https://developer.dnsimple.com/v2/billing-charges/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["dnsimple", "dns", "billing charges", "USD", "domains"]
    )

    public static let latitudesh = ProviderDescriptor(
        id: .latitudesh,
        displayName: "Latitude.sh",
        kind: .usage,
        category: .hosting,
        tier: .two,
        tierReason: "全球按需裸金属的强挑战者，与 phoenixNAP / Servers.com 并列短名单。",
        colorKey: "latitudesh",
        billingURL: URL(string: "https://www.latitude.sh/")!,
        credentialSetupURL: URL(string: "https://www.latitude.sh/docs/api-reference/get-billing-usage")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 1,
        accessStatus: .pendingVerification,
        searchKeywords: ["latitude.sh", "latitudesh", "billing usage", "bare metal", "cents"]
    )
}
