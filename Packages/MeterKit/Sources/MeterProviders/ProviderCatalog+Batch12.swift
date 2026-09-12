import Foundation
import MeterCore

extension ProviderCatalog {
    public static let zilliz = ProviderDescriptor(
        id: .zilliz,
        displayName: "Zilliz Cloud",
        kind: .usage,
        category: .database,
        tier: .two,
        tierReason: "托管向量库里的强挑战者，与 Pinecone 等同台。",
        colorKey: "zilliz",
        billingURL: URL(string: "https://cloud.zilliz.com/")!,
        credentialSetupURL: URL(string: "https://docs.zilliz.com/docs/manage-api-keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["zilliz", "milvus", "vector", "向量"]
    )

    public static let soniox = ProviderDescriptor(
        id: .soniox,
        displayName: "Soniox",
        kind: .usage,
        category: .aiInference,
        tier: .three,
        tierReason: "语音转写 API 细分里的小型选手。",
        colorKey: "soniox",
        billingURL: URL(string: "https://console.soniox.com/")!,
        credentialSetupURL: URL(string: "https://soniox.com/docs/speech-to-text/api-reference/authentication")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["soniox", "stt", "speech", "asr", "语音"]
    )

    public static let quay = ProviderDescriptor(
        id: .quay,
        displayName: "Quay.io",
        kind: .usage,
        category: .devTools,
        tier: .two,
        tierReason: "企业容器镜像仓库的强挑战者，红帽生态内地位稳固。",
        colorKey: "quay",
        billingURL: URL(string: "https://quay.io/organization/")!,
        credentialSetupURL: URL(string: "https://docs.quay.io/api/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["quay", "quay.io", "container registry", "镜像仓库"]
    )

    public static let glesys = ProviderDescriptor(
        id: .glesys,
        displayName: "GleSYS",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "北欧区域云/主机的小型选手。",
        colorKey: "glesys",
        billingURL: URL(string: "https://customer.glesys.com/")!,
        credentialSetupURL: URL(string: "https://cloud.glesys.com")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["glesys", "sweden", "invoice/list", "SEK", "customernumber"]
    )

    public static let cloudsigma = ProviderDescriptor(
        id: .cloudsigma,
        displayName: "CloudSigma",
        kind: .usage,
        category: .hosting,
        tier: .four,
        tierReason: "欧洲弹性云老将，近年声量与份额走弱。",
        colorKey: "cloudsigma",
        billingURL: URL(string: "https://ui.cloudsigma.com/")!,
        credentialSetupURL: URL(string: "https://docs.cloudsigma.com/en/latest/general.html#http-basic-auth")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 3,
        accessStatus: .pendingVerification,
        searchKeywords: ["cloudsigma", "ledger", "burst", "ignore balance", "CHF"]
    )

    public static let vpsnet = ProviderDescriptor(
        id: .vpsnet,
        displayName: "VPS.NET",
        kind: .usage,
        category: .hosting,
        tier: .four,
        tierReason: "老牌 VPS 品牌份额持续下滑。",
        colorKey: "vpsnet",
        billingURL: URL(string: "https://control.vps.net/")!,
        credentialSetupURL: URL(string: "https://control.vps.net/api/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["vps.net", "vpsnet", "vps"]
    )
}
