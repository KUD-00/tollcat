import Foundation
import MeterCore

extension ProviderCatalog {
    public static let cerebrium = ProviderDescriptor(
        id: .cerebrium,
        displayName: "Cerebrium",
        kind: .usage,
        category: .gpuCompute,
        tier: .three,
        tierReason: "Serverless GPU 部署云的细分选手，买方发票 amountDue（分）+currency，体量小于 RunPod / Fireworks 主流短名单。",
        colorKey: "cerebrium",
        billingURL: URL(string: "https://dashboard.cerebrium.ai/")!,
        credentialSetupURL: URL(string: "https://cerebrium.ai/docs/api-reference/subscriptions/list-invoices")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["cerebrium", "invoices", "amountDue", "currency", "serverless gpu"]
    )
}
