import Foundation
import MeterCore

extension ProviderCatalog {
    public static let iwinv = ProviderDescriptor(
        id: .iwinv,
        displayName: "iwinv",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "韩国区域云 period 账单（payment_price），体量远小于 ncloud / AWS 亚太。",
        colorKey: "iwinv",
        billingURL: URL(string: "https://www.iwinv.kr/")!,
        credentialSetupURL: URL(string: "https://console.iwinv.kr/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["iwinv", "korea", "KRW", "bill", "stack"]
    )

    public static let frankenergie = ProviderDescriptor(
        id: .frankenergie,
        displayName: "Frank Energie",
        kind: .usage,
        category: .other,
        tier: .three,
        tierReason: "荷兰能源零售发票 GraphQL（totalAmount EUR），体量小于 Octopus / Tibber / Nomos。",
        colorKey: "frankenergie",
        billingURL: URL(string: "https://www.frankenergie.nl/")!,
        credentialSetupURL: URL(string: "https://github.com/HiDiHo01/python-frank-energie")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["frank", "frankenergie", "netherlands", "EUR", "invoice", "energy"]
    )

    public static let dilmune = ProviderDescriptor(
        id: .dilmune,
        displayName: "Dilmune",
        kind: .usage,
        category: .hosting,
        tier: .four,
        tierReason: "托管云 Stripe 发票列表（amount 分），份额远小于 DigitalOcean / AWS。",
        colorKey: "dilmune",
        billingURL: URL(string: "https://dilmune.com/")!,
        credentialSetupURL: URL(string: "https://cloud.dilmune.com/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["dilmune", "invoice", "stripe", "cloud", "hosting"]
    )

    public static let hubble = ProviderDescriptor(
        id: .hubble,
        displayName: "Hubble",
        kind: .usage,
        category: .messaging,
        tier: .three,
        tierReason: "物联网卫星网络 period 发票（total_balance），体量小于 Soracom / 1NCE。",
        colorKey: "hubble",
        billingURL: URL(string: "https://hubble.com/")!,
        credentialSetupURL: URL(string: "https://dash.hubble.com/developer/api-tokens")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["hubble", "iot", "satellite", "invoice", "billing"]
    )
}
