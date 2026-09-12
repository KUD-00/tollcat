import MeterCore
import MeterProviders

/// 放在 MainActor 类型外面，才不会把隔离带进 TaskGroup。
struct BillingRefreshJob: Sendable {
    var id: AccountID
    var providerID: ProviderID
    var provider: any BillingProvider
    var credential: Credential
}
