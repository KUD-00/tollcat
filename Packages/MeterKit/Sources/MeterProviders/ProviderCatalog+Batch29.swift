import Foundation
import MeterCore

extension ProviderCatalog {
    public static let formspring = ProviderDescriptor(
        id: .formspring,
        displayName: "Formspring",
        kind: .usage,
        category: .automation,
        tier: .four,
        tierReason: "欧盟表单 SaaS，billing invoices USD cents 清晰但份额远小于 Typeform。",
        colorKey: "formspring",
        billingURL: URL(string: "https://formspring.io/")!,
        credentialSetupURL: URL(string: "https://formspring.io/tokens")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["formspring", "formspring.io", "billing invoices", "USD cents", "billing:read"]
    )

    public static let hostcircle = ProviderDescriptor(
        id: .hostcircle,
        displayName: "Hostcircle",
        kind: .usage,
        category: .hosting,
        tier: .four,
        tierReason: "荷兰 HostBill 主机商，发票 total+currency 清晰但全球份额远小于 Time4VPS / Hetzner。",
        colorKey: "hostcircle",
        billingURL: URL(string: "https://my.hostcircle.com/")!,
        credentialSetupURL: URL(string: "https://my.hostcircle.com/userapi/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["hostcircle", "hostbill", "invoice", "EUR", "my.hostcircle.com"]
    )

    public static let loginet = ProviderDescriptor(
        id: .loginet,
        displayName: "Loginet",
        kind: .usage,
        category: .hosting,
        tier: .four,
        tierReason: "爱沙尼亚 IaaS，HostBill 发票 total+currency 清晰但体量远小于北欧大厂。",
        colorKey: "loginet",
        billingURL: URL(string: "https://hostbill.loginet.ee/")!,
        credentialSetupURL: URL(string: "https://hostbill.loginet.ee/?cmd=userapi")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["loginet", "hostbill.loginet.ee", "invoice", "EUR", "estonia"]
    )
}
