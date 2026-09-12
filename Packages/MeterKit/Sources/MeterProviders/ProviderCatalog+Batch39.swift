import Foundation
import MeterCore

extension ProviderCatalog {
    public static let sendcloud = ProviderDescriptor(
        id: .sendcloud,
        displayName: "Sendcloud",
        kind: .usage,
        category: .other,
        tier: .two,
        tierReason: "荷兰/欧盟电商发货 SaaS 主流选手；买方发票 price_taxable/tax value+currency 同资源，Basic Public+Private Key。",
        colorKey: "sendcloud",
        billingURL: URL(string: "https://panel.sendcloud.sc/")!,
        credentialSetupURL: URL(string: "https://sendcloud.dev/api/v3/invoices/retrieve-a-list-of-invoices")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["sendcloud", "invoice", "price_taxable", "currency", "shipping", "eu"]
    )
}
