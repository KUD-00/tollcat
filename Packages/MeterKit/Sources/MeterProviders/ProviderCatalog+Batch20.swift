import Foundation
import MeterCore

extension ProviderCatalog {
    public static let inferencesh = ProviderDescriptor(
        id: .inferencesh,
        displayName: "inference.sh",
        kind: .usage,
        category: .aiInference,
        tier: .three,
        tierReason: "推理/应用市场用量计费的细分选手，体量小于 OpenRouter / Fireworks 主流短名单。",
        colorKey: "inferencesh",
        billingURL: URL(string: "https://inference.sh/")!,
        credentialSetupURL: URL(string: "https://app.inference.sh/settings/keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 1,
        accessStatus: .pendingVerification,
        searchKeywords: ["inference.sh", "inferencesh", "usage", "microcents", "breakdown"]
    )

    public static let voltview = ProviderDescriptor(
        id: .voltview,
        displayName: "VoltView",
        kind: .usage,
        category: .other,
        tier: .three,
        tierReason: "英国多站点能源发票聚合的细分选手，体量小于 Octopus / Tibber 消费级能源 API。",
        colorKey: "voltview",
        billingURL: URL(string: "https://docs.voltview.co.uk/")!,
        credentialSetupURL: URL(string: "https://docs.voltview.co.uk/register")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["voltview", "energy", "invoices", "GBP", "UK"]
    )
}
