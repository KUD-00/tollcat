import Foundation
import MeterCore

extension ProviderCatalog {
    public static let scalingo = ProviderDescriptor(
        id: .scalingo,
        displayName: "Scalingo",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "法国 PaaS，发票欧分清晰但体量小于 Clever Cloud / Scaleway 短名单。",
        colorKey: "scalingo",
        billingURL: URL(string: "https://dashboard.scalingo.com/")!,
        credentialSetupURL: URL(string: "https://developers.scalingo.com/invoices")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["scalingo", "invoice", "total_price", "EUR", "PaaS", "osc-fr1"]
    )

    public static let upsun = ProviderDescriptor(
        id: .upsun,
        displayName: "Upsun",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "原 Platform.sh 的 PaaS，订单 total+currency 清晰但体量小于主流公有云。",
        colorKey: "upsun",
        billingURL: URL(string: "https://console.upsun.com/")!,
        credentialSetupURL: URL(string: "https://developer.upsun.com/api-reference/orders/list-orders")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["upsun", "platform.sh", "orders", "currency", "PaaS"]
    )
}
