import Foundation
import MeterCore

extension ProviderCatalog {
    public static let ncloud = ProviderDescriptor(
        id: .ncloud,
        displayName: "NAVER Cloud",
        kind: .usage,
        category: .hosting,
        tier: .two,
        tierReason: "韩国主权公有云龙头，月度请款 totalDemandAmount+payCurrency 清晰但全球份额远小于 Hyperscaler。",
        colorKey: "ncloud",
        billingURL: URL(string: "https://console.ncloud.com/")!,
        credentialSetupURL: URL(string: "https://api.ncloud-docs.com/docs/en/common-ncpapi")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["ncloud", "naver cloud", "navercloud", "demandCost", "KRW", "ntruss"]
    )

    public static let nomos = ProviderDescriptor(
        id: .nomos,
        displayName: "Nomos",
        kind: .usage,
        category: .other,
        tier: .three,
        tierReason: "德国能源零售用量发票 API，体量远小于 Octopus / Tibber，但 period EUR 清晰。",
        colorKey: "nomos",
        billingURL: URL(string: "https://nomos.energy/")!,
        credentialSetupURL: URL(string: "https://dashboard.nomos.energy")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["nomos", "nomos.energy", "usage invoice", "EUR", "electricity"]
    )

    public static let dnscale = ProviderDescriptor(
        id: .dnscale,
        displayName: "DNScale",
        kind: .usage,
        category: .networkEdge,
        tier: .four,
        tierReason: "欧洲独立 DNS 小厂，billing summary EUR 清晰但份额远小于 Cloudflare / DNSimple。",
        colorKey: "dnscale",
        billingURL: URL(string: "https://dnscale.eu/")!,
        credentialSetupURL: URL(string: "https://dnscale.eu/api/authentication")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["dnscale", "dns", "billing summary", "EUR"]
    )
}
