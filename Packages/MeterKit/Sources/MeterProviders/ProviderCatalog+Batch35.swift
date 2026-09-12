import Foundation
import MeterCore

extension ProviderCatalog {
    public static let catalystvm = ProviderDescriptor(
        id: .catalystvm,
        displayName: "CatalystVM",
        kind: .usage,
        category: .hosting,
        tier: .four,
        tierReason: "小型 HostBill VPS（invoice total+currency），体量远小于 Time4VPS / Hetzner。",
        colorKey: "catalystvm",
        billingURL: URL(string: "https://my.catalystvm.com/")!,
        credentialSetupURL: URL(string: "https://my.catalystvm.com/userapi/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["catalystvm", "hostbill", "invoice", "USD", "my.catalystvm.com", "vps"]
    )

    public static let oxahost = ProviderDescriptor(
        id: .oxahost,
        displayName: "Oxahost",
        kind: .usage,
        category: .hosting,
        tier: .four,
        tierReason: "非洲/法语区 HostBill 主机商（invoice total+currency），全球份额远小于主流 IaaS。",
        colorKey: "oxahost",
        billingURL: URL(string: "https://my.oxahost.com/")!,
        credentialSetupURL: URL(string: "https://my.oxahost.com/userapi/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["oxahost", "hostbill", "invoice", "USD", "my.oxahost.com", "afrinic"]
    )
}
