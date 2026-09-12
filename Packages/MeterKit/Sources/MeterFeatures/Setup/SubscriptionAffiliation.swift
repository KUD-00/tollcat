import MeterCore

enum SubscriptionAffiliation: Hashable {
    case none
    case vendor(ProviderID)
    case account(AccountID)
}
