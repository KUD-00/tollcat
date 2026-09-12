import Foundation

public enum PersistenceError: Error, Equatable, Sendable {
    case invalidStoredKind(String)
    case invalidStoredPeriod(String)
    case invalidAnchorDate(year: Int, month: Int, day: Int)
    case corruptDailySpend
    case corruptWalletBalances
    case corruptSpendLines
    case invalidStoredAccount(String)
    /// 账本里有解不出来的行。**这是缓存坏了，不是数据坏了**——戳已经在同一个
    /// context 里作废，下一次同步会整份重折。抛出来是为了让上层亮「读不出最新数据」，
    /// 而不是把这几行悄悄从合计里去掉（见 `MonthlyLedgerStore.all`）。
    case corruptLedgerRow(count: Int)
}
