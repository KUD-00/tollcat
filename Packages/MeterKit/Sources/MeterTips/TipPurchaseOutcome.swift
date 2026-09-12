import Foundation

/// 取消、待批准、失败必须分开。家长控制走 `.pending`，不是失败。
public enum TipPurchaseOutcome: Sendable, Equatable {
    case success(TipTransaction)
    case cancelled
    case pending
    case failed
}
