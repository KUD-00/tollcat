import Foundation

/// 新账号插到列表的哪里。只活在 `ProviderConfigStore.insert`，调用方不许各写一份。
public enum AccountInsertPlacement: Sendable {
    /// 向导 / 信箱新建。
    ///
    /// - 该厂商没有任何已有行：`sortIndex = (全部账号 max ?? -1) + 1`，不 shift。
    /// - 有 sibling：插在该厂商 max+1，并把 `sortIndex >= 新值` 的其它行 +1。
    case afterSiblings
    /// 迁移包 / 种子：用给定值，不 shift。
    case exact(Int)
}
