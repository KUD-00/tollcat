import Foundation
import MeterCore

extension ProviderCatalog {
    public static let time4vps = ProviderDescriptor(
        id: .time4vps,
        displayName: "Time4VPS",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "立陶宛 HostBill 发票型 VPS，区域体量小于西欧主流 IaaS。",
        colorKey: "time4vps",
        billingURL: URL(string: "https://billing.time4vps.com/")!,
        credentialSetupURL: URL(string: "https://billing.time4vps.com/userapi/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["time4vps", "hostbill", "invoice", "vps", "EUR", "USD"]
    )

    public static let bitlaunch = ProviderDescriptor(
        id: .bitlaunch,
        displayName: "BitLaunch",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "加密货币友好的按小时 VPS 聚合层，周期 usage 美元清晰但体量偏小。",
        colorKey: "bitlaunch",
        billingURL: URL(string: "https://app.bitlaunch.io/")!,
        credentialSetupURL: URL(string: "https://developers.bitlaunch.io/reference/view-usage")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["bitlaunch", "usage", "totalUsd", "vps", "USD"]
    )

    public static let hivelocity = ProviderDescriptor(
        id: .hivelocity,
        displayName: "Hivelocity",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "美国裸金属 / Instant 托管，发票金额明确但不及超大规模云。",
        colorKey: "hivelocity",
        billingURL: URL(string: "https://my.hivelocity.net/")!,
        credentialSetupURL: URL(string: "https://developers.hivelocity.net/docs/billing")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["hivelocity", "invoice", "bare metal", "core.hivelocity.net", "USD"]
    )
}
