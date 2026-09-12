import Foundation
import MeterCore

extension ProviderCatalog {
    public static let shipmondo = ProviderDescriptor(
        id: .shipmondo,
        displayName: "Shipmondo",
        kind: .usage,
        category: .other,
        tier: .three,
        tierReason: "丹麦/欧盟电商发货 SaaS 的细分选手；买方账户流水 amount+currency_code，只计 sales_document 扣费、忽略充值。",
        colorKey: "shipmondo",
        billingURL: URL(string: "https://app.shipmondo.com/")!,
        credentialSetupURL: URL(string: "https://shipmondo.dev/api-reference#/operations/user_ledger_entries_get")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["shipmondo", "ledger", "amount", "currency_code", "sales_document", "shipping"]
    )
}
