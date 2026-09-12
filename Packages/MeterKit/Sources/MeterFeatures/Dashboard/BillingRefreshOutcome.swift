import MeterCore

enum BillingRefreshOutcome: Sendable {
    case success(id: AccountID, snapshot: Snapshot)
    case failure(id: AccountID)
    /// 信箱里还没有这条。不把已有的手填标成失败。
    case skipped(id: AccountID)
}
